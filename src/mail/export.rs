//! Save one message's original bytes as `.eml` in the user's Downloads folder.
//!
//! The bytes come from the provider operation E01 added (`imap.rawMessage`) and
//! are written unchanged. The RPC contract is frozen in `planning/decisions/E00.md`;
//! this module owns strict account resolution's consumer side, the filename
//! policy, the bounded write, and the result shape.
use super::{Account, ExportRequest, Provider};
use base64::{Engine, engine::general_purpose::STANDARD};
use serde_json::{Value, json};
use std::{
    future::Future,
    path::{Path, PathBuf},
    pin::Pin,
};

/// The product limit from E00: below the transport's 32 MiB response bound and
/// above the 20 MiB attachment limit. Checked before any unbounded allocation.
pub(crate) const MAX_BYTES: usize = 25 * 1024 * 1024;

/// Fetches the raw provider result (`{"bytes": n, "data": <base64>}`) for one
/// account-qualified message. The backend supplies the IMAP-backed one.
pub(crate) trait ExportAdapter: Send + Sync {
    fn raw<'a>(
        &'a self,
        account: &'a Account,
        id: &'a str,
    ) -> Pin<Box<dyn Future<Output = Result<Value, &'static str>> + Send + 'a>>;
}

pub(crate) async fn export_with(
    request: ExportRequest,
    adapter: &impl ExportAdapter,
    downloads: &Path,
    refusals: &Value,
) -> Result<Value, &'static str> {
    // Provider ceiling: only Outlook and generic IMAP share the native path.
    if !matches!(request.account.provider, Provider::Outlook | Provider::Imap) {
        return Err("mail_export_unsupported");
    }
    if !crate::providers::can(request.account.provider.id(), "emlExport", refusals) {
        return Err("mail_export_unsupported");
    }
    // Reject a malformed `<uid>:<folder>` before any credential or network work.
    crate::providers::imap::message_id(&request.id)?;

    // Cancellation is observed here, before the file is created: if this future
    // is dropped or refused, nothing is written. Once the write below commits,
    // success is returned even if a cancellation arrives afterwards — a
    // committed file is never reported as a failure.
    let fetched = adapter.raw(&request.account, &request.id).await?;
    let data = fetched["data"].as_str().ok_or("mail_export_incomplete")?;
    // Refuse an over-limit payload before decoding it.
    if data.len() > MAX_BYTES.div_ceil(3) * 4 + 1024 {
        return Err("mail_export_too_large");
    }
    let bytes = decode(data)?;
    if bytes.len() > MAX_BYTES {
        return Err("mail_export_too_large");
    }

    let filename = export_filename(&request.suggested_name);
    std::fs::create_dir_all(downloads).map_err(|_| "mail_export_write_failed")?;
    let path = write_unique(downloads, &filename, &bytes)?;
    let saved = path
        .file_name()
        .map(|name| name.to_string_lossy().into_owned())
        .unwrap_or(filename);
    Ok(json!({
        "accountId": request.account.id,
        "messageId": request.id,
        "path": path,
        "filename": saved,
        "bytes": bytes.len(),
    }))
}

fn decode(data: &str) -> Result<Vec<u8>, &'static str> {
    let compact: String = data.chars().filter(|c| !c.is_ascii_whitespace()).collect();
    STANDARD
        .decode(&compact)
        .map_err(|_| "mail_export_incomplete")
}

/// A safe `.eml` basename built from the untrusted subject hint. The hint is
/// reduced to a basename, control characters and separators are dropped, the
/// name is capped, and `.eml` is appended exactly once.
pub(crate) fn export_filename(suggested: &str) -> String {
    let base = crate::attachment::safe_filename(suggested);
    let base = if base == "attachment" {
        "message".to_owned()
    } else {
        base
    };
    let stem = if base.to_lowercase().ends_with(".eml") {
        &base[..base.len() - 4]
    } else {
        base.as_str()
    };
    let stem = stem.trim_end_matches([' ', '.']);
    let stem = if stem.is_empty() { "message" } else { stem };
    let mut end = stem.len().min(240 - 4);
    while !stem.is_char_boundary(end) {
        end -= 1;
    }
    format!("{}.eml", &stem[..end])
}

#[cfg(unix)]
fn write_unique(directory: &Path, filename: &str, bytes: &[u8]) -> Result<PathBuf, &'static str> {
    use std::{
        fs::OpenOptions,
        io::Write,
        os::unix::fs::OpenOptionsExt,
    };
    let path = Path::new(filename);
    let stem = path.file_stem().unwrap_or_default().to_string_lossy();
    let suffix = path
        .extension()
        .map(|s| format!(".{}", s.to_string_lossy()))
        .unwrap_or_default();
    for n in 1..1000 {
        let candidate = directory.join(if n == 1 {
            filename.to_owned()
        } else {
            format!("{stem} ({n}){suffix}")
        });
        match OpenOptions::new()
            .write(true)
            .create_new(true)
            .mode(0o600)
            .custom_flags(libc::O_NOFOLLOW)
            .open(&candidate)
        {
            Ok(mut file) => {
                if file.write_all(bytes).and_then(|_| file.sync_all()).is_err() {
                    let _ = std::fs::remove_file(&candidate);
                    return Err("mail_export_write_failed");
                }
                return Ok(candidate);
            }
            Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => continue,
            Err(_) => return Err("mail_export_write_failed"),
        }
    }
    Err("mail_export_write_failed")
}

#[cfg(windows)]
fn write_unique(directory: &Path, filename: &str, bytes: &[u8]) -> Result<PathBuf, &'static str> {
    let dir = crate::platform::private_fs::directories(directory, &[], true)
        .map_err(|_| "mail_export_write_failed")?
        .ok_or("mail_export_write_failed")?;
    crate::platform::private_fs::write_unique(&dir, filename, bytes)
        .map_err(|_| "mail_export_write_failed")
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{fs, sync::atomic::{AtomicUsize, Ordering}};

    fn scratch(name: &str) -> PathBuf {
        static N: AtomicUsize = AtomicUsize::new(0);
        let dir = std::env::temp_dir().canonicalize().unwrap().join(format!(
            "omamail-export-{}-{}-{}",
            std::process::id(),
            name,
            N.fetch_add(1, Ordering::Relaxed)
        ));
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[test]
    fn names_are_safe_and_get_one_eml_suffix() {
        assert_eq!(export_filename("Project update"), "Project update.eml");
        assert_eq!(export_filename("report.eml"), "report.eml");
        assert_eq!(export_filename("report.EML"), "report.eml");
        assert_eq!(export_filename("../../x\\invoice"), "invoice.eml");
        assert_eq!(export_filename(""), "message.eml");
        assert_eq!(export_filename(".."), "message.eml");
        assert_eq!(export_filename("a\nb"), "a_b.eml");
        let long = export_filename(&format!("{}.eml", "x".repeat(400)));
        assert!(long.len() <= 240);
        assert!(long.ends_with(".eml"));
    }

    #[test]
    fn duplicate_names_never_overwrite() {
        let dir = scratch("dup");
        let first = write_unique(&dir, "note.eml", b"one").unwrap();
        let second = write_unique(&dir, "note.eml", b"two").unwrap();
        assert_eq!(first.file_name().unwrap(), "note.eml");
        assert_eq!(second.file_name().unwrap(), "note (2).eml");
        assert_eq!(fs::read(&first).unwrap(), b"one");
        assert_eq!(fs::read(&second).unwrap(), b"two");
        fs::remove_dir_all(dir).unwrap();
    }

    #[cfg(unix)]
    #[test]
    fn a_symlink_target_is_never_followed_and_permits_are_private() {
        use std::os::unix::fs::PermissionsExt;
        let dir = scratch("link");
        let victim = dir.join("victim");
        fs::write(&victim, b"keep").unwrap();
        std::os::unix::fs::symlink(&victim, dir.join("note.eml")).unwrap();
        let saved = write_unique(&dir, "note.eml", b"payload").unwrap();
        assert_eq!(saved.file_name().unwrap(), "note (2).eml");
        assert_eq!(fs::read(&victim).unwrap(), b"keep");
        assert_eq!(
            fs::metadata(&saved).unwrap().permissions().mode() & 0o777,
            0o600
        );
        fs::remove_dir_all(dir).unwrap();
    }

    struct Fake {
        payload: Value,
    }
    impl ExportAdapter for Fake {
        fn raw<'a>(
            &'a self,
            _account: &'a Account,
            _id: &'a str,
        ) -> Pin<Box<dyn Future<Output = Result<Value, &'static str>> + Send + 'a>> {
            let payload = self.payload.clone();
            Box::pin(async move { Ok(payload) })
        }
    }

    fn request() -> ExportRequest {
        ExportRequest {
            account: Account {
                id: "imap:person@example.test".into(),
                provider: Provider::Imap,
            },
            id: "42:INBOX".into(),
            suggested_name: "Project update".into(),
        }
    }

    async fn run(payload: Value) -> Result<Value, &'static str> {
        let dir = scratch("run");
        let result = export_with(request(), &Fake { payload }, &dir, &Value::Null).await;
        fs::remove_dir_all(dir).ok();
        result
    }

    #[tokio::test]
    async fn a_missing_payload_column_is_incomplete() {
        assert_eq!(run(json!({"bytes": 1})).await, Err("mail_export_incomplete"));
        assert_eq!(
            run(json!({"data": "not base64!"})).await,
            Err("mail_export_incomplete")
        );
    }

    #[tokio::test]
    async fn an_over_limit_payload_is_refused_before_decoding() {
        let huge = "A".repeat(MAX_BYTES.div_ceil(3) * 4 + 2048);
        assert_eq!(
            run(json!({"data": huge})).await,
            Err("mail_export_too_large")
        );
    }

    #[tokio::test]
    async fn a_committed_export_reports_the_exact_file_and_bytes() {
        let dir = scratch("commit");
        let bytes = b"Subject: hi\r\n\r\nbody \xc3\xa9";
        let payload = json!({"bytes": bytes.len(), "data": STANDARD.encode(bytes)});
        let result = export_with(request(), &Fake { payload }, &dir, &Value::Null)
            .await
            .unwrap();
        assert_eq!(result["accountId"], "imap:person@example.test");
        assert_eq!(result["messageId"], "42:INBOX");
        assert_eq!(result["filename"], "Project update.eml");
        assert_eq!(result["bytes"], bytes.len());
        let saved = PathBuf::from(result["path"].as_str().unwrap());
        assert_eq!(saved.parent().unwrap(), dir);
        assert_eq!(fs::read(&saved).unwrap(), bytes);
        fs::remove_dir_all(dir).unwrap();
    }

    #[tokio::test]
    async fn an_unsupported_provider_is_refused_before_any_fetch() {
        let dir = scratch("provider");
        let mut request = request();
        request.account.provider = Provider::Gmail;
        assert_eq!(
            export_with(request, &Fake { payload: json!({}) }, &dir, &Value::Null).await,
            Err("mail_export_unsupported")
        );
        assert!(fs::read_dir(&dir).unwrap().next().is_none());
        fs::remove_dir_all(dir).unwrap();
    }
}

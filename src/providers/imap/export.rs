//! Exact raw-message retrieval for export. The octets the server sends are
//! returned unchanged: nothing here parses the message or re-serializes it.
//!
//! Internal to the provider layer and deliberately absent from the advertised
//! public method inventory (`src/backend/methods.rs`), like the internal
//! `jmap.action*` planners. `mail.exportEml` (E02) consumes it.
use super::*;

/// Validate the export parameters before any socket is opened.
pub(super) fn validate(method: &str, p: &Value) -> Result<()> {
    if method != "imap.rawMessage" {
        return Ok(());
    }
    quote(p["folder"].as_str().ok_or("invalid_params")?)?;
    requested_uid(p)?;
    Ok(())
}

fn requested_uid(p: &Value) -> Result<u32> {
    p["uid"]
        .as_u64()
        .filter(|n| *n > 0 && *n <= u32::MAX as u64)
        .map(|n| n as u32)
        .ok_or("mail_export_message_invalid")
}

pub(super) async fn call(p: &Value) -> Result<Value> {
    let folder = p["folder"].as_str().ok_or("invalid_params")?;
    let bytes = raw_message(p, requested_uid(p)?, folder).await?;
    Ok(json!({"bytes": bytes.len(), "data": STANDARD.encode(&bytes)}))
}

/// Fetch one UID's complete message and return the server's literal octets.
/// `BODY.PEEK[]` keeps `\Seen` unchanged, and `EXAMINE` selects the mailbox
/// read-only, so nothing here changes flags, message location, or mailbox
/// state such as `\Recent`.
pub(super) async fn raw_message(p: &Value, uid: u32, folder: &str) -> Result<Vec<u8>> {
    let (mut w, key) = acquire(p).await?;
    let result = fetch_literal(&mut w, uid, folder).await;
    release(w, key).await;
    result
}

async fn fetch_literal(w: &mut Wire, uid: u32, folder: &str) -> Result<Vec<u8>> {
    command(w, &format!("EXAMINE {}", quote(folder)?)).await?;
    let data = command(w, &format!("UID FETCH {uid} (UID BODY.PEEK[])")).await?;
    single_literal(&data, uid)
}

/// Exactly one full `BODY[]` literal for the requested UID. Unsolicited records
/// for other UIDs are ignored; a missing record, a `NIL` body, a partial
/// section such as `BODY[HEADER]`, a list-valued body, a duplicated field, or
/// two literals for the requested UID are refused. The literal is length-framed,
/// so a payload that merely looks like a tagged completion or another FETCH
/// record cannot be mistaken for one.
///
/// A partial section and a second body field are refusals rather than
/// overwrites: the saved file would otherwise report success while holding
/// something that is not the complete original message.
fn single_literal(data: &[u8], uid: u32) -> Result<Vec<u8>> {
    let mut found: Option<Vec<u8>> = None;
    for row in read::nodes(data)? {
        if row.len() < 4 || !row[0].is("*") || !row[2].is("FETCH") {
            continue;
        }
        let fields = row[3].list();
        let mut row_uid: Option<u32> = None;
        let mut uid_fields = 0usize;
        let mut bodies: Vec<Option<Vec<u8>>> = Vec::new();
        let mut malformed = false;
        let mut i = 0;
        while i + 1 < fields.len() {
            let name = fields[i].text();
            let value = &fields[i + 1];
            if name.eq_ignore_ascii_case(b"UID") {
                uid_fields += 1;
                row_uid = value.number();
            } else if name.eq_ignore_ascii_case(b"BODY[]") {
                // A list-valued body is not a literal, and reading it through
                // `text()` would silently become empty bytes.
                if value.is_list() {
                    malformed = true;
                } else {
                    bodies.push(if value.is("NIL") {
                        None
                    } else {
                        Some(value.text().to_vec())
                    });
                }
            } else if name
                .to_ascii_uppercase()
                .starts_with(b"BODY[")
            {
                // `BODY[HEADER]`, `BODY[1]`, `BODY[TEXT]`, `BODY[]<0>`: any
                // section but the whole message cannot be the whole message.
                malformed = true;
            }
            i += 2;
        }
        // An unsolicited record for another UID is not this message and is
        // ignored; only the requested UID's record is judged.
        if row_uid != Some(uid) {
            continue;
        }
        if malformed || uid_fields > 1 || bodies.len() > 1 {
            return Err("mail_export_incomplete");
        }
        match bodies.pop() {
            Some(Some(bytes)) => {
                if found.is_some() {
                    return Err("mail_export_incomplete");
                }
                found = Some(bytes);
            }
            Some(None) => return Err("mail_export_message_missing"),
            None => continue,
        }
    }
    found.ok_or("mail_export_message_missing")
}

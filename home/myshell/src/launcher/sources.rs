//! Where the launcher's entries come from, and what choosing one does. Everything here reads
//! files or runs programs, so it runs in the background.

use std::path::Path;

use futures::AsyncWriteExt;
use secrecy::ExposeSecret;
use secrecy::SecretString;
use secrecy::zeroize::Zeroize;
use secrecy::zeroize::Zeroizing;

use super::Action;
use super::Entry;
use super::Mode;
use crate::data_source::Result;
use crate::desktop_entry;

/// Executables on `$PATH`, by name. Earlier directories shadow later ones, as in a shell.
pub fn programs() -> Vec<Entry> {
    use std::os::unix::fs::PermissionsExt;
    let mut seen = std::collections::HashSet::new();
    let mut programs = Vec::new();
    let paths = std::env::var_os("PATH").unwrap_or_default();
    for dir in std::env::split_paths(&paths) {
        let Ok(files) = std::fs::read_dir(&dir) else {
            continue;
        };
        for file in files.flatten() {
            let path = file.path();
            let executable = (std::fs::metadata(&path))
                .is_ok_and(|meta| meta.is_file() && meta.permissions().mode() & 0o111 != 0);
            let Some(name) = file.file_name().to_str().map(str::to_owned) else {
                continue;
            };
            // Dotted names are hidden (e.g. Nix's `.foo-wrapped` wrappers).
            if executable && !name.starts_with('.') && seen.insert(name.clone()) {
                programs.push(Entry::new(
                    Mode::Programs,
                    name,
                    dir.display().to_string(),
                    Action::Program(path),
                ));
            }
        }
    }
    programs.sort_by(|a, b| a.name.cmp(&b.name));
    programs
}

/// Every emoji (without skin tones), in Unicode's order, found by name or shortcode. Choosing one
/// copies it.
pub fn emoji() -> Vec<Entry> {
    (emojis::iter())
        .map(|emoji| {
            let mut name = emoji.name().chars();
            let name = (name.next().into_iter())
                .flat_map(char::to_uppercase)
                .chain(name)
                .collect();
            let shortcodes = (emoji.shortcodes().map(|code| format!(":{code}:")))
                .collect::<Vec<_>>()
                .join(" ");
            let mut entry = Entry::new(
                Mode::Emoji,
                name,
                shortcodes.clone(),
                Action::Copy(emoji.as_str().to_owned()),
            );
            entry.extra = shortcodes;
            entry
        })
        .collect()
}

/// The shell's environment. Choosing one copies its value.
pub fn environment() -> Vec<Entry> {
    let mut variables: Vec<Entry> = std::env::vars()
        .map(|(name, value)| {
            Entry::new(Mode::Environment, name, value.clone(), Action::Copy(value))
        })
        .collect();
    variables.sort_by(|a, b| a.name.cmp(&b.name));
    variables
}

/// Proton Pass's CLI; `MYSHELL_PASS_CLI` overrides it (e.g. `false`, to disable it).
fn pass_cli() -> String {
    std::env::var("MYSHELL_PASS_CLI").unwrap_or_else(|_| "pass-cli".into())
}

/// Items' titles (and usernames) only; passwords are read when one is chosen. The list may still
/// hold secrets (e.g. if it includes items' contents), so its values are never logged, and every
/// copy of them is zeroed once read. Its shape (keys and types) is logged, to debug parsing.
pub async fn passwords() -> Vec<Entry> {
    let arguments = ["item", "list", "--output", "json"];
    eprintln!("passwords: running {} {}", pass_cli(), arguments.join(" "));
    let (status, stdout, stderr) = match run_secret(&arguments).await {
        Ok(output) => output,
        Err(error) => {
            eprintln!("passwords: couldn't run {}: {error}", pass_cli());
            return Vec::new();
        }
    };
    eprintln!(
        "passwords: item list exited with {status}, {} bytes of output, stderr: {:?}",
        stdout.len(),
        stderr.trim()
    );
    if !status.success() {
        return Vec::new();
    }
    let mut json = match serde_json::from_slice::<serde_json::Value>(&stdout) {
        Ok(json) => json,
        Err(error) => {
            eprintln!("passwords: item list isn't JSON: {error}");
            return Vec::new();
        }
    };
    eprintln!("passwords: item list's shape: {}", shape(&json, 0));
    let mut items = Vec::new();
    password_items(&json, None, &mut items);
    zeroize_strings(&mut json);
    let with_share = (items.iter())
        .filter(|item| matches!(&item.action, Action::Password(Some(_), _)))
        .count();
    eprintln!(
        "passwords: found {} items ({with_share} with a share ID)",
        items.len()
    );
    items.sort_by_key(|item| item.name.to_lowercase());
    items
}

/// Runs pass-cli, returning its status, its output (zeroed on drop), and its error output.
async fn run_secret(
    arguments: &[&str],
) -> Result<(std::process::ExitStatus, Zeroizing<Vec<u8>>, String)> {
    use futures::AsyncReadExt;
    let mut child = async_process::Command::new(pass_cli())
        .args(arguments)
        .stdin(async_process::Stdio::null())
        .stdout(async_process::Stdio::piped())
        .stderr(async_process::Stdio::piped())
        .kill_on_drop(true)
        .spawn()?;
    let (mut stdout, mut stderr) = (
        child.stdout.take().ok_or("no stdout")?,
        child.stderr.take().ok_or("no stderr")?,
    );
    // Reserved up front, so growing it doesn't leave unzeroed copies behind (for most outputs).
    let mut output = Zeroizing::new(Vec::with_capacity(1 << 20));
    let mut errors = Vec::new();
    let (read, _) = futures::join!(
        stdout.read_to_end(&mut output),
        stderr.read_to_end(&mut errors)
    );
    read?;
    let status = child.status().await?;
    Ok((
        status,
        output,
        String::from_utf8_lossy(&errors).into_owned(),
    ))
}

/// The JSON's structure, without any values: e.g. `{"items": [3 x {"id": str}]}`. Arrays show
/// their first element.
fn shape(value: &serde_json::Value, depth: usize) -> String {
    use serde_json::Value;
    if depth > 8 {
        return "...".into();
    }
    match value {
        Value::Null => "null".into(),
        Value::Bool(_) => "bool".into(),
        Value::Number(_) => "number".into(),
        Value::String(_) => "str".into(),
        Value::Array(values) => match values.first() {
            Some(first) => format!("[{} x {}]", values.len(), shape(first, depth + 1)),
            None => "[]".into(),
        },
        Value::Object(object) => {
            let fields: Vec<String> = (object.iter())
                .map(|(key, value)| format!("{key:?}: {}", shape(value, depth + 1)))
                .collect();
            format!("{{{}}}", fields.join(", "))
        }
    }
}

/// Zeroes every string in the JSON, before it's dropped.
fn zeroize_strings(value: &mut serde_json::Value) {
    match value {
        serde_json::Value::String(string) => string.zeroize(),
        serde_json::Value::Array(values) => values.iter_mut().for_each(zeroize_strings),
        serde_json::Value::Object(object) => object.values_mut().for_each(zeroize_strings),
        _ => {}
    }
}

/// Lenient, as the JSON's exact shape isn't documented: any object with a title and an item ID is
/// an item, in the vault (share) of the nearest object above with a share ID.
fn password_items(value: &serde_json::Value, share: Option<&str>, items: &mut Vec<Entry>) {
    let string = |value: &serde_json::Value, keys: &[&str]| {
        keys.iter()
            .find_map(|key| value.get(*key)?.as_str().map(str::to_owned))
    };
    match value {
        serde_json::Value::Array(values) => {
            for value in values {
                password_items(value, share, items);
            }
        }
        serde_json::Value::Object(object) => {
            let own_share = string(value, &["share_id", "shareId"]);
            let share = own_share.as_deref().or(share);
            let content = value.get("content").unwrap_or(value);
            let title = string(value, &["title"]).or_else(|| string(content, &["title"]));
            let id = string(value, &["item_id", "itemId", "id"]);
            if let (Some(title), Some(id)) = (title, id) {
                let username = first_string(value, &["username", "email"]).unwrap_or_default();
                let action = Action::Password(share.map(str::to_owned), id);
                items.push(Entry::new(Mode::Passwords, title, username, action));
            }
            for value in object.values() {
                password_items(value, share, items);
            }
        }
        _ => {}
    }
}

/// The first string under any of `keys`, at any depth.
fn first_string(value: &serde_json::Value, keys: &[&str]) -> Option<String> {
    match value {
        serde_json::Value::Object(object) => (keys.iter())
            .find_map(|key| object.get(*key)?.as_str().filter(|s| !s.is_empty()))
            .map(str::to_owned)
            .or_else(|| object.values().find_map(|value| first_string(value, keys))),
        serde_json::Value::Array(values) => {
            values.iter().find_map(|value| first_string(value, keys))
        }
        _ => None,
    }
}

/// Files and directories in the home directory whose path contains `query`, ignoring hidden and
/// ignored ones (as `fd` does by default).
pub async fn files(query: String) -> Vec<Entry> {
    let home = std::env::home_dir().unwrap_or_default();
    let output = async_process::Command::new("fd")
        .args([
            "--ignore-case",
            "--fixed-strings",
            "--max-results",
            "200",
            "--",
        ])
        .arg(&query)
        .current_dir(&home)
        .stdin(async_process::Stdio::null())
        .stderr(async_process::Stdio::null())
        .kill_on_drop(true)
        .output()
        .await;
    let Ok(output) = output else {
        return Vec::new();
    };
    String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|relative| {
            let relative = relative.trim_end_matches('/');
            let path = home.join(relative);
            let name = (Path::new(relative).file_name()).map_or_else(
                || relative.into(),
                |name| name.to_string_lossy().into_owned(),
            );
            let parent = Path::new(relative).parent().unwrap_or(Path::new(""));
            let mut entry = Entry::new(
                Mode::Files,
                name,
                format!("~/{}", parent.display()),
                Action::Open(path),
            );
            entry.extra = relative.to_owned();
            entry
        })
        .collect()
}

/// `query` evaluated by qalc (libqalculate): arithmetic, units, currencies, dates. Unless
/// `explicit` (calculator mode), None if the result is just the query back.
pub async fn calculate(query: String, explicit: bool) -> Option<Entry> {
    // Set by the devshell.
    let output = async_process::Command::new(env!("MYSHELL_QALC"))
        .args(["-t", "--", &query])
        .stdin(async_process::Stdio::null())
        .kill_on_drop(true)
        .output()
        .await
        .ok()?;
    let result = String::from_utf8_lossy(&output.stdout).trim().to_owned();
    let unchanged = !explicit && result.replace(' ', "") == query.replace(' ', "");
    if !output.status.success() || result.is_empty() || unchanged || result.contains("error") {
        return None;
    }
    let description = format!("{query}  \u{2014}  copy to clipboard");
    Some(Entry::new(
        Mode::Calculator,
        result.clone(),
        description,
        Action::Copy(result),
    ))
}

/// Puts text on the clipboard. wl-copy stays in the background to serve it.
pub async fn copy(text: String) -> Result<()> {
    let mut child = async_process::Command::new("wl-copy")
        .stdin(async_process::Stdio::piped())
        .stdout(async_process::Stdio::null())
        .spawn()?;
    let mut stdin = child.stdin.take().ok_or("no stdin")?;
    stdin.write_all(text.as_bytes()).await?;
    drop(stdin);
    child.status().await?;
    Ok(())
}

/// Reads the item's password from pass-cli, and puts it on the clipboard. It's only held as a
/// `SecretString`, and the raw output is zeroed. Logs each step, but never the password.
pub async fn copy_password(share: Option<String>, item: String) -> Result<()> {
    let uri;
    let arguments: Vec<&str> = match &share {
        Some(share) => {
            uri = format!("pass://{share}/{item}/password");
            vec!["item", "view", &uri]
        }
        None => vec!["item", "view", "--item-id", &item, "--field", "password"],
    };
    eprintln!("passwords: running {} {}", pass_cli(), arguments.join(" "));
    let (status, stdout, stderr) = run_secret(&arguments).await?;
    eprintln!(
        "passwords: item view exited with {status}, stderr: {:?}",
        stderr.trim()
    );
    if !status.success() {
        return Err(format!("pass-cli item view: {status}").into());
    }
    let password = password(&stdout).ok_or("pass-cli item view: no password in its output")?;
    copy_secret(&password).await?;
    eprintln!("passwords: copied to the clipboard");
    Ok(())
}

/// pass-cli's output, without its trailing newline. Copied once, into a buffer of exactly its
/// length, so `SecretString` doesn't reallocate (leaving a copy behind).
fn password(output: &[u8]) -> Option<SecretString> {
    let text = std::str::from_utf8(output).ok()?;
    let text = text.strip_suffix('\n').unwrap_or(text);
    let text = text.strip_suffix('\r').unwrap_or(text);
    (!text.is_empty()).then(|| SecretString::from(text.to_owned()))
}

async fn copy_secret(secret: &SecretString) -> Result<()> {
    let mut child = async_process::Command::new("wl-copy")
        .stdin(async_process::Stdio::piped())
        .stdout(async_process::Stdio::null())
        .spawn()?;
    let mut stdin = child.stdin.take().ok_or("no stdin")?;
    stdin.write_all(secret.expose_secret().as_bytes()).await?;
    drop(stdin);
    let status = child.status().await?;
    if !status.success() {
        return Err(format!("wl-copy: {status}").into());
    }
    Ok(())
}

/// e.g. `htop -d 5`: the program chosen, with any arguments typed after its name.
pub fn run_program(path: &Path, arguments: &str) -> Result<()> {
    let name = path
        .file_name()
        .map_or_else(String::new, |name| name.to_string_lossy().into());
    let command: Vec<String> = std::iter::once(path.display().to_string())
        .chain(arguments.split_whitespace().map(str::to_owned))
        .collect();
    desktop_entry::spawn_in_terminal(&name, &name, &command)
}

pub fn open(path: &Path) -> Result<()> {
    let name = path
        .file_name()
        .map_or_else(String::new, |name| name.to_string_lossy().into());
    desktop_entry::spawn(
        "xdg-open",
        &name,
        &["xdg-open".into(), path.display().to_string()],
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn logged_shape_has_no_values() {
        let json =
            serde_json::json!({"items": [{"title": "GitHub", "password": "hunter2", "n": 4}]});
        let shape = shape(&json, 0);
        assert_eq!(
            shape,
            r#"{"items": [1 x {"title": str, "password": str, "n": number}]}"#
        );
    }

    #[test]
    fn password_items_are_found_in_nested_json() {
        let json = serde_json::json!({"items": [
            {"share_id": "s1", "items": [{"id": "i1", "content": {"title": "GitHub", "content": {"Login": {"username": "me"}}}}]},
        ]});
        let mut items = Vec::new();
        password_items(&json, None, &mut items);
        assert_eq!(items.len(), 1);
        assert_eq!(
            (items[0].name.as_str(), items[0].description.as_str()),
            ("GitHub", "me")
        );
        assert!(
            matches!(&items[0].action, Action::Password(Some(share), id) if share == "s1" && id == "i1")
        );
    }
}

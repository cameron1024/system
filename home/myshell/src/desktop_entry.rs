//! Installed applications, from their desktop entries (a subset of the freedesktop Desktop Entry
//! spec: unlocalised keys, no actions), and launching them.

use std::collections::HashMap;
use std::collections::HashSet;
use std::path::Path;
use std::sync::Arc;

use gpui::RenderImage;

use crate::data_source::Result;
use crate::icon_theme;

#[derive(Clone)]
pub struct App {
    /// The desktop file ID, e.g. "org.gnome.Nautilus".
    pub id: String,
    pub name: String,
    /// GenericName, else Comment.
    pub description: String,
    /// Description and keywords, which searches also match (below the name).
    pub extra: String,
    /// Its icon file, if any, and that rendered (once tried; it may have failed).
    icon_path: Option<String>,
    pub icon: Option<Arc<RenderImage>>,
    rendered: bool,
    /// Arguments, with field codes expanded.
    exec: Vec<String>,
    terminal: bool,
}

/// Every app to show, by name. Earlier data directories override later ones, as the spec says.
/// Icons rendered by `previous` scans are reused where the file is the same; `render_icons`
/// renders the rest. Reads files, so keep it off the UI thread.
pub fn scan(previous: &[App]) -> Vec<App> {
    let desktops: Vec<String> = std::env::var("XDG_CURRENT_DESKTOP")
        .unwrap_or_default()
        .split(':')
        .map(str::to_lowercase)
        .collect();
    let mut seen = HashSet::new();
    let mut apps = Vec::new();
    for dir in icon_theme::data_dirs() {
        let root = dir.join("applications");
        walk(&root, &root, &desktops, &mut seen, &mut apps);
    }
    apps.sort_by_cached_key(|app| app.name.to_lowercase());
    let rendered: HashMap<&str, &Option<Arc<RenderImage>>> = (previous.iter())
        .filter(|app| app.rendered)
        .filter_map(|app| Some((app.icon_path.as_deref()?, &app.icon)))
        .collect();
    for app in &mut apps {
        let reused = app.icon_path.as_deref().and_then(|path| rendered.get(path));
        app.rendered = app.icon_path.is_none() || reused.is_some();
        app.icon = reused.and_then(|icon| (*icon).clone());
    }
    apps
}

/// Renders icons `scan` couldn't reuse, at `size` pixels. Returns whether there were any. Reads
/// and renders files, so keep it off the UI thread.
pub fn render_icons(apps: &mut [App], size: u32) -> bool {
    let mut any = false;
    for app in apps.iter_mut().filter(|app| !app.rendered) {
        app.icon = (app.icon_path.as_deref()).and_then(|path| icon_theme::render(path, size));
        app.rendered = true;
        any = true;
    }
    any
}

fn walk(
    root: &Path,
    dir: &Path,
    desktops: &[String],
    seen: &mut HashSet<String>,
    apps: &mut Vec<App>,
) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            walk(root, &path, desktops, seen, apps);
            continue;
        }
        if path
            .extension()
            .is_none_or(|extension| extension != "desktop")
        {
            continue;
        }
        // e.g. applications/kde/foo.desktop is "kde-foo".
        let Some(id) = (path.strip_prefix(root).ok())
            .and_then(|relative| relative.with_extension("").to_str().map(str::to_owned))
            .map(|relative| relative.replace('/', "-"))
        else {
            continue;
        };
        // Hidden or unshown entries still override others with the same ID.
        if !seen.insert(id.clone()) {
            continue;
        }
        if let Some(app) = std::fs::read_to_string(&path)
            .ok()
            .and_then(|text| parse(id, &text, &path, desktops))
        {
            apps.push(app);
        }
    }
}

fn parse(id: String, text: &str, path: &Path, desktops: &[String]) -> Option<App> {
    let mut in_entry = false;
    let mut fields = std::collections::HashMap::new();
    for line in text.lines().map(str::trim) {
        if line.starts_with('[') {
            in_entry = line == "[Desktop Entry]";
        } else if in_entry
            && let Some((key, value)) = line.split_once('=')
            // Localised keys (e.g. Name[de]) aren't used.
            && !key.contains('[')
        {
            fields.insert(key.trim(), value.trim());
        }
    }
    let get = |key: &str| fields.get(key).copied().unwrap_or_default();
    let flag = |key: &str| get(key) == "true";
    let listed = |key: &str| {
        get(key)
            .split(';')
            .any(|desktop| desktops.contains(&desktop.to_lowercase()))
    };
    if get("Type") != "Application"
        || flag("NoDisplay")
        || flag("Hidden")
        || (!get("OnlyShowIn").is_empty() && !listed("OnlyShowIn"))
        || listed("NotShowIn")
        || (!get("TryExec").is_empty() && !executable(&unescape(get("TryExec"))))
    {
        return None;
    }
    let name = unescape(get("Name"));
    let icon_name = unescape(get("Icon"));
    let exec = arguments(
        &unescape(get("Exec")),
        &name,
        &icon_name,
        path.to_str().unwrap_or_default(),
    );
    if name.is_empty() || exec.is_empty() {
        return None;
    }
    let description = [get("GenericName"), get("Comment")]
        .into_iter()
        .find(|text| !text.is_empty())
        .map(unescape)
        .unwrap_or_default();
    let icon_path = match icon_name.as_str() {
        "" => None,
        path if path.starts_with('/') => Path::new(path).is_file().then(|| path.to_owned()),
        name => icon_theme::lookup(name, false),
    };
    Some(App {
        extra: format!(
            "{description} {}",
            unescape(get("Keywords")).replace(';', " ")
        ),
        id,
        name,
        description,
        icon_path,
        icon: None,
        rendered: false,
        exec,
        terminal: flag("Terminal"),
    })
}

/// The spec's escapes for string values.
fn unescape(value: &str) -> String {
    let mut result = String::with_capacity(value.len());
    let mut chars = value.chars();
    while let Some(char) = chars.next() {
        if char != '\\' {
            result.push(char);
            continue;
        }
        match chars.next() {
            Some('s') => result.push(' '),
            Some('n') => result.push('\n'),
            Some('t') => result.push('\t'),
            Some('r') => result.push('\r'),
            Some(other) => result.push(other),
            None => {}
        }
    }
    result
}

/// Splits Exec into arguments (double quotes group, and backslashes escape, as GLib parses it:
/// e.g. Wine's entries escape spaces outside quotes), then expands field codes. Nothing is passed
/// to open, so file and URL codes are dropped.
fn arguments(exec: &str, name: &str, icon: &str, path: &str) -> Vec<String> {
    let mut arguments = Vec::new();
    let mut current: Option<String> = None;
    let mut chars = exec.chars();
    while let Some(char) = chars.next() {
        match char {
            '"' => {
                let argument = current.get_or_insert_default();
                while let Some(char) = chars.next() {
                    match char {
                        '"' => break,
                        '\\' => argument.extend(chars.next()),
                        char => argument.push(char),
                    }
                }
            }
            '\\' => current.get_or_insert_default().extend(chars.next()),
            ' ' | '\t' => arguments.extend(current.take()),
            char => current.get_or_insert_default().push(char),
        }
    }
    arguments.extend(current);
    arguments
        .into_iter()
        .flat_map(|argument| match argument.as_str() {
            "%i" if !icon.is_empty() => vec!["--icon".into(), icon.into()],
            "%f" | "%F" | "%u" | "%U" | "%i" | "%d" | "%D" | "%n" | "%N" | "%v" | "%m" => vec![],
            _ => vec![
                argument
                    .replace("%c", name)
                    .replace("%k", path)
                    .replace("%%", "%"),
            ],
        })
        .collect()
}

fn executable(program: &str) -> bool {
    if program.contains('/') {
        return Path::new(program).is_file();
    }
    std::env::var_os("PATH")
        .is_some_and(|paths| std::env::split_paths(&paths).any(|dir| dir.join(program).is_file()))
}

impl App {
    /// Starts it in its own systemd scope, as the systemd XDG integration recommends, so it
    /// isn't part of the shell (e.g. stopped when the shell restarts).
    pub fn launch(&self) -> Result<()> {
        let mut arguments = self.exec.clone();
        if self.terminal {
            let terminal = std::env::var("TERMINAL").unwrap_or_else(|_| "xdg-terminal-exec".into());
            arguments.splice(0..0, [terminal, "-e".into()]);
        }
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .subsec_nanos();
        let unit = format!("app-myshell-{}-{nanos:x}.scope", unit_escape(&self.id));
        // The app runs as this child (systemd-run execs it). Once dropped, async-process reaps it
        // when it exits, without waiting here.
        async_process::Command::new("systemd-run")
            .args(["--user", "--scope", "--collect", "--quiet"])
            .arg(format!("--unit={unit}"))
            .arg(format!("--description={}", self.name))
            .arg("--")
            .args(&arguments)
            .stdin(async_process::Stdio::null())
            .stdout(async_process::Stdio::null())
            .spawn()?;
        Ok(())
    }
}

/// Like `systemd-escape`: unit names allow only a few characters, and dashes separate fields.
fn unit_escape(id: &str) -> String {
    id.bytes()
        .map(|byte| match byte {
            b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b':' | b'_' | b'.' => {
                (byte as char).to_string()
            }
            byte => format!("\\x{byte:02x}"),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn exec_arguments_follow_the_spec() {
        let exec = unescape(r#"env A="b c" app --name=%c %U "a\\"b" C:\\\\x\\ y 100%%"#);
        assert_eq!(
            arguments(&exec, "App", "", "/x.desktop"),
            [
                "env",
                "A=b c",
                "app",
                "--name=App",
                "a\"b",
                r"C:\x y",
                "100%"
            ]
        );
    }
}

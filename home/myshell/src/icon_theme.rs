//! Resolves icons to files, following (a simplified version of) the freedesktop icon theme spec:
//! the GTK icon theme, what it inherits, then hicolor.

use std::path::Path;
use std::path::PathBuf;
use std::sync::OnceLock;

/// Tried in order: an image path or name from the hints, the app icon, the sender's desktop
/// entry's icon, then the app name as an icon name.
pub fn resolve(
    image_path: Option<&str>,
    app_icon: &str,
    desktop_entry: Option<&str>,
    app_name: &str,
) -> Option<String> {
    let desktop_icon = desktop_entry.and_then(desktop_entry_icon);
    [
        image_path,
        Some(app_icon),
        desktop_icon.as_deref(),
        Some(&app_name.to_lowercase()),
    ]
    .into_iter()
    .flatten()
    .filter(|icon| !icon.is_empty())
    .find_map(|icon| {
        let path = icon.strip_prefix("file://").unwrap_or(icon);
        if path.starts_with('/') {
            Path::new(path).is_file().then(|| path.to_owned())
        } else {
            lookup(icon, false)
        }
    })
}

fn data_dirs() -> &'static [PathBuf] {
    static DIRS: OnceLock<Vec<PathBuf>> = OnceLock::new();
    DIRS.get_or_init(|| {
        let home = std::env::home_dir().unwrap_or_default();
        let user = std::env::var("USER").unwrap_or_default();
        let mut dirs = vec![
            std::env::var_os("XDG_DATA_HOME")
                .map(PathBuf::from)
                .unwrap_or_else(|| home.join(".local/share")),
            home.join(".nix-profile/share"),
            PathBuf::from(format!("/etc/profiles/per-user/{user}/share")),
            PathBuf::from("/run/current-system/sw/share"),
        ];
        let system = std::env::var("XDG_DATA_DIRS").unwrap_or_default();
        dirs.extend(
            system
                .split(':')
                .filter(|dir| !dir.is_empty())
                .map(PathBuf::from),
        );
        dirs.push(PathBuf::from("/usr/share"));
        dirs.dedup();
        dirs.retain(|dir| dir.is_dir());
        dirs
    })
}

/// Each theme, in lookup order, with its directories (from index.theme) in each base.
fn themes() -> &'static [(PathBuf, Vec<String>)] {
    static THEMES: OnceLock<Vec<(PathBuf, Vec<String>)>> = OnceLock::new();
    THEMES.get_or_init(|| {
        let home = std::env::home_dir().unwrap_or_default();
        let configured = ["gtk-4.0", "gtk-3.0"].iter().find_map(|gtk| {
            let settings =
                std::fs::read_to_string(home.join(".config").join(gtk).join("settings.ini"))
                    .ok()?;
            settings.lines().find_map(|line| {
                Some(
                    line.strip_prefix("gtk-icon-theme-name")?
                        .trim_start_matches([' ', '='])
                        .trim()
                        .to_owned(),
                )
            })
        });
        let bases: Vec<PathBuf> = std::iter::once(home.join(".icons"))
            .chain(data_dirs().iter().map(|dir| dir.join("icons")))
            .collect();
        let mut queue: Vec<String> = configured.into_iter().collect();
        queue.push("hicolor".into());
        let mut seen = Vec::new();
        let mut themes = Vec::new();
        while let Some(theme) = (!queue.is_empty()).then(|| queue.remove(0)) {
            if seen.contains(&theme) {
                continue;
            }
            seen.push(theme.clone());
            for base in &bases {
                let dir = base.join(&theme);
                let Ok(index) = std::fs::read_to_string(dir.join("index.theme")) else {
                    continue;
                };
                let list = |key: &str| -> Vec<String> {
                    index
                        .lines()
                        .find_map(|line| line.strip_prefix(key))
                        .map(|value| {
                            value
                                .split(',')
                                .map(|item| item.trim().to_owned())
                                .collect()
                        })
                        .unwrap_or_default()
                };
                // Inherited themes come after this one, but before hicolor.
                let at = queue.len().saturating_sub(1);
                for parent in list("Inherits=").into_iter().rev() {
                    queue.insert(at.min(queue.len()), parent);
                }
                themes.push((dir, list("Directories=")));
            }
        }
        themes
    })
}

/// The first theme with the icon wins; within it, the largest (scalable counts as largest),
/// preferring SVG. Symbolic (monochrome) directories are skipped unless `symbolic`.
pub fn lookup(name: &str, symbolic: bool) -> Option<String> {
    for (theme, directories) in themes() {
        let mut best: Option<((u32, bool), PathBuf)> = None;
        for directory in (directories.iter()).filter(|dir| symbolic || !dir.contains("symbolic")) {
            for extension in ["svg", "png"] {
                let path = theme.join(directory).join(format!("{name}.{extension}"));
                if !path.is_file() {
                    continue;
                }
                let size = if directory.contains("scalable") {
                    u32::MAX
                } else {
                    directory
                        .split(['/', 'x', '@'])
                        .find_map(|part| part.parse::<u32>().ok())
                        .unwrap_or(1)
                };
                let rank = (size, extension == "svg");
                if best.as_ref().is_none_or(|(best, _)| rank > *best) {
                    best = Some((rank, path));
                }
            }
        }
        if let Some((_, path)) = best {
            return path.to_str().map(str::to_owned);
        }
    }
    data_dirs().iter().find_map(|dir| {
        ["svg", "png"].iter().find_map(|extension| {
            let path = dir.join("pixmaps").join(format!("{name}.{extension}"));
            path.is_file()
                .then(|| path.to_str().map(str::to_owned))
                .flatten()
        })
    })
}

fn desktop_entry_icon(entry: &str) -> Option<String> {
    data_dirs().iter().find_map(|dir| {
        let file =
            std::fs::read_to_string(dir.join("applications").join(format!("{entry}.desktop")))
                .ok()?;
        file.lines()
            .find_map(|line| line.strip_prefix("Icon="))
            .map(|icon| icon.trim().to_owned())
    })
}

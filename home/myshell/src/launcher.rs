//! The launcher's state: its entries (from several sources, one per mode), the query, and the
//! matches. Shared by every bar, though only one shows it at a time. Sources are re-read in the
//! background each time it opens; files and the calculator are queried as you type.
//!
//! A prefix picks a mode; without one, every mode's entries are searched together, weighted.

mod sources;

use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

use futures::channel::oneshot;
use gpui::Context;
use gpui::RenderImage;
use gpui::Task;
use nucleo_matcher::Config;
use nucleo_matcher::Matcher;
use nucleo_matcher::Utf32Str;
use nucleo_matcher::pattern::CaseMatching;
use nucleo_matcher::pattern::Normalization;
use nucleo_matcher::pattern::Pattern;

use crate::animated_icon::Icon;
use crate::desktop_entry;
use crate::desktop_entry::App;

/// Results shown at once; the list scrolls to keep the selection among them.
pub const VISIBLE: usize = 8;
/// Apps' icons, in logical pixels. They're rendered at twice this, for HiDPI displays.
pub const ICON_SIZE: f32 = 28.;
/// At most this many results are kept.
const MAX_RESULTS: usize = 200;
/// Typing pauses this long before files and the calculator are queried.
const DEBOUNCE: Duration = Duration::from_millis(80);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Mode {
    Auto,
    Desktop,
    Programs,
    Passwords,
    Files,
    Environment,
    Calculator,
    Emoji,
    /// Options from `myshell-menu`, like dmenu.
    Menu,
}

impl Mode {
    /// In the order of the mode selector.
    pub const SELECTABLE: [Self; 8] = [
        Self::Auto,
        Self::Desktop,
        Self::Programs,
        Self::Passwords,
        Self::Files,
        Self::Environment,
        Self::Calculator,
        Self::Emoji,
    ];

    pub fn prefix(self) -> Option<char> {
        match self {
            Self::Desktop => Some('#'),
            Self::Programs => Some('>'),
            Self::Passwords => Some('*'),
            Self::Files => Some('/'),
            Self::Environment => Some('$'),
            Self::Calculator => Some('='),
            Self::Emoji => Some(':'),
            Self::Auto | Self::Menu => None,
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            Self::Auto => "Search",
            Self::Desktop => "Apps",
            Self::Programs => "Programs",
            Self::Passwords => "Passwords",
            Self::Files => "Files",
            Self::Environment => "Environment",
            Self::Calculator => "Calculator",
            Self::Emoji => "Emoji",
            Self::Menu => "Menu",
        }
    }

    pub fn icon(self) -> Icon {
        match self {
            Self::Auto => Icon::Sparkles,
            Self::Desktop => Icon::Apps,
            Self::Programs => Icon::Terminal,
            Self::Passwords => Icon::Key,
            Self::Files => Icon::FileSearch,
            Self::Environment => Icon::Dollar,
            Self::Calculator => Icon::Calculator,
            Self::Emoji => Icon::Smile,
            Self::Menu => Icon::List,
        }
    }

    pub fn placeholder(self) -> &'static str {
        match self {
            Self::Auto => "Search",
            Self::Desktop => "Search apps",
            Self::Programs => "Run a program in a terminal",
            Self::Passwords => "Copy a password",
            Self::Files => "Search files",
            Self::Environment => "Copy an environment variable",
            Self::Calculator => "Calculate, e.g. 10 km to mi",
            Self::Emoji => "Copy an emoji",
            Self::Menu => "Choose",
        }
    }

    /// In auto mode, match scores are multiplied by this.
    fn weight(self) -> u32 {
        match self {
            Self::Desktop => 4,
            Self::Passwords => 2,
            _ => 1,
        }
    }
}

#[derive(Clone)]
pub struct Entry {
    pub mode: Mode,
    pub name: String,
    pub description: String,
    /// Also searched, below the name (e.g. an app's keywords).
    extra: String,
    pub icon: Option<Arc<RenderImage>>,
    action: Action,
}

impl Entry {
    fn new(mode: Mode, name: String, description: String, action: Action) -> Self {
        Self {
            mode,
            name,
            description,
            extra: String::new(),
            icon: None,
            action,
        }
    }

    /// The emoji itself, for an emoji entry.
    pub fn emoji(&self) -> Option<&str> {
        match (&self.action, self.mode) {
            (Action::Copy(emoji), Mode::Emoji) => Some(emoji),
            _ => None,
        }
    }

    fn app(app: &App) -> Self {
        Self {
            mode: Mode::Desktop,
            name: app.name.clone(),
            description: app.description.clone(),
            extra: app.extra.clone(),
            icon: app.icon.clone(),
            action: Action::App(app.clone()),
        }
    }
}

#[derive(Clone)]
enum Action {
    App(App),
    /// Run in a terminal, with any arguments typed after its name.
    Program(PathBuf),
    /// The vault's share ID (if known) and the item's ID.
    Password(Option<String>, String),
    Copy(String),
    Open(PathBuf),
    /// Answers `myshell-menu`.
    Choose(String),
}

/// A `myshell-menu` request: its prompt, and where to send the choice. Dropping it cancels.
#[derive(Debug)]
pub struct Menu {
    pub prompt: Option<String>,
    pub options: Vec<String>,
    pub reply: oneshot::Sender<String>,
}

/// Where a cursor movement (or deletion) goes.
#[derive(Clone, Copy)]
pub enum Motion {
    Left,
    Right,
    WordLeft,
    WordRight,
    Start,
    End,
}

pub struct Launcher {
    apps: Arc<Vec<App>>,
    desktop: Vec<Entry>,
    programs: Vec<Entry>,
    environment: Vec<Entry>,
    passwords: Vec<Entry>,
    /// Built when first opened; it never changes.
    emoji: Vec<Entry>,
    /// The query they're for, and the results.
    files: (String, Vec<Entry>),
    calculation: (String, Option<Entry>),
    menu: Option<(Option<String>, oneshot::Sender<String>)>,
    menu_entries: Vec<Entry>,
    /// Whether apps have been scanned yet.
    pub scanned: bool,
    pub query: String,
    /// Byte offsets into the query: the cursor, and the other end of the selection.
    pub cursor: usize,
    anchor: usize,
    results: Vec<Entry>,
    pub selected: usize,
    /// The first result shown.
    pub scroll: usize,
    matcher: Matcher,
    _scans: Vec<Task<()>>,
    _query: Option<Task<()>>,
}

impl Launcher {
    pub fn new() -> Self {
        Self {
            apps: Arc::default(),
            desktop: Vec::new(),
            programs: Vec::new(),
            environment: Vec::new(),
            passwords: Vec::new(),
            emoji: Vec::new(),
            files: Default::default(),
            calculation: Default::default(),
            menu: None,
            menu_entries: Vec::new(),
            scanned: false,
            query: String::new(),
            cursor: 0,
            anchor: 0,
            results: Vec::new(),
            selected: 0,
            scroll: 0,
            matcher: Matcher::new(Config::DEFAULT),
            _scans: Vec::new(),
            _query: None,
        }
    }

    /// Starts afresh in auto mode (or with `menu`'s options), showing the last scans' entries
    /// until new ones finish.
    pub fn open(&mut self, menu: Option<Menu>, cx: &mut Context<Self>) {
        self.query.clear();
        (self.cursor, self.anchor) = (0, 0);
        self.files = Default::default();
        self.calculation = Default::default();
        self._query = None;
        self.menu_entries.clear();
        self.menu = menu.map(|menu| {
            self.menu_entries = (menu.options.into_iter())
                .map(|option| {
                    Entry::new(
                        Mode::Menu,
                        option.clone(),
                        String::new(),
                        Action::Choose(option),
                    )
                })
                .collect();
            (menu.prompt, menu.reply)
        });
        self.search();
        cx.notify();
        if self.menu.is_some() {
            return;
        }
        let executor = cx.background_executor().clone();
        let previous = self.apps.clone();
        let apps = cx.spawn(async move |this, cx| {
            let mut apps = executor
                .spawn(async move { desktop_entry::scan(&previous) })
                .await;
            let set = |apps: &Vec<App>, cx: &mut gpui::AsyncApp| {
                let apps = Arc::new(apps.clone());
                this.update(cx, |this, cx| {
                    this.desktop = apps.iter().map(Entry::app).collect();
                    this.apps = apps;
                    this.scanned = true;
                    this.refresh();
                    cx.notify();
                })
            };
            if set(&apps, cx).is_err() {
                return;
            }
            let (rendered, apps) = executor
                .spawn(async move {
                    let rendered = desktop_entry::render_icons(&mut apps, (ICON_SIZE * 2.) as u32);
                    (rendered, apps)
                })
                .await;
            if rendered {
                let _ = set(&apps, cx);
            }
        });
        let executor = cx.background_executor().clone();
        let need_emoji = self.emoji.is_empty();
        let others = cx.spawn(async move |this, cx| {
            let (programs, environment, emoji) = executor
                .spawn(async move {
                    let emoji = need_emoji.then(sources::emoji);
                    (sources::programs(), sources::environment(), emoji)
                })
                .await;
            let _ = this.update(cx, |this, cx| {
                (this.programs, this.environment) = (programs, environment);
                if let Some(emoji) = emoji {
                    this.emoji = emoji;
                }
                this.refresh();
                cx.notify();
            });
            let passwords = executor.spawn(sources::passwords()).await;
            let _ = this.update(cx, |this, cx| {
                this.passwords = passwords;
                this.refresh();
                cx.notify();
            });
        });
        self._scans = vec![apps, others];
    }

    /// Cancels a pending `myshell-menu` request, if any.
    pub fn close(&mut self) {
        self.menu = None;
        self._query = None;
    }

    /// The mode, from the query's prefix, and the query without it.
    pub fn mode(&self) -> (Mode, &str) {
        if self.menu.is_some() {
            return (Mode::Menu, self.query.trim());
        }
        let mut chars = self.query.chars();
        let mode = chars.next().and_then(|first| {
            (Mode::SELECTABLE.into_iter()).find(|mode| mode.prefix() == Some(first))
        });
        match mode {
            Some(mode) => (mode, chars.as_str().trim()),
            None => (Mode::Auto, self.query.trim()),
        }
    }

    /// `myshell-menu`'s prompt, if it gave one.
    pub fn prompt(&self) -> Option<&str> {
        self.menu.as_ref()?.0.as_deref()
    }

    /// Replaces the query's prefix with `mode`'s, keeping the rest.
    pub fn set_mode(&mut self, mode: Mode, cx: &mut Context<Self>) {
        if self.menu.is_some() {
            return;
        }
        let rest = self.mode().1.to_owned();
        self.query = mode
            .prefix()
            .map_or(rest.clone(), |prefix| format!("{prefix}{rest}"));
        (self.cursor, self.anchor) = (self.query.len(), self.query.len());
        self.edited(cx);
    }

    /// Switches to the next (or previous) mode in the selector, wrapping around. A menu has no
    /// modes, so it moves the selection instead.
    pub fn cycle_mode(&mut self, delta: isize, cx: &mut Context<Self>) {
        if self.menu.is_some() {
            return self.select(delta, cx);
        }
        let modes = Mode::SELECTABLE;
        let current = modes
            .iter()
            .position(|mode| *mode == self.mode().0)
            .unwrap_or(0);
        let next = (current as isize + delta).rem_euclid(modes.len() as isize) as usize;
        self.set_mode(modes[next], cx);
    }

    /// Re-runs the search over new entries, keeping the selection if it's still a result.
    fn refresh(&mut self) {
        let selected = self
            .selected_entry()
            .map(|entry| (entry.mode, entry.name.clone()));
        self.search();
        let index = selected.and_then(|selected| {
            (self.results.iter())
                .position(|entry| (entry.mode, &entry.name) == (selected.0, &selected.1))
        });
        if let Some(index) = index {
            self.set_selected(index);
        }
    }

    pub fn results(&self) -> &[Entry] {
        &self.results
    }

    pub fn selected_entry(&self) -> Option<&Entry> {
        self.results.get(self.selected)
    }

    /// Runs the entry at `index` (or the selected one). With none, a menu returns the query, as
    /// dmenu does.
    pub fn choose(&mut self, index: Option<usize>, cx: &mut Context<Self>) {
        let entry = self.results.get(index.unwrap_or(self.selected)).cloned();
        let (mode, text) = self.mode();
        let arguments = match mode {
            Mode::Programs => text
                .split_once(char::is_whitespace)
                .map_or("", |(_, rest)| rest),
            _ => "",
        }
        .to_owned();
        let choice = match entry {
            Some(entry) => entry.action,
            None if mode == Mode::Menu => Action::Choose(text.to_owned()),
            None => return,
        };
        let run = |result: crate::data_source::Result<()>| {
            if let Err(error) = result {
                eprintln!("launcher: {error}");
            }
        };
        let executor = cx.background_executor().clone();
        match choice {
            Action::App(app) => run(app.launch()),
            Action::Program(path) => run(sources::run_program(&path, &arguments)),
            Action::Open(path) => run(sources::open(&path)),
            Action::Copy(text) => executor
                .spawn(async move { run(sources::copy(text).await) })
                .detach(),
            Action::Password(share, item) => executor
                .spawn(async move { run(sources::copy_password(share, item).await) })
                .detach(),
            Action::Choose(text) => {
                if let Some((_, reply)) = self.menu.take() {
                    let _ = reply.send(text);
                }
            }
        }
    }

    pub fn selection(&self) -> std::ops::Range<usize> {
        self.cursor.min(self.anchor)..self.cursor.max(self.anchor)
    }

    pub fn selected_text(&self) -> &str {
        &self.query[self.selection()]
    }

    /// Words are separated by whitespace.
    fn target(&self, motion: Motion) -> usize {
        let (query, cursor) = (&self.query, self.cursor);
        match motion {
            Motion::Left => (query[..cursor].char_indices().next_back()).map_or(0, |(at, _)| at),
            Motion::Right => {
                (query[cursor..].chars().next()).map_or(cursor, |c| cursor + c.len_utf8())
            }
            Motion::WordLeft => {
                let before = query[..cursor].trim_end();
                (before.char_indices().rev())
                    .find(|(_, c)| c.is_whitespace())
                    .map_or(0, |(at, c)| at + c.len_utf8())
            }
            Motion::WordRight => {
                let after = &query[cursor..];
                let word = after.trim_start();
                let spaces = after.len() - word.len();
                cursor + spaces + word.find(char::is_whitespace).unwrap_or(word.len())
            }
            Motion::Start => 0,
            Motion::End => query.len(),
        }
    }

    /// With `extend`, the selection grows to the new position; otherwise it's dropped (moving
    /// left or right collapses it to that end, as text fields do).
    pub fn move_to(&mut self, motion: Motion, extend: bool, cx: &mut Context<Self>) {
        let selection = self.selection();
        self.cursor = match motion {
            Motion::Left if !extend && !selection.is_empty() => selection.start,
            Motion::Right if !extend && !selection.is_empty() => selection.end,
            motion => self.target(motion),
        };
        if !extend {
            self.anchor = self.cursor;
        }
        cx.notify();
    }

    pub fn select_all(&mut self, cx: &mut Context<Self>) {
        (self.anchor, self.cursor) = (0, self.query.len());
        cx.notify();
    }

    /// Replaces the selection (or inserts at the cursor).
    pub fn insert(&mut self, text: &str, cx: &mut Context<Self>) {
        let selection = self.selection();
        self.query.replace_range(selection.clone(), text);
        self.cursor = selection.start + text.len();
        self.anchor = self.cursor;
        self.edited(cx);
    }

    /// Deletes the selection, or else from the cursor to where `motion` goes.
    pub fn delete(&mut self, motion: Motion, cx: &mut Context<Self>) {
        if self.selection().is_empty() {
            self.cursor = self.target(motion);
        }
        self.insert("", cx);
    }

    /// Wraps around at either end.
    pub fn select(&mut self, delta: isize, cx: &mut Context<Self>) {
        let count = self.results.len() as isize;
        if count > 0 {
            self.set_selected((self.selected as isize + delta).rem_euclid(count) as usize);
            cx.notify();
        }
    }

    fn set_selected(&mut self, selected: usize) {
        self.selected = selected;
        if selected < self.scroll {
            self.scroll = selected;
        } else if selected >= self.scroll + VISIBLE {
            self.scroll = selected + 1 - VISIBLE;
        }
    }

    /// Searches, then queries files and the calculator for the new text if needed (after a
    /// pause, cancelling any earlier query).
    fn edited(&mut self, cx: &mut Context<Self>) {
        self.search();
        cx.notify();
        let (mode, text) = self.mode();
        let text = text.to_owned();
        let files = match mode {
            Mode::Files => !text.is_empty(),
            Mode::Auto => text.chars().count() >= 3,
            _ => false,
        };
        let calculate = match mode {
            Mode::Calculator => !text.is_empty(),
            // Words alone are often valid expressions (e.g. units), but not worth showing.
            Mode::Auto => text.contains(|c: char| c.is_ascii_digit()),
            _ => false,
        };
        let stale = (files && self.files.0 != text) || (calculate && self.calculation.0 != text);
        if !stale {
            return;
        }
        self._query = Some(cx.spawn(async move |this, cx| {
            async_io::Timer::after(DEBOUNCE).await;
            let file_query = files.then(|| sources::files(text.clone()));
            let explicit = mode == Mode::Calculator;
            let calculation = calculate.then(|| sources::calculate(text.clone(), explicit));
            let (files, calculation) = futures::join!(
                async {
                    match file_query {
                        Some(query) => query.await,
                        None => Vec::new(),
                    }
                },
                async {
                    match calculation {
                        Some(calculation) => calculation.await,
                        None => None,
                    }
                },
            );
            let _ = this.update(cx, |this, cx| {
                this.files = (text.clone(), files);
                this.calculation = (text, calculation);
                this.refresh();
                cx.notify();
            });
        }));
    }

    /// Names match above `extra` (e.g. keywords). Within auto mode, entries are weighted by
    /// mode. With no query, a mode lists everything (auto lists apps). Up to a few thousand
    /// short strings, which is fast enough for every keystroke.
    fn search(&mut self) {
        self.scroll = 0;
        self.selected = 0;
        let (mode, text) = self.mode();
        let text = text.to_owned();
        let sources: Vec<&[Entry]> = match mode {
            Mode::Auto => vec![
                &self.desktop,
                &self.passwords,
                &self.programs,
                &self.environment,
                if self.files.0 == text {
                    &self.files.1
                } else {
                    &[]
                },
            ],
            Mode::Desktop => vec![&self.desktop],
            Mode::Programs => vec![&self.programs],
            Mode::Passwords => vec![&self.passwords],
            Mode::Files if self.files.0 == text => vec![&self.files.1],
            Mode::Environment => vec![&self.environment],
            Mode::Emoji => vec![&self.emoji],
            Mode::Menu => vec![&self.menu_entries],
            Mode::Files | Mode::Calculator => vec![],
        };
        // The calculation, if it's for this text, always comes first.
        let calculation = (self.calculation.0 == text)
            .then(|| self.calculation.1.clone())
            .flatten();
        let mut results: Vec<Entry> = calculation.into_iter().collect();
        if text.is_empty() {
            let all = match mode {
                Mode::Auto => &self.desktop[..],
                Mode::Files | Mode::Calculator => &[],
                _ => sources.first().copied().unwrap_or_default(),
            };
            results.extend(all.iter().take(MAX_RESULTS).cloned());
            self.results = results;
            return;
        }
        // Programs are matched by name, before any arguments.
        let pattern_text = match mode {
            Mode::Programs => text.split_whitespace().next().unwrap_or_default(),
            _ => &text,
        };
        let pattern = Pattern::parse(pattern_text, CaseMatching::Smart, Normalization::Smart);
        let mut buffer = Vec::new();
        let mut scored: Vec<(u32, &Entry)> = (sources.iter().flat_map(|entries| entries.iter()))
            .filter_map(|entry| {
                let mut score =
                    |text: &str| pattern.score(Utf32Str::new(text, &mut buffer), &mut self.matcher);
                let name = score(&entry.name).map(|score| score * 2);
                let extra = (!entry.extra.is_empty())
                    .then(|| score(&entry.extra))
                    .flatten();
                let weight = if mode == Mode::Auto {
                    entry.mode.weight()
                } else {
                    1
                };
                Some((name.max(extra)? * weight, entry))
            })
            .collect();
        // Stable, so equal scores stay in each source's order.
        scored.sort_by_key(|&(score, _)| std::cmp::Reverse(score));
        results.extend((scored.into_iter().take(MAX_RESULTS)).map(|(_, entry)| entry.clone()));
        self.results = results;
    }
}

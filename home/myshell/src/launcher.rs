//! The launcher's state: installed apps, the query, and the matches. Shared by every bar, though
//! only one shows it at a time. Apps are rescanned in the background each time it opens.

use std::sync::Arc;

use gpui::Context;
use gpui::Task;
use nucleo_matcher::Config;
use nucleo_matcher::Matcher;
use nucleo_matcher::Utf32Str;
use nucleo_matcher::pattern::CaseMatching;
use nucleo_matcher::pattern::Normalization;
use nucleo_matcher::pattern::Pattern;

use crate::desktop_entry;
use crate::desktop_entry::App;

/// Results shown at once; the list scrolls to keep the selection among them.
pub const VISIBLE: usize = 8;
/// Apps' icons, in logical pixels. They're rendered at twice this, for HiDPI displays.
pub const ICON_SIZE: f32 = 28.;

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
    /// Whether `apps` has been scanned yet.
    pub scanned: bool,
    pub query: String,
    /// Byte offsets into the query: the cursor, and the other end of the selection.
    pub cursor: usize,
    anchor: usize,
    /// Indices into `apps`, best first.
    results: Vec<usize>,
    pub selected: usize,
    /// The first result shown.
    pub scroll: usize,
    matcher: Matcher,
    _scan: Option<Task<()>>,
}

impl Launcher {
    pub fn new() -> Self {
        Self {
            apps: Arc::default(),
            scanned: false,
            query: String::new(),
            cursor: 0,
            anchor: 0,
            results: Vec::new(),
            selected: 0,
            scroll: 0,
            matcher: Matcher::new(Config::DEFAULT),
            _scan: None,
        }
    }

    /// Starts afresh, showing the last scan's apps until a new one finishes. Apps are shown as
    /// soon as they're found, then again once any new icons are rendered.
    pub fn open(&mut self, cx: &mut Context<Self>) {
        self.query.clear();
        (self.cursor, self.anchor) = (0, 0);
        self.search();
        let previous = self.apps.clone();
        let executor = cx.background_executor().clone();
        self._scan = Some(cx.spawn(async move |this, cx| {
            let mut apps = executor
                .spawn(async move { desktop_entry::scan(&previous) })
                .await;
            let set = |apps: &Vec<App>, cx: &mut gpui::AsyncApp| {
                let apps = Arc::new(apps.clone());
                this.update(cx, |this, cx| {
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
        }));
        cx.notify();
    }

    /// Re-runs the search over new apps, keeping the selection if it's still a result.
    fn refresh(&mut self) {
        let selected = self.selected_app().map(|app| app.id.clone());
        self.search();
        if let Some(index) = selected.and_then(|id| self.results().position(|app| app.id == id)) {
            self.set_selected(index);
        }
    }

    pub fn results(&self) -> impl Iterator<Item = &App> {
        self.results.iter().map(|&index| &self.apps[index])
    }

    pub fn result_count(&self) -> usize {
        self.results.len()
    }

    pub fn selected_app(&self) -> Option<&App> {
        self.results().nth(self.selected)
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
        self.search();
        cx.notify();
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

    /// Names match above descriptions and keywords. With no query, everything is listed by name.
    /// A few hundred short strings, so this is fast enough for every keystroke.
    fn search(&mut self) {
        self.scroll = 0;
        self.selected = 0;
        if self.query.trim().is_empty() {
            self.results = (0..self.apps.len()).collect();
            return;
        }
        let pattern = Pattern::parse(&self.query, CaseMatching::Smart, Normalization::Smart);
        let mut buffer = Vec::new();
        let mut scored: Vec<(u32, usize)> = (self.apps.iter().enumerate())
            .filter_map(|(index, app)| {
                let mut score =
                    |text: &str| pattern.score(Utf32Str::new(text, &mut buffer), &mut self.matcher);
                let name = score(&app.name).map(|score| score * 2);
                let extra = score(&app.extra);
                Some((name.max(extra)?, index))
            })
            .collect();
        // Stable, so equal scores stay in name order.
        scored.sort_by_key(|&(score, _)| std::cmp::Reverse(score));
        self.results = scored.into_iter().map(|(_, index)| index).collect();
    }
}

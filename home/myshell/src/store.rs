//! Notification history and persisted values in SQLite. Every call is a short indexed query;
//! callers keep them off the UI thread.

use std::cmp::Reverse;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::Mutex;

use diesel::connection::SimpleConnection;
use diesel::prelude::*;
use diesel_migrations::EmbeddedMigrations;
use diesel_migrations::MigrationHarness;
use diesel_migrations::embed_migrations;

use crate::data_source::Result;

// History is disposable, so there is only ever one migration: edit it in place (bumping its
// version), rather than adding more. A database with any other schema is deleted and recreated.
const MIGRATIONS: EmbeddedMigrations = embed_migrations!();

diesel::table! {
    notifications (id) {
        id -> Integer,
        app_name -> Text,
        app_icon -> Text,
        summary -> Text,
        body -> Text,
        default_action -> Nullable<Text>,
        received_at -> BigInt,
        read_at -> Nullable<BigInt>,
        icon -> Nullable<Text>,
    }
}

diesel::table! {
    persisted (key) {
        key -> Text,
        value -> Text,
    }
}

#[derive(Queryable, Selectable, Clone, Debug, PartialEq, Eq)]
#[diesel(table_name = notifications, check_for_backend(diesel::sqlite::Sqlite))]
pub struct Notification {
    pub id: i32,
    pub app_name: String,
    pub app_icon: String,
    pub summary: String,
    pub body: String,
    pub default_action: Option<String>,
    /// Unix milliseconds.
    pub received_at: i64,
    pub read_at: Option<i64>,
    /// A resolved image file, if any.
    pub icon: Option<String>,
}

/// A notification's place in the dropdown: unread first, then newest first.
pub type Key = (bool, Reverse<i64>, Reverse<i32>);

impl Notification {
    pub fn is_read(&self) -> bool {
        self.read_at.is_some()
    }

    pub fn key(&self) -> Key {
        (self.is_read(), Reverse(self.received_at), Reverse(self.id))
    }
}

#[derive(Insertable, AsChangeset)]
#[diesel(table_name = notifications, treat_none_as_null = true)]
pub struct NewNotification {
    pub app_name: String,
    pub app_icon: String,
    pub summary: String,
    pub body: String,
    pub default_action: Option<String>,
    pub received_at: i64,
    /// Always None: new and replaced notifications are unread.
    pub read_at: Option<i64>,
    pub icon: Option<String>,
}

pub struct Store(Mutex<SqliteConnection>);

/// The store, and what the shell reads from it at startup. Opened in the background while the
/// shell waits for displays, so it's ready before the first frame.
pub struct Database {
    pub store: Option<Arc<Store>>,
    pub unread: usize,
    persisted: HashMap<String, serde_json::Value>,
}

impl Database {
    pub fn open() -> Self {
        let store = Store::open()
            .inspect_err(|error| eprintln!("database unavailable: {error}"))
            .ok();
        let (unread, persisted) = match &store {
            Some(store) => (
                read("unread count", store.unread_count()),
                read("persisted values", store.persisted()),
            ),
            None => Default::default(),
        };
        Self {
            store: store.map(Arc::new),
            unread,
            persisted,
        }
    }

    pub fn persisted(&self, key: &str) -> Option<&serde_json::Value> {
        self.persisted.get(key)
    }
}

fn read<T: Default>(what: &str, result: Result<T>) -> T {
    result
        .inspect_err(|error| eprintln!("reading {what}: {error}"))
        .unwrap_or_default()
}

impl Store {
    /// `$XDG_DATA_HOME/myshell/notifications.db`, created and migrated if needed.
    pub fn open() -> Result<Self> {
        let dir = std::env::var_os("XDG_DATA_HOME")
            .map(PathBuf::from)
            .or_else(|| std::env::home_dir().map(|home| home.join(".local/share")))
            .ok_or("no data directory")?
            .join("myshell");
        std::fs::create_dir_all(&dir)?;
        let path = dir.join("notifications.db");
        let path = path.to_str().ok_or("non-UTF-8 data directory")?;
        let connection = match Self::connect(path) {
            Ok(connection) => connection,
            Err(error) => {
                eprintln!("recreating notification history ({error})");
                for suffix in ["", "-wal", "-shm"] {
                    let _ = std::fs::remove_file(format!("{path}{suffix}"));
                }
                Self::connect(path)?
            }
        };
        Ok(Self(Mutex::new(connection)))
    }

    /// Fails if the database has any schema other than the current one.
    fn connect(path: &str) -> Result<SqliteConnection> {
        let mut connection = SqliteConnection::establish(path)?;
        // WAL keeps writes cheap; NORMAL is durable across application crashes.
        connection.batch_execute("PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;")?;
        let current: Vec<String> =
            (diesel::migration::MigrationSource::<diesel::sqlite::Sqlite>::migrations(
                &MIGRATIONS,
            )?)
            .iter()
            .map(|migration| migration.name().version().to_string())
            .collect();
        let applied: Vec<String> = (connection.applied_migrations()?.iter())
            .map(ToString::to_string)
            .collect();
        if !applied.is_empty() && applied != current {
            return Err(format!("schema {applied:?} isn't {current:?}").into());
        }
        connection.run_pending_migrations(MIGRATIONS)?;
        Ok(connection)
    }

    fn connection(&self) -> std::sync::MutexGuard<'_, SqliteConnection> {
        // A panic mid-query can't leave SQLite inconsistent, so poisoning is irrelevant.
        self.0
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    }

    pub fn insert(&self, new: &NewNotification) -> Result<Notification> {
        Ok(diesel::insert_into(notifications::table)
            .values(new)
            .returning(Notification::as_returning())
            .get_result(&mut *self.connection())?)
    }

    /// Replaces an existing notification's content, making it unread. Returns it, and whether it
    /// was read before.
    pub fn replace(&self, id: i32, new: &NewNotification) -> Result<Option<(Notification, bool)>> {
        let mut connection = self.connection();
        connection.transaction(|connection| {
            let was_read: Option<Option<i64>> = notifications::table
                .find(id)
                .select(notifications::read_at)
                .first(connection)
                .optional()?;
            let Some(was_read) = was_read else {
                return Ok(None);
            };
            let notification = diesel::update(notifications::table.find(id))
                .set(new)
                .returning(Notification::as_returning())
                .get_result(connection)?;
            Ok(Some((notification, was_read.is_some())))
        })
    }

    pub fn unread_count(&self) -> Result<usize> {
        let count: i64 = notifications::table
            .filter(notifications::read_at.is_null())
            .count()
            .get_result(&mut *self.connection())?;
        Ok(count as usize)
    }

    /// Up to `limit` notifications in the dropdown's order, after `after` (or from the start).
    pub fn page(&self, after: Option<Key>, limit: i64) -> Result<Vec<Notification>> {
        use self::notifications::dsl::id;
        use self::notifications::dsl::read_at;
        use self::notifications::dsl::received_at;
        let mut query = notifications::table
            .select(Notification::as_select())
            .order((read_at.is_not_null().asc(), received_at.desc(), id.desc()))
            .limit(limit)
            .into_boxed();
        if let Some((read, Reverse(received), Reverse(last_id))) = after {
            let older = received_at
                .lt(received)
                .or(received_at.eq(received).and(id.lt(last_id)));
            query = if read {
                query.filter(read_at.is_not_null().and(older))
            } else {
                query.filter(read_at.is_not_null().or(older))
            };
        }
        Ok(query.load(&mut *self.connection())?)
    }

    /// Returns whether it was unread.
    pub fn mark_read(&self, id: i32, at: i64) -> Result<bool> {
        let changed = diesel::update(
            notifications::table
                .find(id)
                .filter(notifications::read_at.is_null()),
        )
        .set(notifications::read_at.eq(at))
        .execute(&mut *self.connection())?;
        Ok(changed > 0)
    }

    pub fn mark_all_read(&self, at: i64) -> Result<()> {
        diesel::update(notifications::table.filter(notifications::read_at.is_null()))
            .set(notifications::read_at.eq(at))
            .execute(&mut *self.connection())?;
        Ok(())
    }

    fn persisted(&self) -> Result<HashMap<String, serde_json::Value>> {
        let rows: Vec<(String, String)> = persisted::table.load(&mut *self.connection())?;
        (rows.into_iter())
            .map(|(key, value)| Ok((key, serde_json::from_str(&value)?)))
            .collect()
    }

    pub fn set(&self, key: &str, value: &serde_json::Value) -> Result<()> {
        diesel::replace_into(persisted::table)
            .values((
                persisted::key.eq(key),
                persisted::value.eq(value.to_string()),
            ))
            .execute(&mut *self.connection())?;
        Ok(())
    }
}

pub fn now() -> i64 {
    jiff::Timestamp::now().as_millisecond()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pages_follow_the_dropdown_order_across_read_states() {
        let directory = std::env::temp_dir().join(format!("myshell-test-{}", std::process::id()));
        // SAFETY: no other test reads XDG_DATA_HOME.
        unsafe { std::env::set_var("XDG_DATA_HOME", &directory) };
        let store = Store::open().unwrap();
        for index in 0..7 {
            let new = NewNotification {
                app_name: "app".into(),
                app_icon: String::new(),
                summary: index.to_string(),
                body: String::new(),
                default_action: None,
                received_at: index,
                read_at: None,
                icon: None,
            };
            store.insert(&new).unwrap();
        }
        // Read: 1, 4, 5. Unread: 0, 2, 3, 6.
        for id in [2, 5, 6] {
            assert!(store.mark_read(id, 100).unwrap());
        }
        assert!(!store.mark_read(2, 100).unwrap());
        assert_eq!(store.unread_count().unwrap(), 4);
        let mut seen = Vec::new();
        let mut after = None;
        loop {
            let page = store.page(after, 2).unwrap();
            let Some(last) = page.last() else { break };
            after = Some(last.key());
            seen.extend(page.iter().map(|notification| notification.summary.clone()));
        }
        assert_eq!(seen, ["6", "3", "2", "0", "5", "4", "1"]);
        let _ = std::fs::remove_dir_all(directory);
    }
}

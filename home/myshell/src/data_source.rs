//! Sources own their scheduling: subscribers await updates, never poll for them.
//! A source may use a timer when its underlying data requires one (e.g. the clock).

pub mod battery;
pub mod brightness;
pub mod clock;
pub mod power_profile;
pub mod system;
pub mod tray;
pub mod volume;

use std::future::Future;

use futures::SinkExt;
use futures::Stream;
use futures::StreamExt;
use futures::channel::mpsc;
use gpui::Context;
use gpui::Task;
use zbus::fdo::PropertiesProxy;
use zbus::proxy::CacheProperties;

use crate::store::Database;

pub type Error = Box<dyn std::error::Error + Send + Sync>;
pub type Result<T> = std::result::Result<T, Error>;

pub trait DataSource: Send + 'static {
    type Value: Clone + PartialEq + Send + 'static;

    /// Caches availability under this key, so it's known immediately at the next startup.
    const PERSISTENCE_KEY: Option<&str> = None;

    /// Checked once at startup, before streaming. An unavailable source's module is hidden.
    fn is_available() -> impl Future<Output = bool> + Send {
        async { true }
    }

    /// Emit the initial value, then updates. Errors may be recoverable; keep reading until EOF.
    /// Dropping the stream releases its resources.
    fn stream(self) -> impl Stream<Item = Result<Self::Value>> + Send + 'static;

    /// Merge observed metadata into a pending target. Return false if the target belongs
    /// to a different resource (e.g. an audio output that is no longer the default).
    fn reconcile_target(_target: &mut Self::Value, _known: &Self::Value) -> bool {
        true
    }
}

/// Subscribes before the caller's first read. Yields once immediately, then whenever one of
/// `names` changes or the system service (re)appears, and an error while it is absent.
pub async fn watch_properties(
    destination: &'static str,
    path: &'static str,
    interface: &'static str,
    names: &'static [&'static str],
) -> Result<(
    PropertiesProxy<'static>,
    impl Stream<Item = Result<()>> + Send + 'static,
)> {
    let connection = zbus::Connection::system().await?;
    let properties = PropertiesProxy::builder(&connection)
        .destination(destination)?
        .path(path)?
        .cache_properties(CacheProperties::No)
        .build()
        .await?;
    let changes = properties.receive_properties_changed().await?;
    let owners = properties.inner().receive_owner_changed().await?;
    let changes = changes.filter_map(move |signal| {
        let relevant = signal.args().map(|args| {
            args.interface_name().as_str() == interface
                && names.iter().any(|name| {
                    args.changed_properties().contains_key(name)
                        || args.invalidated_properties().contains(name)
                })
        });
        futures::future::ready(match relevant {
            Ok(true) => Some(Ok(())),
            Ok(false) => None,
            Err(error) => Some(Err(error.into())),
        })
    });
    let owners = owners.map(move |owner| {
        owner.map(|_| ()).ok_or_else(|| {
            std::io::Error::new(
                std::io::ErrorKind::NotConnected,
                format!("{destination} unavailable"),
            )
            .into()
        })
    });
    let updates = futures::stream::iter([Ok(())]).chain(futures::stream::select(changes, owners));
    Ok((properties, updates))
}

/// The optimistic target and most recently observed source value.
pub struct State<T> {
    pub target: Option<T>,
    pub known: Option<T>,
    revision: u64,
    pending: Option<u64>,
    applied: bool,
}

impl<T> Default for State<T> {
    fn default() -> Self {
        Self {
            target: None,
            known: None,
            revision: 0,
            pending: None,
            applied: false,
        }
    }
}

impl<T: Clone + PartialEq> State<T> {
    /// Equality alone does not imply that a queued write has finished.
    pub fn is_confirmed(&self) -> bool {
        self.target == self.known
    }

    fn request(&mut self, target: T) -> u64 {
        self.revision = self
            .revision
            .checked_add(1)
            .expect("write revision overflow");
        self.pending = Some(self.revision);
        self.applied = false;
        self.target = Some(target);
        self.revision
    }

    fn observe(&mut self, known: Option<T>) -> bool {
        let changed = self.known != known;
        self.known = known;
        if self.pending.is_none() {
            let target_changed = self.target != self.known;
            self.target = self.known.clone();
            return changed || target_changed;
        }
        self.confirm();
        changed
    }

    fn confirm(&mut self) {
        // An intermediate observation may match a later queued target (A -> B -> A).
        // Only release that target once its own write has completed successfully.
        if self.applied && self.is_confirmed() {
            self.pending = None;
            self.applied = false;
        }
    }

    /// Returns false for stale completions, which must not affect state or errors.
    fn complete(&mut self, revision: u64, succeeded: bool) -> bool {
        if self.pending != Some(revision) {
            return false;
        }
        if succeeded {
            self.applied = true;
            self.confirm();
        } else {
            self.target = self.known.clone();
            self.pending = None;
            self.applied = false;
        }
        true
    }
}

/// Sources always run in the background. Only state application and notifications run on the UI.
/// Retaining the tasks ties subscriptions and queued writes to the entity's lifetime.
pub struct Data<S: DataSource> {
    pub state: State<S::Value>,
    pub error: Option<String>,
    /// Until checked: the persisted availability, if any, else true.
    pub available: bool,
    _task: Task<()>,
    write_task: Option<Task<()>>,
}

impl<S: DataSource> Data<S> {
    pub fn new(source: S, database: &Database, cx: &mut Context<Self>) -> Self {
        let persisted = (S::PERSISTENCE_KEY)
            .and_then(|key| database.persisted(key))
            .and_then(|value| value.as_bool());
        let store = database.store.clone();
        let executor = cx.background_executor().clone();
        let task = cx.spawn(async move |this, cx| {
            let available = executor
                .spawn(async move {
                    let available = S::is_available().await;
                    if let Some((key, store)) = S::PERSISTENCE_KEY.zip(store)
                        && persisted != Some(available)
                        && let Err(error) = store.set(key, &available.into())
                    {
                        eprintln!("persisting {key}: {error}");
                    }
                    available
                })
                .await;
            let updated = this.update(cx, |this, cx| {
                if this.available != available {
                    this.available = available;
                    cx.notify();
                }
            });
            if updated.is_err() || !available {
                return;
            }
            // Bounded delivery provides backpressure if the UI can't keep up.
            let (mut sender, mut updates) = mpsc::channel(1);
            // Dropping the UI subscription also cancels the producer and its resources.
            let _producer = executor.spawn(async move {
                let stream = source.stream();
                futures::pin_mut!(stream);
                while let Some(update) = stream.next().await {
                    if let Err(error) = &update {
                        eprintln!("{}: {error}", std::any::type_name::<S>());
                    }
                    if sender.send(update).await.is_err() {
                        break;
                    }
                }
            });
            while let Some(update) = updates.next().await {
                if this
                    .update(cx, |this, cx| {
                        let (known, error) = match update {
                            Ok(value) => (Some(value), None),
                            Err(error) => (None, Some(error.to_string())),
                        };
                        let invalidated =
                            this.state.pending.is_some()
                                && this.state.target.as_mut().zip(known.as_ref()).is_some_and(
                                    |(target, known)| !S::reconcile_target(target, known),
                                );
                        if invalidated {
                            this.state.pending = None;
                            this.state.applied = false;
                        }
                        let changed =
                            this.state.observe(known) || invalidated || this.error != error;
                        this.error = error;
                        if changed {
                            cx.notify();
                        }
                    })
                    .is_err()
                {
                    break;
                }
            }
        });
        Self {
            state: State::default(),
            error: None,
            available: persisted.unwrap_or(true),
            _task: task,
            write_task: None,
        }
    }

    /// Immediately updates the target, then executes writes in request order off the UI thread.
    pub fn request(
        &mut self,
        target: S::Value,
        write: impl Future<Output = Result<()>> + Send + 'static,
        cx: &mut Context<Self>,
    ) {
        let revision = self.state.request(target);
        self.error = None;
        cx.notify();

        let previous = self.write_task.take();
        let executor = cx.background_executor().clone();
        self.write_task = Some(cx.spawn(async move |this, cx| {
            if let Some(previous) = previous {
                previous.await;
            }
            let result = executor
                .spawn(async move {
                    write.await.map_err(|error| {
                        eprintln!("{}: {error}", std::any::type_name::<S>());
                        error.to_string()
                    })
                })
                .await;
            let _ = this.update(cx, |this, cx| {
                if this.state.complete(revision, result.is_ok()) {
                    this.error = result.err();
                    cx.notify();
                }
            });
        }));
    }
}

#[cfg(test)]
mod tests {
    use super::State;

    #[test]
    fn follows_external_changes_when_idle() {
        let mut state = State::default();
        assert!(state.is_confirmed());
        assert!(state.observe(Some('A')));
        assert_eq!(state.target, Some('A'));
        assert!(!state.observe(Some('A')));
        state.observe(Some('B'));
        assert_eq!(state.target, Some('B'));
        state.observe(None);
        assert_eq!(state.target, None);
        assert!(state.is_confirmed());
    }

    #[test]
    fn waits_for_both_write_and_observation() {
        let mut state = State::default();
        state.observe(Some('A'));
        let revision = state.request('B');
        state.observe(Some('B'));
        assert!(state.is_confirmed());
        state.observe(Some('C'));
        assert_eq!(state.target, Some('B'));
        assert!(state.complete(revision, true));
        state.observe(Some('D'));
        assert_eq!(state.target, Some('B'));
        state.observe(Some('B'));
        state.observe(Some('C'));
        assert_eq!(state.target, Some('C'));
    }

    #[test]
    fn matching_observation_before_success_releases_target_on_completion() {
        let mut state = State::default();
        let revision = state.request('B');
        state.observe(Some('B'));
        assert!(state.complete(revision, true));
        state.observe(Some('C'));
        assert_eq!(state.target, Some('C'));
    }

    #[test]
    fn queued_a_b_a_ignores_intermediate_confirmation_and_stale_completions() {
        let mut state = State::default();
        state.observe(Some('A'));
        let a = state.request('A');
        let b = state.request('B');
        let final_a = state.request('A');
        assert_eq!(state.target, Some('A'));
        assert!(!state.complete(a, true));
        state.observe(Some('A'));
        assert!(!state.complete(b, false));
        state.observe(Some('B'));
        assert_eq!(state.target, Some('A'));
        state.observe(Some('A'));
        state.observe(Some('B'));
        assert_eq!(state.target, Some('A'));
        assert!(state.complete(final_a, true));
        state.observe(Some('A'));
        state.observe(Some('C'));
        assert_eq!(state.target, Some('C'));
        assert!(!state.complete(b, false));
    }

    #[test]
    fn failure_rolls_back_to_latest_known_and_resumes_following() {
        let mut state = State::default();
        state.observe(Some('A'));
        let revision = state.request('B');
        state.observe(Some('C'));
        assert!(state.complete(revision, false));
        assert_eq!(state.target, Some('C'));
        state.observe(Some('D'));
        assert_eq!(state.target, Some('D'));
    }

    #[test]
    fn source_error_preserves_pending_target_and_rollback_can_be_unknown() {
        let mut state = State::default();
        state.observe(Some('A'));
        let revision = state.request('B');
        state.observe(None);
        assert_eq!(state.known, None);
        assert_eq!(state.target, Some('B'));
        assert!(state.complete(revision, false));
        assert_eq!(state.target, None);
        state.observe(Some('C'));
        assert_eq!(state.target, Some('C'));
    }
}

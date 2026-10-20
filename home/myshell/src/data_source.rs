//! Sources own their scheduling: subscribers await updates, never poll for them.
//! A source may use a timer when its underlying data requires one (e.g. the clock).

pub mod clock;
pub mod power_profile;
pub mod volume;

use futures::Stream;
use futures::StreamExt;
use gpui::Context;
use gpui::Task;

pub type Error = Box<dyn std::error::Error + Send + Sync>;
pub type Result<T> = std::result::Result<T, Error>;

pub trait DataSource: Send + 'static {
    type Value: PartialEq + Send + 'static;

    /// Emit the initial value, then updates. Errors may be recoverable; keep reading until EOF.
    /// Dropping the stream releases its resources.
    fn stream(self) -> impl Stream<Item = Result<Self::Value>> + Send + 'static;
}

/// A shared GPUI binding. Retaining the task ties the subscription to the entity's lifetime.
pub struct Data<S: DataSource> {
    pub value: Option<S::Value>,
    pub error: Option<String>,
    _task: Task<()>,
}

impl<S: DataSource> Data<S> {
    pub fn new(source: S, cx: &mut Context<Self>) -> Self {
        let task = cx.spawn(async move |this, cx| {
            let updates = source.stream();
            futures::pin_mut!(updates);
            while let Some(update) = updates.next().await {
                if this
                    .update(cx, |this, cx| match update {
                        Ok(value) => {
                            if this.value.as_ref() != Some(&value) || this.error.is_some() {
                                this.value = Some(value);
                                this.error = None;
                                cx.notify();
                            }
                        }
                        Err(error) => {
                            let error = error.to_string();
                            if this.error.as_ref() != Some(&error) {
                                eprintln!("{}: {error}", std::any::type_name::<S>());
                                this.value = None;
                                this.error = Some(error);
                                cx.notify();
                            }
                        }
                    })
                    .is_err()
                {
                    break;
                }
            }
        });
        Self {
            value: None,
            error: None,
            _task: task,
        }
    }
}

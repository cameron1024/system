mod animated_icon;
mod bar;
mod bar_module;
mod battery_indicator;
mod command;
mod data_source;
mod profile_icon;
mod shell;
mod shortcuts;
mod theme;
mod tooltip;
mod volume_button;

use futures::StreamExt;
use futures::channel::mpsc;
use gpui::App;
use gpui::AppContext;

use crate::shell::Shell;

fn main() {
    gpui_platform::application()
        .with_quit_mode(gpui::QuitMode::Explicit)
        .run(|cx: &mut App| {
            let (sender, mut commands) = mpsc::unbounded();
            let shell = cx.new(Shell::new);
            cx.spawn(async move |cx| {
                // Wayland output announcements arrive after the application startup callback.
                // Wait only during startup; there is no ongoing display polling.
                let deadline = std::time::Instant::now() + std::time::Duration::from_secs(3);
                while cx.update(|cx| cx.displays().is_empty()) {
                    assert!(
                        std::time::Instant::now() < deadline,
                        "no Wayland outputs discovered"
                    );
                    async_io::Timer::after(std::time::Duration::from_millis(10)).await;
                }
                shell.update(cx, |shell, cx| shell.show_bars(cx));
                // Retain the connection and shell for the entire application lifetime.
                let _connection = match shortcuts::listen(sender).await {
                    Ok(connection) => Some(connection),
                    Err(error) => {
                        eprintln!("global shortcuts unavailable: {error}");
                        None
                    }
                };
                while let Some(command) = commands.next().await {
                    shell.update(cx, |shell, cx| shell.command(command, cx));
                }
            })
            .detach();
        });
}

//! The system tray: a StatusNotifierItem host, with menus over DBusMenu. It also serves the
//! watcher (the registry items register with), queued behind any other (e.g. another bar's) and
//! taking over if that one exits. Items announce changes with signals, and are then re-read.

use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use std::sync::OnceLock;

use futures::FutureExt;
use futures::Stream;
use futures::StreamExt;
use futures::stream::AbortHandle;
use futures::stream::BoxStream;
use futures::stream::SelectAll;
use gpui::RenderImage;
use gpui::SharedString;
use zbus::Connection;
use zbus::fdo::PropertiesProxy;
use zbus::fdo::RequestNameFlags;
use zbus::message::Header;
use zbus::object_server::SignalEmitter;
use zbus::proxy::CacheProperties;
use zbus::zvariant::OwnedValue;
use zbus::zvariant::Value;

use super::DataSource;
use super::Result;
use crate::icon_theme;
use crate::theme;

const WATCHER: &str = "org.kde.StatusNotifierWatcher";
const WATCHER_PATH: &str = "/StatusNotifierWatcher";
const ITEM: &str = "org.kde.StatusNotifierItem";
const MENU: &str = "com.canonical.dbusmenu";

/// For actions; set once the tray is connected.
static CONNECTION: OnceLock<Connection> = OnceLock::new();

pub struct Tray;

#[derive(Clone, PartialEq)]
pub struct TrayItem {
    /// Its bus name and object path, e.g. ":1.94/StatusNotifierItem".
    pub key: String,
    /// The app's own identifier for it, e.g. "blueman".
    pub id: String,
    pub title: String,
    /// The tooltip's title, which some apps use for state (e.g. Slack's unread messages).
    pub tooltip: String,
    pub icon: Option<TrayIcon>,
    pub attention: bool,
    /// Clicking activates it (e.g. raising a window), rather than opening its menu.
    pub activates: bool,
    pub menu: Vec<MenuEntry>,
    menu_path: Option<String>,
}

#[derive(Clone, PartialEq)]
pub enum TrayIcon {
    /// Painted in a single colour, like the bar's own icons.
    Svg(SharedString),
    /// A raster icon's silhouette, in the tray's colour.
    Raster(Arc<RenderImage>),
}

#[derive(Clone, PartialEq)]
pub struct MenuEntry {
    pub id: i32,
    pub label: String,
    pub enabled: bool,
    pub kind: EntryKind,
    /// A submenu.
    pub children: Vec<MenuEntry>,
}

#[derive(Clone, Copy, PartialEq)]
pub enum EntryKind {
    Item,
    Separator,
    Check(bool),
    Radio(bool),
}

impl DataSource for Tray {
    type Value = Vec<TrayItem>;

    fn stream(self) -> impl Stream<Item = Result<Vec<TrayItem>>> + Send + 'static {
        async_stream::stream! {
            let (connection, mut events) = match connect().await {
                Ok(connected) => connected,
                Err(error) => {
                    yield Err(error);
                    return;
                }
            };
            let host = format!("org.kde.StatusNotifierHost-{}", std::process::id());
            let mut items: Vec<TrayItem> = Vec::new();
            let mut tracked: HashMap<String, AbortHandle> = HashMap::new();
            yield Ok(Vec::new());
            while let Some(event) = events.next().await {
                let changed = match event {
                    Event::WatcherChanged => {
                        // Items re-register with a new watcher, so existing ones are kept.
                        match sync_watcher(&connection, &host).await {
                            Ok(keys) => {
                                for key in keys {
                                    track(&connection, key, &mut events, &mut tracked);
                                }
                            }
                            Err(error) => eprintln!("tray watcher: {error}"),
                        }
                        false
                    }
                    Event::Registered(key) => {
                        track(&connection, key, &mut events, &mut tracked);
                        false
                    }
                    Event::Unregistered(key) => untrack(|tracked| tracked == key, &mut items, &mut tracked),
                    Event::Vanished(name) => {
                        forget(&connection, &name).await;
                        untrack(|key| split_key(key).0 == name, &mut items, &mut tracked)
                    }
                    Event::Item(key, item) => {
                        let index = items.iter().position(|item| item.key == key);
                        match (index, item) {
                            (Some(index), Some(item)) => items[index] = item,
                            (None, Some(item)) if tracked.contains_key(&key) => items.push(item),
                            (Some(index), None) => drop(items.remove(index)),
                            (None, _) => {}
                        }
                        true
                    }
                };
                if changed {
                    yield Ok(items.clone());
                }
            }
            yield Err(std::io::Error::new(
                std::io::ErrorKind::BrokenPipe,
                "tray signal stream closed",
            )
            .into());
        }
    }
}

enum Event {
    /// The watcher (ours or another's) appeared or went.
    WatcherChanged,
    Registered(String),
    Unregistered(String),
    /// A bus name went away, with any items it had.
    Vanished(String),
    /// None if it's hidden (passive) or unreadable.
    Item(String, Option<TrayItem>),
}

/// Serves our watcher, queued for the name, and subscribes to the watcher's and the bus's signals.
async fn connect() -> Result<(Connection, SelectAll<BoxStream<'static, Event>>)> {
    let connection = zbus::connection::Builder::session()?
        .serve_at(WATCHER_PATH, Watcher::default())?
        .build()
        .await?;
    let _ = CONNECTION.set(connection.clone());
    let watcher = zbus::proxy::Builder::<zbus::Proxy>::new(&connection)
        .destination(WATCHER)?
        .path(WATCHER_PATH)?
        .interface(WATCHER)?
        .cache_properties(CacheProperties::No)
        .build()
        .await?;
    let registered = watcher
        .receive_signal("StatusNotifierItemRegistered")
        .await?;
    let unregistered = watcher
        .receive_signal("StatusNotifierItemUnregistered")
        .await?;
    let owner = watcher.receive_owner_changed().await?;
    let names = zbus::fdo::DBusProxy::new(&connection)
        .await?
        .receive_name_owner_changed()
        .await?;
    // Not exclusive: without another watcher this is ours at once, else once that one exits.
    connection
        .request_name_with_flags(WATCHER, RequestNameFlags::AllowReplacement.into())
        .await?;
    let service = |message: zbus::Message| message.body().deserialize::<String>().ok();
    let mut events = SelectAll::new();
    events.push(futures::stream::once(async { Event::WatcherChanged }).boxed());
    events.push(owner.map(|_| Event::WatcherChanged).boxed());
    events.push(
        (registered.filter_map(move |message| async move { service(message) }))
            .map(Event::Registered)
            .boxed(),
    );
    events.push(
        (unregistered.filter_map(move |message| async move { service(message) }))
            .map(Event::Unregistered)
            .boxed(),
    );
    events.push(
        names
            .filter_map(|signal| async move {
                let args = signal.args().ok()?;
                args.new_owner()
                    .is_none()
                    .then(|| Event::Vanished(args.name().to_string()))
            })
            .boxed(),
    );
    Ok((connection, events))
}

/// Registers as a host, returning the watcher's items.
async fn sync_watcher(connection: &Connection, host: &str) -> Result<Vec<String>> {
    connection.request_name(host).await?;
    connection
        .call_method(
            Some(WATCHER),
            WATCHER_PATH,
            Some(WATCHER),
            "RegisterStatusNotifierHost",
            &host,
        )
        .await?;
    let properties = PropertiesProxy::builder(connection)
        .destination(WATCHER)?
        .path(WATCHER_PATH)?
        .cache_properties(CacheProperties::No)
        .build()
        .await?;
    let items = properties
        .get(WATCHER.try_into()?, "RegisteredStatusNotifierItems")
        .await?;
    Ok(Vec::try_from(items)?)
}

/// Starts (or restarts) reading an item.
fn track(
    connection: &Connection,
    key: String,
    events: &mut SelectAll<BoxStream<'static, Event>>,
    tracked: &mut HashMap<String, AbortHandle>,
) {
    let (stream, handle) = futures::stream::abortable(item_events(connection.clone(), key.clone()));
    if let Some(previous) = tracked.insert(key, handle) {
        previous.abort();
    }
    events.push(stream.boxed());
}

/// Returns whether any shown item was removed.
fn untrack(
    matches: impl Fn(&str) -> bool,
    items: &mut Vec<TrayItem>,
    tracked: &mut HashMap<String, AbortHandle>,
) -> bool {
    tracked.retain(|key, handle| {
        let keep = !matches(key);
        if !keep {
            handle.abort();
        }
        keep
    });
    let count = items.len();
    items.retain(|item| !matches(&item.key));
    items.len() != count
}

/// Removes a vanished name's items and host from our watcher (if it's ours).
async fn forget(connection: &Connection, name: &str) {
    let Ok(watcher) = (connection.object_server())
        .interface::<_, Watcher>(WATCHER_PATH)
        .await
    else {
        return;
    };
    let mut state = watcher.get_mut().await;
    state.hosts.retain(|host| host != name);
    let (gone, kept) = (state.items.drain(..)).partition(|key| split_key(key).0 == name);
    state.items = kept;
    for key in gone {
        let _ = Watcher::status_notifier_item_unregistered(watcher.signal_emitter(), &key).await;
    }
}

/// e.g. (":1.94", "/StatusNotifierItem").
fn split_key(key: &str) -> (&str, &str) {
    key.find('/')
        .map_or((key, "/StatusNotifierItem"), |at| key.split_at(at))
}

/// The item's state, then again (coalesced) after each of its or its menu's signals.
fn item_events(connection: Connection, key: String) -> BoxStream<'static, Event> {
    async_stream::stream! {
        let (reader, signals) = match ItemReader::new(&connection, &key).await {
            Ok(watched) => watched,
            Err(error) => {
                eprintln!("tray item {key}: {error}");
                yield Event::Item(key, None);
                return;
            }
        };
        futures::pin_mut!(signals);
        let mut icon = None;
        loop {
            let item = reader.read(&mut icon).await.unwrap_or_else(|error| {
                eprintln!("tray item {key}: {error}");
                None
            });
            yield Event::Item(key.clone(), item);
            if signals.next().await.is_none() {
                break;
            }
            while let Some(Some(())) = signals.next().now_or_never() {}
        }
    }
    .boxed()
}

struct ItemReader {
    key: String,
    properties: PropertiesProxy<'static>,
    menu: Option<zbus::Proxy<'static>>,
    activates: bool,
}

/// What an icon was resolved from, so it's only resolved again when that changes.
type IconSource = (String, String, Vec<(i32, i32, Vec<u8>)>);

impl ItemReader {
    async fn new(
        connection: &Connection,
        key: &str,
    ) -> Result<(Self, impl Stream<Item = ()> + use<>)> {
        let (service, path) = split_key(key);
        let item = zbus::proxy::Builder::<zbus::Proxy>::new(connection)
            .destination(service.to_owned())?
            .path(path.to_owned())?
            .interface(ITEM)?
            .cache_properties(CacheProperties::No)
            .build()
            .await?;
        let signals = item.receive_all_signals().await?;
        let properties = PropertiesProxy::builder(connection)
            .destination(service.to_owned())?
            .path(path.to_owned())?
            .cache_properties(CacheProperties::No)
            .build()
            .await?;
        // e.g. Ayatana's items have no Activate; clicking them should open their menu. Some
        // (e.g. Chromium's) don't describe their interface at all, so are assumed to have it.
        let activates = (item.introspect().await)
            .is_ok_and(|xml| !xml.contains(ITEM) || xml.contains("\"Activate\""));
        let menu_path = (properties.get(ITEM.try_into()?, "Menu").await.ok())
            .and_then(|path| zbus::zvariant::OwnedObjectPath::try_from(path).ok())
            .filter(|path| path.as_str() != "/");
        let (menu, menu_signals) = match menu_path {
            Some(path) => {
                let menu = zbus::proxy::Builder::<zbus::Proxy>::new(connection)
                    .destination(service.to_owned())?
                    .path(path)?
                    .interface(MENU)?
                    .cache_properties(CacheProperties::No)
                    .build()
                    .await?;
                let signals = menu.receive_all_signals().await?;
                (Some(menu), Some(signals))
            }
            None => (None, None),
        };
        let signals = futures::stream::select(
            signals.map(drop),
            futures::stream::iter(menu_signals).flatten().map(drop),
        );
        let reader = Self {
            key: key.to_owned(),
            properties,
            menu,
            activates,
        };
        Ok((reader, signals))
    }

    async fn read(
        &self,
        icon: &mut Option<(IconSource, Option<TrayIcon>)>,
    ) -> Result<Option<TrayItem>> {
        let mut all = self.properties.get_all(ITEM.try_into()?).await?;
        let mut string = |name: &str| {
            (all.remove(name))
                .and_then(|value| String::try_from(value).ok())
                .unwrap_or_default()
        };
        let status = string("Status");
        if status == "Passive" {
            return Ok(None);
        }
        let attention = status == "NeedsAttention";
        let (id, title) = (string("Id"), string("Title"));
        let attention_name = string("AttentionIconName");
        let name = string("IconName");
        let theme_path = string("IconThemePath");
        let pixmaps = |value: Option<_>| -> Vec<(i32, i32, Vec<u8>)> {
            value
                .and_then(|value| Vec::try_from(value).ok())
                .unwrap_or_default()
        };
        let attention_pixmaps = pixmaps(all.remove("AttentionIconPixmap"));
        let source = if attention && (!attention_name.is_empty() || !attention_pixmaps.is_empty()) {
            (attention_name, theme_path, attention_pixmaps)
        } else {
            (name, theme_path, pixmaps(all.remove("IconPixmap")))
        };
        if icon
            .as_ref()
            .is_none_or(|(previous, _)| *previous != source)
        {
            let resolved = resolve_icon(&source);
            *icon = Some((source, resolved));
        }
        let tooltip = (all.remove("ToolTip"))
            .and_then(|value| {
                <(String, Vec<(i32, i32, Vec<u8>)>, String, String)>::try_from(value).ok()
            })
            .map(|(_, _, title, _)| title)
            .unwrap_or_default();
        let title = [&title, &tooltip, &id]
            .into_iter()
            .find(|title| !title.is_empty())
            .cloned()
            .unwrap_or_default();
        let menu = match &self.menu {
            Some(menu) => read_menu(menu).await.unwrap_or_else(|error| {
                eprintln!("tray menu {}: {error}", self.key);
                Vec::new()
            }),
            None => Vec::new(),
        };
        Ok(Some(TrayItem {
            key: self.key.clone(),
            id,
            title,
            tooltip,
            icon: icon.as_ref().and_then(|(_, icon)| icon.clone()),
            attention,
            activates: self.activates,
            menu,
            menu_path: self.menu.as_ref().map(|menu| menu.path().to_string()),
        }))
    }
}

async fn read_menu(menu: &zbus::Proxy<'_>) -> Result<Vec<MenuEntry>> {
    let reply = menu
        .call_method("GetLayout", &(0i32, -1i32, Vec::<&str>::new()))
        .await?;
    type Layout = (i32, HashMap<String, OwnedValue>, Vec<OwnedValue>);
    let (_revision, (_, _, children)): (u32, Layout) = reply.body().deserialize()?;
    Ok(children.iter().filter_map(|child| entry(child)).collect())
}

/// A DBusMenu layout node, `(ia{sv}av)`; None if hidden.
fn entry(value: &Value) -> Option<MenuEntry> {
    let value = match value {
        Value::Value(inner) => inner,
        value => value,
    };
    let Value::Structure(structure) = value else {
        return None;
    };
    let [id, Value::Dict(properties), Value::Array(children)] = structure.fields() else {
        return None;
    };
    let get = |name: &str| {
        properties
            .iter()
            .find_map(|(key, value)| match (key, value) {
                (Value::Str(key), Value::Value(value)) if key.as_str() == name => Some(&**value),
                (Value::Str(key), value) if key.as_str() == name => Some(value),
                _ => None,
            })
    };
    let string = |name: &str| match get(name) {
        Some(Value::Str(value)) => Some(value.as_str()),
        _ => None,
    };
    let flag = |name: &str| match get(name) {
        Some(Value::Bool(value)) => Some(*value),
        _ => None,
    };
    if flag("visible") == Some(false) {
        return None;
    }
    let toggled = matches!(get("toggle-state"), Some(Value::I32(1)));
    let kind = match (string("type"), string("toggle-type")) {
        (Some("separator"), _) => EntryKind::Separator,
        (_, Some("checkmark")) => EntryKind::Check(toggled),
        (_, Some("radio")) => EntryKind::Radio(toggled),
        _ => EntryKind::Item,
    };
    Some(MenuEntry {
        id: i32::try_from(id).ok()?,
        label: string("label").map(without_mnemonics).unwrap_or_default(),
        enabled: flag("enabled") != Some(false),
        kind,
        children: children.inner().iter().filter_map(entry).collect(),
    })
}

/// "_File" -> "File"; "__" is a literal underscore.
fn without_mnemonics(label: &str) -> String {
    let mut result = String::with_capacity(label.len());
    let mut chars = label.chars();
    while let Some(char) = chars.next() {
        match char {
            '_' => result.extend(chars.next()),
            char => result.push(char),
        }
    }
    result
}

/// Prefers symbolic theme icons, which suit the bar. Raster icons become silhouettes.
fn resolve_icon((name, theme_path, pixmaps): &IconSource) -> Option<TrayIcon> {
    let file = (!name.is_empty())
        .then(|| find_icon(name, theme_path))
        .flatten();
    if let Some(path) = file {
        if path.ends_with(".svg") {
            return Some(TrayIcon::Svg(path.into()));
        }
        let image = image::ImageReader::open(&path)
            .ok()?
            .with_guessed_format()
            .ok()?
            .decode()
            .ok()?
            .into_rgba8();
        let (width, height) = image.dimensions();
        return silhouette(width, height, image.pixels().map(|pixel| pixel.0[3]));
    }
    // ARGB32 in network byte order.
    let (width, height, data) = (pixmaps.iter())
        .filter(|(width, height, data)| {
            *width > 0 && *height > 0 && data.len() == (*width * *height * 4) as usize
        })
        .max_by_key(|(width, height, _)| width * height)?;
    silhouette(
        *width as u32,
        *height as u32,
        data.chunks_exact(4).map(|pixel| pixel[0]),
    )
}

fn find_icon(name: &str, theme_path: &str) -> Option<String> {
    if name.starts_with('/') {
        return Path::new(name).is_file().then(|| name.to_owned());
    }
    let themed = (!theme_path.is_empty())
        .then(|| {
            ["svg", "png"].iter().find_map(|extension| {
                let path = Path::new(theme_path).join(format!("{name}.{extension}"));
                path.is_file().then(|| path.to_string_lossy().into_owned())
            })
        })
        .flatten();
    themed
        .or_else(|| icon_theme::lookup(&format!("{name}-symbolic"), true))
        .or_else(|| icon_theme::lookup(name, true))
}

fn silhouette(width: u32, height: u32, alpha: impl Iterator<Item = u8>) -> Option<TrayIcon> {
    let color = theme::TRAY_ACCENT;
    let [r, g, b] = [color.r, color.g, color.b].map(|channel| (channel * 255.).round() as u8);
    // GPUI's images are BGRA.
    let pixels = alpha.flat_map(|alpha| [b, g, r, alpha]).collect();
    let buffer = image::RgbaImage::from_raw(width, height, pixels)?;
    let image = RenderImage::new(vec![image::Frame::new(buffer)]);
    Some(TrayIcon::Raster(Arc::new(image)))
}

impl TrayItem {
    /// e.g. raising its window.
    pub async fn activate(&self) -> Result<()> {
        let (service, path) = split_key(&self.key);
        connection()?
            .call_method(Some(service), path, Some(ITEM), "Activate", &(0i32, 0i32))
            .await?;
        Ok(())
    }

    /// Lets the menu update itself before it's shown.
    pub async fn menu_opened(&self) -> Result<()> {
        self.menu_event("AboutToShow", 0).await
    }

    pub async fn menu_clicked(&self, id: i32) -> Result<()> {
        let (service, _) = split_key(&self.key);
        let path = self.menu_path.as_deref().ok_or("no menu")?;
        let event = (id, "clicked", Value::from(0i32), 0u32);
        (connection()?)
            .call_method(Some(service), path, Some(MENU), "Event", &event)
            .await?;
        Ok(())
    }

    async fn menu_event(&self, method: &str, id: i32) -> Result<()> {
        let (service, _) = split_key(&self.key);
        let path = self.menu_path.as_deref().ok_or("no menu")?;
        (connection()?)
            .call_method(Some(service), path, Some(MENU), method, &id)
            .await?;
        Ok(())
    }
}

fn connection() -> Result<&'static Connection> {
    Ok(CONNECTION.get().ok_or("tray not connected")?)
}

/// The registry, while we own its name. Hosts (including our own) list its items.
#[derive(Default)]
struct Watcher {
    items: Vec<String>,
    hosts: Vec<String>,
}

#[zbus::interface(name = "org.kde.StatusNotifierWatcher")]
impl Watcher {
    /// `service` is a bus name, or an object path on the sender (as Ayatana's items send).
    async fn register_status_notifier_item(
        &mut self,
        service: &str,
        #[zbus(header)] header: Header<'_>,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) -> zbus::fdo::Result<()> {
        let key = match header.sender() {
            Some(sender) if service.starts_with('/') => format!("{sender}{service}"),
            _ => format!("{service}/StatusNotifierItem"),
        };
        if !self.items.contains(&key) {
            self.items.push(key.clone());
            Self::status_notifier_item_registered(&emitter, &key).await?;
        }
        Ok(())
    }

    async fn register_status_notifier_host(
        &mut self,
        service: &str,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) -> zbus::fdo::Result<()> {
        if !self.hosts.iter().any(|host| host == service) {
            self.hosts.push(service.to_owned());
            Self::status_notifier_host_registered(&emitter).await?;
        }
        Ok(())
    }

    #[zbus(property)]
    fn registered_status_notifier_items(&self) -> Vec<String> {
        self.items.clone()
    }

    #[zbus(property)]
    fn is_status_notifier_host_registered(&self) -> bool {
        // This shell is always a host.
        true
    }

    #[zbus(property)]
    fn protocol_version(&self) -> i32 {
        0
    }

    #[zbus(signal)]
    async fn status_notifier_item_registered(
        emitter: &SignalEmitter<'_>,
        service: &str,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn status_notifier_item_unregistered(
        emitter: &SignalEmitter<'_>,
        service: &str,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn status_notifier_host_registered(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;
}

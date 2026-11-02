use std::collections::BTreeMap;
use std::collections::HashMap;
use std::io;
use std::time::Duration;

use futures::Stream;
use futures::StreamExt;
use zbus::fdo::PropertiesProxy;
use zbus::proxy::CacheProperties;
use zbus::zvariant::OwnedObjectPath;

use super::Data;
use super::DataSource;
use super::Result;

const DESTINATION: &str = "org.freedesktop.NetworkManager";
const PATH: &str = "/org/freedesktop/NetworkManager";
const ACTIVE: &str = "org.freedesktop.NetworkManager.Connection.Active";
const ACCESS_POINT: &str = "org.freedesktop.NetworkManager.AccessPoint";
const DEVICE: &str = "org.freedesktop.NetworkManager.Device";
const WIRELESS: &str = "org.freedesktop.NetworkManager.Device.Wireless";

pub struct Wifi;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WifiNetwork {
    pub ssid: String,
    /// Frequency in MHz.
    pub frequency: u32,
    /// NetworkManager signal quality percentage, not RSSI in dBm.
    pub strength: u8,
    pub secured: bool,
    ssid_bytes: Vec<u8>,
    access_point: OwnedObjectPath,
    security_flags: u32,
}

impl WifiNetwork {
    pub fn band(&self) -> Option<&'static str> {
        match self.frequency {
            2400..=2500 => Some("2.4 GHz"),
            4900..=5895 => Some("5 GHz"),
            5925..=7125 => Some("6 GHz"),
            _ => None,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WifiState {
    pub enabled: bool,
    pub ssid: Option<String>,
    pub current: Option<WifiNetwork>,
    /// Visible named networks, strongest AP per SSID, excluding the current SSID.
    pub networks: Vec<WifiNetwork>,
}

impl Data<Wifi> {
    pub fn toggle_enabled(&mut self, cx: &mut gpui::Context<Self>) {
        let Some(mut target) = self.state.target.clone() else {
            return;
        };
        target.enabled = !target.enabled;
        let enabled = target.enabled;
        self.request(
            target,
            async move {
                let connection = zbus::Connection::system().await?;
                properties(&connection, PATH)
                    .await?
                    .set(DESTINATION.try_into()?, "WirelessEnabled", enabled.into())
                    .await?;
                Ok(())
            },
            cx,
        );
    }
}

impl DataSource for Wifi {
    type Value = WifiState;

    fn reconcile_target(target: &mut WifiState, known: &WifiState) -> bool {
        target.ssid.clone_from(&known.ssid);
        target.current.clone_from(&known.current);
        target.networks.clone_from(&known.networks);
        true
    }

    fn stream(self) -> impl Stream<Item = Result<WifiState>> + Send + 'static {
        async_stream::stream! {
            loop {
                let result = watch().await;
                match result {
                    Ok((connection, mut updates)) => {
                        let mut previous = None;
                        loop {
                            match read(&connection).await {
                                Ok(state) => {
                                    if previous.as_ref() != Some(&state) {
                                        previous = Some(state.clone());
                                        yield Ok(state);
                                    }
                                }
                                Err(error) => {
                                    yield Err(error);
                                    break;
                                }
                            }
                            match updates.next().await {
                                Some(Ok(())) => {}
                                Some(Err(error)) => {
                                    yield Err(error);
                                    break;
                                }
                                None => {
                                    yield Err(io::Error::new(
                                        io::ErrorKind::BrokenPipe,
                                        "NetworkManager signal stream closed",
                                    ).into());
                                    break;
                                }
                            }
                        }
                    }
                    Err(error) => yield Err(error),
                }
                async_io::Timer::after(Duration::from_secs(2)).await;
            }
        }
    }
}

async fn watch() -> Result<(
    zbus::Connection,
    impl Stream<Item = Result<()>> + Send + Unpin + 'static,
)> {
    let connection = zbus::Connection::system().await?;
    let properties = properties(&connection, PATH).await?;
    // Subscribe across the object tree before reading: AP and active-connection changes
    // aren't necessarily accompanied by a root property change.
    let rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .sender(DESTINATION)?
        .path_namespace(PATH)?
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .build();
    let changes = zbus::MessageStream::for_match_rule(rule, &connection, None)
        .await?
        .map(|message| message.map(|_| ()).map_err(Into::into));
    let owners = properties
        .inner()
        .receive_owner_changed()
        .await?
        .map(|owner| {
            owner.map(|_| ()).ok_or_else(|| {
                io::Error::new(io::ErrorKind::NotConnected, "NetworkManager unavailable").into()
            })
        });
    Ok((connection, futures::stream::select(changes, owners)))
}

async fn properties<'a>(
    connection: &zbus::Connection,
    path: &'a str,
) -> Result<PropertiesProxy<'a>> {
    Ok(PropertiesProxy::builder(connection)
        .destination(DESTINATION)?
        .path(path)?
        .cache_properties(CacheProperties::No)
        .build()
        .await?)
}

async fn read(connection: &zbus::Connection) -> Result<WifiState> {
    let root = properties(connection, PATH).await?;
    let enabled = bool::try_from(root.get(DESTINATION.try_into()?, "WirelessEnabled").await?)?;
    let mut state = WifiState {
        enabled,
        ssid: None,
        current: None,
        networks: Vec::new(),
    };
    if !enabled {
        return Ok(state);
    }
    let connections = Vec::<OwnedObjectPath>::try_from(
        root.get(DESTINATION.try_into()?, "ActiveConnections")
            .await?,
    )?;
    for path in connections {
        let active = properties(connection, path.as_str()).await?;
        let kind = String::try_from(active.get(ACTIVE.try_into()?, "Type").await?)?;
        if kind != "802-11-wireless" {
            continue;
        }
        // ActiveConnections also includes connections still being activated.
        if u32::try_from(active.get(ACTIVE.try_into()?, "State").await?)? != 2 {
            continue;
        }
        let ap =
            OwnedObjectPath::try_from(active.get(ACTIVE.try_into()?, "SpecificObject").await?)?;
        state.ssid = Some(if ap.as_str() != "/" {
            let network = read_network(connection, &ap).await?;
            let ssid = network.ssid.clone();
            state.current = Some(network);
            ssid
        } else {
            String::try_from(active.get(ACTIVE.try_into()?, "Id").await?)?
        });
        break;
    }
    let mut networks = BTreeMap::<String, WifiNetwork>::new();
    for device in wireless_devices(connection).await? {
        let wireless = properties(connection, device.as_str()).await?;
        let aps = Vec::<OwnedObjectPath>::try_from(
            wireless.get(WIRELESS.try_into()?, "AccessPoints").await?,
        )?;
        for ap in aps {
            // APs can disappear between listing them and reading their properties.
            let Ok(network) = read_network(connection, &ap).await else {
                continue;
            };
            if network.ssid.is_empty() || state.ssid.as_ref() == Some(&network.ssid) {
                continue;
            }
            let entry = networks
                .entry(network.ssid.clone())
                .or_insert_with(|| network.clone());
            if network.strength > entry.strength
                || (network.strength == entry.strength && network.frequency > entry.frequency)
            {
                *entry = network;
            }
        }
    }
    state.networks = networks.into_values().collect();
    state.networks.sort_by(|a, b| {
        b.strength
            .cmp(&a.strength)
            .then_with(|| a.ssid.cmp(&b.ssid))
    });
    Ok(state)
}

async fn read_network(
    connection: &zbus::Connection,
    path: &OwnedObjectPath,
) -> Result<WifiNetwork> {
    let ap = properties(connection, path.as_str()).await?;
    let values = ap.get_all(ACCESS_POINT.try_into()?).await?;
    let missing = || io::Error::new(io::ErrorKind::InvalidData, "Missing access point property");
    let ssid = Vec::<u8>::try_from(values.get("Ssid").ok_or_else(missing)?.try_clone()?)?;
    let flags = u32::try_from(values.get("Flags").ok_or_else(missing)?.try_clone()?)?;
    let security_flags = u32::try_from(values.get("WpaFlags").ok_or_else(missing)?.try_clone()?)?
        | u32::try_from(values.get("RsnFlags").ok_or_else(missing)?.try_clone()?)?;
    Ok(WifiNetwork {
        ssid: String::from_utf8_lossy(&ssid).into_owned(),
        secured: flags & 1 != 0 || security_flags != 0,
        ssid_bytes: ssid,
        access_point: path.clone(),
        security_flags,
        frequency: u32::try_from(values.get("Frequency").ok_or_else(missing)?.try_clone()?)?,
        strength: u8::try_from(values.get("Strength").ok_or_else(missing)?.try_clone()?)?,
    })
}

async fn wireless_devices(connection: &zbus::Connection) -> Result<Vec<OwnedObjectPath>> {
    let root = properties(connection, PATH).await?;
    let devices =
        Vec::<OwnedObjectPath>::try_from(root.get(DESTINATION.try_into()?, "Devices").await?)?;
    let mut wireless = Vec::new();
    for device in devices {
        let props = properties(connection, device.as_str()).await?;
        if u32::try_from(props.get(DEVICE.try_into()?, "DeviceType").await?)? == 2 {
            wireless.push(device);
        }
    }
    Ok(wireless)
}

/// Request activation of the selected AP. Success means NetworkManager accepted
/// the request, not that authentication or association has finished.
/// Passwords support WPA/WPA2 Personal; enterprise authentication is unsupported.
/// Without a password, prefer a compatible saved profile (and its saved secrets).
pub async fn connect(network: WifiNetwork, password: Option<String>) -> Result<()> {
    use zbus::zvariant::Value;

    let unsupported = |message| io::Error::new(io::ErrorKind::Unsupported, message);
    // NM_802_11_AP_SEC_KEY_MGMT_PSK and NM_802_11_AP_SEC_KEY_MGMT_802_1X.
    if network.security_flags & 0x200 != 0 && network.security_flags & 0x100 == 0 {
        return Err(unsupported("Enterprise Wi-Fi authentication is not supported").into());
    }
    let connection = zbus::Connection::system().await?;
    let mut selected = None;
    for device in wireless_devices(&connection).await? {
        let props = properties(&connection, device.as_str()).await?;
        let aps = Vec::<OwnedObjectPath>::try_from(
            props.get(WIRELESS.try_into()?, "AccessPoints").await?,
        )?;
        if aps.contains(&network.access_point) {
            selected = Some(device);
            break;
        }
    }
    let device = selected.ok_or_else(|| {
        io::Error::new(
            io::ErrorKind::NotFound,
            "Wi-Fi access point is no longer available; scan again",
        )
    })?;
    let current = read_network(&connection, &network.access_point).await?;
    if current.ssid_bytes != network.ssid_bytes
        || current.secured != network.secured
        || current.security_flags != network.security_flags
    {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "Wi-Fi access point changed; scan again",
        )
        .into());
    }
    let root = zbus::Proxy::new(&connection, DESTINATION, PATH, DESTINATION).await?;
    if password.is_none() {
        let props = properties(&connection, device.as_str()).await?;
        // AvailableConnections is filtered by NetworkManager for this device.
        let profiles = Vec::<OwnedObjectPath>::try_from(
            props
                .get(DEVICE.try_into()?, "AvailableConnections")
                .await?,
        )?;
        for profile in profiles {
            let proxy = zbus::Proxy::new(
                &connection,
                DESTINATION,
                profile.as_str(),
                "org.freedesktop.NetworkManager.Settings.Connection",
            )
            .await?;
            let settings: HashMap<String, HashMap<String, zbus::zvariant::OwnedValue>> =
                proxy.call("GetSettings", &()).await?;
            let Some(wireless) = settings.get("802-11-wireless") else {
                continue;
            };
            let Some(ssid) = wireless.get("ssid") else {
                continue;
            };
            if Vec::<u8>::try_from(ssid.try_clone()?)? != network.ssid_bytes {
                continue;
            }
            let security = settings.get("802-11-wireless-security");
            let compatible = if network.secured {
                security
                    .and_then(|s| s.get("key-mgmt"))
                    .and_then(|v| <&str>::try_from(v).ok())
                    == Some("wpa-psk")
                    && network.security_flags & 0x100 != 0
            } else {
                security.is_none()
            };
            if compatible {
                let _: OwnedObjectPath = root
                    .call(
                        "ActivateConnection",
                        &(profile, &device, &network.access_point),
                    )
                    .await?;
                return Ok(());
            }
        }
    }
    let mut settings = HashMap::<&str, HashMap<&str, Value<'_>>>::new();
    settings.insert(
        "connection",
        HashMap::from([
            ("id", Value::from(network.ssid.as_str())),
            ("type", Value::from("802-11-wireless")),
        ]),
    );
    settings.insert(
        "802-11-wireless",
        HashMap::from([
            ("ssid", Value::from(network.ssid_bytes.clone())),
            ("mode", Value::from("infrastructure")),
        ]),
    );
    if network.secured {
        if network.security_flags & 0x100 == 0 {
            return Err(unsupported("Only WPA/WPA2 Personal Wi-Fi is supported; WEP and WPA3-only networks are unsupported").into());
        }
        let password = password.as_deref().ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidInput,
                "A Wi-Fi password is required; no compatible saved connection was found",
            )
        })?;
        settings.insert(
            "802-11-wireless-security",
            HashMap::from([
                ("key-mgmt", Value::from("wpa-psk")),
                ("psk", Value::from(password)),
            ]),
        );
    }
    let _: (OwnedObjectPath, OwnedObjectPath) = root
        .call(
            "AddAndActivateConnection",
            &(settings, &device, &network.access_point),
        )
        .await?;
    Ok(())
}

/// Request a scan on every Wi-Fi device. The UI owns scheduling: call immediately
/// when auto-scan is enabled, then about every 15 seconds only while the menu is open.
/// Completion means NetworkManager accepted the requests, not that scans finished.
pub async fn request_scan() -> Result<()> {
    let connection = zbus::Connection::system().await?;
    let root = properties(&connection, PATH).await?;
    if !bool::try_from(root.get(DESTINATION.try_into()?, "WirelessEnabled").await?)? {
        return Ok(());
    }
    let mut result = Ok(());
    for device in wireless_devices(&connection).await? {
        let proxy = zbus::Proxy::new(&connection, DESTINATION, device.as_str(), WIRELESS).await?;
        let options = HashMap::<&str, zbus::zvariant::Value<'_>>::new();
        let scan: zbus::Result<()> = proxy.call("RequestScan", &(options,)).await;
        if let Err(error) = scan {
            result = Err(error.into());
        }
    }
    result
}

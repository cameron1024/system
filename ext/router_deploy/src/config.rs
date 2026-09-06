use std::collections::BTreeMap;
use std::io::Read;

use anyhow::{Context, Result};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct Config {
    pub host: String,

    #[serde(default)]
    pub static_leases: Vec<StaticLease>,

    #[serde(default)]
    pub service_domains: BTreeMap<String, String>,

    #[serde(default)]
    pub wan_blocked_macs: Vec<String>,

    /// Proton Pass secret references (pass://SHARE_ID/ITEM_ID/FIELD),
    /// resolved lazily via `pass-cli` (see crate::secrets).
    #[serde(default)]
    pub secrets: BTreeMap<String, String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct StaticLease {
    /// Hostname for the lease (also used as the uci section name).
    pub name: String,
    pub mac: String,
    pub ip: String,
}

impl Config {
    pub fn from_stdin() -> Result<Self> {
        let mut input = String::new();
        std::io::stdin()
            .read_to_string(&mut input)
            .context("failed to read config from stdin")?;
        serde_json::from_str(&input).context("failed to parse config JSON from stdin")
    }
}

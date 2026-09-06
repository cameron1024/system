//! Apply the config to the router in one shot: lower everything to a single
//! idempotent uci script (plain `uci set`s — safe to re-run), resolve and
//! inject secrets, commit, and restart the affected services. No reboot.

use std::collections::BTreeMap;

use anyhow::{Context, Result, bail};
use secrecy::{ExposeSecret, SecretString};
use zeroize::Zeroizing;

use crate::{config::Config, secrets, ssh::Ssh};

pub fn apply(config: &Config, ssh: &Ssh) -> Result<()> {
    let mut resolved = BTreeMap::new();
    for (key, reference) in &config.secrets {
        let secret = secrets::load_secret(reference)
            .with_context(|| format!("failed to resolve secret {key:?}"))?;
        resolved.insert(key.clone(), secret);
    }

    let script = build_script(config, &resolved)?;
    ssh.run(&script)?;

    println!(
        "Applied: {} leases, {} service domains, {} WAN blocks, {} secrets. Services restarted.",
        config.static_leases.len(),
        config.service_domains.len(),
        config.wan_blocked_macs.len(),
        resolved.len(),
    );
    Ok(())
}

/// The whole remote script, including secret values, so the buffer is
/// zeroized on drop. It is piped to `sh -s` over ssh (never in argv).
fn build_script(
    config: &Config,
    secrets: &BTreeMap<String, SecretString>,
) -> Result<Zeroizing<String>> {
    let mut script = Zeroizing::new(String::from("set -e\n"));
    let mut line = |s: &str| {
        script.push_str(s);
        script.push('\n');
    };

    // Static DHCP leases.
    for lease in &config.static_leases {
        let section = section_name(&lease.name);
        line(&format!("uci set dhcp.{section}=host"));
        line(&format!("uci set dhcp.{section}.name={}", sq(&lease.name)));
        line(&format!(
            "uci set dhcp.{section}.mac={}",
            sq(&lease.mac.to_lowercase())
        ));
        line(&format!("uci set dhcp.{section}.ip={}", sq(&lease.ip)));
    }

    // Service domains: rebuild the dnsmasq address list from scratch so
    // removed entries disappear (delete fails harmlessly if absent).
    line("uci -q delete 'dhcp.@dnsmasq[0].address' || true");
    for (domain, target) in &config.service_domains {
        let ip = target.split(':').next().unwrap_or(target);
        line(&format!(
            "uci add_list {}",
            sq(&format!("dhcp.@dnsmasq[0].address=/{domain}/{ip}"))
        ));
    }

    // WAN-blocked MACs.
    for mac in &config.wan_blocked_macs {
        let mac = mac.to_lowercase();
        let section = format!("block_wan_mac_{}", mac.replace(':', ""));
        line(&format!("uci set firewall.{section}=rule"));
        line(&format!(
            "uci set firewall.{section}.name={}",
            sq(&format!("Block WAN {mac}"))
        ));
        line(&format!("uci set firewall.{section}.src=lan"));
        line(&format!("uci set firewall.{section}.dest=wan"));
        line(&format!("uci set firewall.{section}.src_mac={}", sq(&mac)));
        line(&format!("uci set firewall.{section}.target=REJECT"));
    }

    // Secrets: each supported key maps to a fixed target on the router.
    for (key, secret) in secrets {
        let value = secret.expose_secret();
        match key.as_str() {
            "wifiPassword" => {
                line(&format!(
                    "uci set wireless.default_radio0.key={}",
                    sq(value)
                ));
                line(&format!(
                    "uci set wireless.default_radio1.key={}",
                    sq(value)
                ));
            }
            "pppoeUsername" => line(&format!("uci set network.wan.username={}", sq(value))),
            "pppoePassword" => line(&format!("uci set network.wan.password={}", sq(value))),
            // Takes effect immediately; not staged/committed like uci.
            "routerPassword" => line(&format!(
                "printf '%s\\n%s\\n' {} {} | passwd root >/dev/null",
                sq(value),
                sq(value)
            )),
            _ => bail!(
                "unknown secret key {key:?} (supported: wifiPassword, \
                 pppoeUsername, pppoePassword, routerPassword)"
            ),
        }
    }

    // Commit and restart. Ordered least-disruptive first; network/wifi last
    // because they can briefly drop connectivity.
    line("uci commit dhcp");
    line("uci commit firewall");
    line("uci commit network");
    line("uci commit wireless");
    line("/etc/init.d/firewall reload");
    line("/etc/init.d/dnsmasq restart");
    line("/etc/init.d/network reload");
    line("wifi reload");

    Ok(script)
}

/// Shell-single-quote a string.
fn sq(s: &str) -> String {
    format!("'{}'", s.replace('\'', r"'\''"))
}

/// uci section names may only contain [A-Za-z0-9_], but lease names are
/// hostnames which may contain '-'.
fn section_name(name: &str) -> String {
    name.chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '_' })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::StaticLease;

    fn test_config() -> Config {
        Config {
            host: "root@test".into(),
            static_leases: vec![StaticLease {
                name: "cudy-ap".into(),
                mac: "D4:0D:AB:2B:C7:73".into(),
                ip: "192.168.1.4".into(),
            }],
            service_domains: BTreeMap::from([("home.lan".into(), "192.168.1.2:8123".into())]),
            wan_blocked_macs: vec!["AA:BB:CC:DD:EE:FF".into()],
            secrets: BTreeMap::new(),
        }
    }

    #[test]
    fn builds_expected_script() {
        let secrets = BTreeMap::from([("wifiPassword".into(), SecretString::from("hunter2"))]);
        let script = build_script(&test_config(), &secrets).unwrap();

        assert!(script.contains("uci set dhcp.cudy_ap=host"));
        assert!(script.contains("uci set dhcp.cudy_ap.mac='d4:0d:ab:2b:c7:73'"));
        assert!(script.contains("uci add_list 'dhcp.@dnsmasq[0].address=/home.lan/192.168.1.2'"));
        assert!(script.contains("uci set firewall.block_wan_mac_aabbccddeeff.src_mac='aa:bb:cc:dd:ee:ff'"));
        assert!(script.contains("uci set wireless.default_radio0.key='hunter2'"));
        assert!(script.ends_with("wifi reload\n"));
    }

    #[test]
    fn rejects_unknown_secret_keys() {
        let secrets = BTreeMap::from([("nonsense".into(), SecretString::from("x"))]);
        assert!(build_script(&test_config(), &secrets).is_err());
    }
}

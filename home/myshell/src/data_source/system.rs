//! CPU, memory and disk have no change notifications, so they are sampled on an interval.

use std::io;
use std::path::PathBuf;
use std::time::Duration;

use futures::Stream;

use super::DataSource;
use super::Result;

const INTERVAL: Duration = Duration::from_secs(2);

pub struct System;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SystemStats {
    pub cpu: u32,
    /// Degrees Celsius, if a CPU sensor was found.
    pub cpu_temperature: Option<i32>,
    pub memory: u32,
    /// Bytes.
    pub memory_used: u64,
    pub memory_total: u64,
    pub disk: u32,
    pub disk_free: u64,
}

impl SystemStats {
    pub fn memory_label(&self) -> String {
        let gb = |bytes: u64| bytes as f64 / f64::from(1 << 30);
        format!(
            "{:.1} GB / {:.1} GB",
            gb(self.memory_used),
            gb(self.memory_total)
        )
    }

    pub fn cpu_temperature_label(&self) -> String {
        self.cpu_temperature
            .map_or_else(|| "Temperature unavailable".into(), |t| format!("{t}°C"))
    }

    pub fn disk_free_label(&self) -> String {
        let gib = self.disk_free as f64 / f64::from(1 << 30);
        match gib {
            1024.0.. => format!("{:.1}T", gib / 1024.),
            10.0.. => format!("{gib:.0}G"),
            _ => format!("{gib:.1}G"),
        }
    }
}

impl DataSource for System {
    type Value = SystemStats;

    fn stream(self) -> impl Stream<Item = Result<SystemStats>> + Send + 'static {
        async_stream::stream! {
            // The first CPU value is the average since boot; later ones cover one interval.
            let mut previous = (0, 0);
            let sensor = cpu_sensor();
            loop {
                yield sample(&mut previous, sensor.as_ref());
                async_io::Timer::after(INTERVAL).await;
            }
        }
    }
}

/// The CPU package sensor: k10temp/zenpower (AMD) or coretemp (Intel). Their first sensor is the
/// package (Tctl/Tdie on AMD, "Package id 0" on Intel).
fn cpu_sensor() -> Option<PathBuf> {
    std::fs::read_dir("/sys/class/hwmon")
        .ok()?
        .flatten()
        .map(|entry| entry.path())
        .find(|path| {
            std::fs::read_to_string(path.join("name"))
                .is_ok_and(|name| matches!(name.trim(), "k10temp" | "zenpower" | "coretemp"))
        })
        .map(|path| path.join("temp1_input"))
}

fn sample(previous: &mut (u64, u64), sensor: Option<&PathBuf>) -> Result<SystemStats> {
    let invalid = || io::Error::new(io::ErrorKind::InvalidData, "unexpected /proc format");

    let stat = std::fs::read_to_string("/proc/stat")?;
    // user nice system idle iowait irq softirq steal (guest time is already in user/nice)
    let times = stat
        .lines()
        .next()
        .and_then(|line| line.strip_prefix("cpu "))
        .ok_or_else(invalid)?
        .split_whitespace()
        .take(8)
        .map(str::parse)
        .collect::<std::result::Result<Vec<u64>, _>>()?;
    let total: u64 = times.iter().sum();
    let idle = times.get(3).ok_or_else(invalid)? + times.get(4).ok_or_else(invalid)?;
    let (previous_total, previous_idle) = std::mem::replace(previous, (total, idle));
    let elapsed = total.saturating_sub(previous_total);
    let cpu = percent(
        elapsed.saturating_sub(idle.saturating_sub(previous_idle)),
        elapsed,
    );

    let meminfo = std::fs::read_to_string("/proc/meminfo")?;
    let field = |name: &str| {
        meminfo
            .lines()
            .find_map(|line| {
                line.strip_prefix(name)?
                    .strip_suffix("kB")?
                    .trim()
                    .parse()
                    .ok()
            })
            .ok_or_else(invalid)
    };
    let (total_memory, available): (u64, u64) = (field("MemTotal:")?, field("MemAvailable:")?);

    let disk = rustix::fs::statvfs("/")?;
    // Like df: blocks reserved for root count as neither used nor available.
    let used = disk.f_blocks.saturating_sub(disk.f_bfree);
    // Millidegrees.
    let cpu_temperature = sensor
        .and_then(|path| std::fs::read_to_string(path).ok())
        .and_then(|value| value.trim().parse::<i32>().ok())
        .map(|millidegrees| (millidegrees + 500) / 1000);
    let used_memory = total_memory.saturating_sub(available);
    Ok(SystemStats {
        cpu,
        cpu_temperature,
        memory: percent(used_memory, total_memory),
        memory_used: used_memory * 1024,
        memory_total: total_memory * 1024,
        disk: percent(used, used + disk.f_bavail),
        disk_free: disk.f_bavail * disk.f_frsize,
    })
}

fn percent(part: u64, whole: u64) -> u32 {
    if whole == 0 {
        return 0;
    }
    ((part * 100 + whole / 2) / whole) as u32
}

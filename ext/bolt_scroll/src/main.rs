//! Smooth scrolling for HID++ mice on a Logitech Bolt receiver.
//!
//! Mainline `hid-logitech-dj` doesn't drive Bolt receivers, so the paired
//! mouse's input arrives on the receiver's boot-mouse interface via
//! `hid-generic`, which knows nothing about the HID++ hi-res wheel
//! multiplier. Once hi-res mode is on (e.g. Solaar's "Scroll Wheel
//! Resolution"), each notch produces `multiplier` full-notch events.
//!
//! This grabs that interface and re-emits it through uinput with the wheel
//! rescaled. See `rescale.rs` for the conversion.

mod rescale;

use std::{thread, time::Duration};

use anyhow::{Context, Result, bail};
use evdev::{
    BusType, InputEvent, InputId, RelativeAxisCode,
    raw_stream::{self, RawDevice},
    uinput::VirtualDevice,
};
use rescale::{Event, Rescaler};

const LOGITECH: u16 = 0x046d;
const BOLT_RECEIVER: u16 = 0xc548;
const VIRTUAL_NAME: &str = "bolt-scroll virtual mouse";

const EV_SYN: u16 = 0x00;
const SYN_REPORT: u16 = 0;
const SYN_DROPPED: u16 = 3;

fn main() -> Result<()> {
    let multiplier = parse_args()?;
    eprintln!("bolt-scroll: wheel multiplier {multiplier}");

    let mut waiting_logged = false;
    loop {
        let Some((path, device)) = find_receiver_mouse() else {
            if !waiting_logged {
                eprintln!("bolt-scroll: waiting for a Bolt receiver");
                waiting_logged = true;
            }
            thread::sleep(Duration::from_secs(1));
            continue;
        };
        waiting_logged = false;
        eprintln!("bolt-scroll: using {}", path.display());
        if let Err(e) = forward(device, multiplier) {
            eprintln!("bolt-scroll: {}: {e:#}", path.display());
        }
        // Short pause so a device that errors immediately doesn't spin.
        thread::sleep(Duration::from_millis(200));
    }
}

fn parse_args() -> Result<i32> {
    let mut args = std::env::args().skip(1);
    let mut multiplier = 15;
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--multiplier" => {
                multiplier = args
                    .next()
                    .context("--multiplier needs a value")?
                    .parse()
                    .context("--multiplier must be an integer")?;
                if multiplier <= 0 {
                    bail!("--multiplier must be positive");
                }
            }
            other => bail!("unknown argument {other:?} (usage: bolt_scroll [--multiplier N])"),
        }
    }
    Ok(multiplier)
}

/// The receiver exposes several evdev nodes; the boot-mouse one is the only
/// one with both pointer motion and a hi-res wheel. Filtering on USB also
/// excludes our own uinput device, which reuses the vendor/product IDs.
fn find_receiver_mouse() -> Option<(std::path::PathBuf, RawDevice)> {
    raw_stream::enumerate().find(|(_, dev)| {
        let id = dev.input_id();
        let rel = dev.supported_relative_axes();
        id.bus_type() == BusType::BUS_USB
            && id.vendor() == LOGITECH
            && id.product() == BOLT_RECEIVER
            && rel.is_some_and(|r| {
                r.contains(RelativeAxisCode::REL_X)
                    && r.contains(RelativeAxisCode::REL_WHEEL_HI_RES)
            })
    })
}

fn forward(mut source: RawDevice, multiplier: i32) -> Result<()> {
    let keys = source
        .supported_keys()
        .context("receiver mouse has no buttons")?;
    let axes = source
        .supported_relative_axes()
        .context("receiver mouse has no relative axes")?;
    let id = source.input_id();

    // Create the virtual device before grabbing, so there's never a window
    // with no working pointer.
    let mut sink = VirtualDevice::builder()?
        .name(VIRTUAL_NAME)
        .input_id(InputId::new(
            BusType::BUS_VIRTUAL,
            id.vendor(),
            id.product(),
            id.version(),
        ))
        .with_keys(keys)?
        .with_relative_axes(axes)?
        .build()
        .context("creating uinput device")?;

    source.grab().context("grabbing receiver mouse")?;

    let mut rescaler = Rescaler::new(multiplier);
    let mut frame: Vec<Event> = Vec::new();
    let mut batch: Vec<InputEvent> = Vec::new();

    loop {
        for ev in source.fetch_events().context("reading events")? {
            let ev = Event::new(ev.event_type().0, ev.code(), ev.value());
            if ev.type_ != EV_SYN {
                rescaler.process(ev, &mut frame);
                continue;
            }
            match ev.code {
                SYN_REPORT => {
                    if !frame.is_empty() {
                        batch.clear();
                        batch.extend(
                            frame
                                .drain(..)
                                .map(|e| InputEvent::new(e.type_, e.code, e.value)),
                        );
                        // `emit` appends the SYN_REPORT itself.
                        sink.emit(&batch).context("writing to uinput")?;
                    }
                }
                SYN_DROPPED => {
                    frame.clear();
                    rescaler.reset();
                }
                _ => {}
            }
        }
    }
}

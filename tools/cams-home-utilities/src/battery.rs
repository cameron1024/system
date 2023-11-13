const BATTERY_UNKNOWN: &str = "󰂑 ??%";

const BATTERY_0: &str = "󰂎";
const BATTERY_10: &str = "󰁺";
const BATTERY_20: &str = "󰁻";
const BATTERY_30: &str = "󰁼";
const BATTERY_40: &str = "󰁽";
const BATTERY_50: &str = "󰁾";
const BATTERY_60: &str = "󰁿";
const BATTERY_70: &str = "󰂀";
const BATTERY_80: &str = "󰂁";
const BATTERY_90: &str = "󰂂";
const BATTERY_100: &str = "󰁹";

const CHARGING_BATTERY_0: &str = "󰢟";
const CHARGING_BATTERY_10: &str = "󰢜";
const CHARGING_BATTERY_20: &str = "󰂆";
const CHARGING_BATTERY_30: &str = "󰂇";
const CHARGING_BATTERY_40: &str = "󰂈";
const CHARGING_BATTERY_50: &str = "󰢝";
const CHARGING_BATTERY_60: &str = "󰂉";
const CHARGING_BATTERY_70: &str = "󰢞";
const CHARGING_BATTERY_80: &str = "󰂊";
const CHARGING_BATTERY_90: &str = "󰂋";
const CHARGING_BATTERY_100: &str = "󰂅";

pub fn battery() {
    let stdin = std::io::stdin();
    let lines = stdin.lines();

    for line in lines {
        match line {
            Err(e) => {
                eprintln!("{e}");
                std::process::exit(1);
            }
            Ok(s) => {
                let mut words = s.split_whitespace();
                let discharging = words.next() == Some("Discharging");

                match words.last() {
                    None => println!("{BATTERY_UNKNOWN}"),
                    Some(word) => {
                        let number: i16 = word.parse().unwrap();
                        let symbol = match (number / 10, discharging) {
                            (0, true) => BATTERY_0,
                            (1, true) => BATTERY_10,
                            (2, true) => BATTERY_20,
                            (3, true) => BATTERY_30,
                            (4, true) => BATTERY_40,
                            (5, true) => BATTERY_50,
                            (6, true) => BATTERY_60,
                            (7, true) => BATTERY_70,
                            (8, true) => BATTERY_80,
                            (9, true) => BATTERY_90,
                            (10, true) => BATTERY_100,
                            (0, false) => CHARGING_BATTERY_0,
                            (1, false) => CHARGING_BATTERY_10,
                            (2, false) => CHARGING_BATTERY_20,
                            (3, false) => CHARGING_BATTERY_30,
                            (4, false) => CHARGING_BATTERY_40,
                            (5, false) => CHARGING_BATTERY_50,
                            (6, false) => CHARGING_BATTERY_60,
                            (7, false) => CHARGING_BATTERY_70,
                            (8, false) => CHARGING_BATTERY_80,
                            (9, false) => CHARGING_BATTERY_90,
                            (10, false) => CHARGING_BATTERY_100,
                            _ => panic!("unknown battery %: {number}"),
                        };

                        println!("{symbol} {number}%");
                    }
                }
            }
        }
    }
}

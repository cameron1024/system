use crate::data_source::Result;

/// Called by background action runners; subprocess details stay independent of GPUI.
pub async fn command(program: &str, args: &[&str]) -> Result<String> {
    let output = async_process::Command::new(program)
        .args(args)
        .env("LC_ALL", "C")
        .kill_on_drop(true)
        .output()
        .await?;
    if !output.status.success() {
        return Err(std::io::Error::other(format!(
            "{program} {}: {}: {}",
            args.join(" "),
            output.status,
            String::from_utf8_lossy(&output.stderr).trim(),
        ))
        .into());
    }
    Ok(String::from_utf8(output.stdout)?)
}

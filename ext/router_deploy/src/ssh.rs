use std::io::Write;
use std::process::{Command, Stdio};

use anyhow::{Context, Result, bail};

pub struct Ssh {
    host: String,
}

impl Ssh {
    pub fn new(host: &str) -> Self {
        Self { host: host.to_owned() }
    }

    pub fn run(&self, script: &str) -> Result<String> {
        let mut child = Command::new("ssh")
            .args([
                "-o",
                "ControlMaster=auto",
                "-o",
                "ControlPath=/tmp/router_deploy_ssh_%C",
                "-o",
                "ControlPersist=60",
                "-o",
                "BatchMode=yes",
                &self.host,
                "/bin/sh -s",
            ])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .context("failed to spawn ssh")?;

        child
            .stdin
            .take()
            .expect("stdin was piped")
            .write_all(script.as_bytes())
            .context("failed to write script to ssh stdin")?;

        let output = child.wait_with_output().context("failed to wait for ssh")?;
        if !output.status.success() {
            bail!(
                "remote script failed ({}) on {}: {}",
                output.status,
                self.host,
                String::from_utf8_lossy(&output.stderr).trim(),
            );
        }
        String::from_utf8(output.stdout).context("ssh output was not UTF-8")
    }
}

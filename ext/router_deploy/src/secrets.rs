use std::process::Command;

use anyhow::{Context, Result, bail, ensure};
use secrecy::SecretString;
use zeroize::Zeroize;

/// Path to the pass-cli binary, injected at compile time by the nix build
/// (see build.nix). For plain `cargo` builds, set it manually, e.g.
/// `PASS_CLI_BIN=pass-cli cargo check`.
const PASS_CLI_BIN: &str = env!("PASS_CLI_BIN");

/// Resolve a Proton Pass secret reference of the form
/// `pass://SHARE_ID/ITEM_ID/FIELD` by shelling out to `pass-cli`.
///
/// The field component is required: without it pass-cli prints the whole
/// item, and we want exactly one value on stdout.
pub fn load_secret(reference: &str) -> Result<SecretString> {
    let rest = reference
        .strip_prefix("pass://")
        .with_context(|| format!("secret reference must start with pass://, got {reference:?}"))?;
    ensure!(
        rest.split('/').filter(|s| !s.is_empty()).count() == 3,
        "secret reference must be pass://SHARE_ID/ITEM_ID/FIELD, got {reference:?}",
    );

    let output = Command::new(PASS_CLI_BIN)
        .args(["item", "view", reference])
        .output()
        .with_context(|| format!("failed to run pass-cli at {PASS_CLI_BIN}"))?;

    if !output.status.success() {
        // stderr from pass-cli doesn't contain the secret value, so it is
        // safe to include in the error.
        bail!(
            "pass-cli failed for {reference} ({}): {}",
            output.status,
            String::from_utf8_lossy(&output.stderr).trim(),
        );
    }

    // The raw stdout buffer holds the secret value; wrap it in a
    // SecretString and zeroize the intermediate on every path so the only
    // long-lived copy is the self-zeroizing one.
    let mut stdout = output.stdout;
    let secret = std::str::from_utf8(&stdout)
        .context("pass-cli output was not UTF-8")
        .map(|value| SecretString::from(value.trim_end_matches(['\r', '\n'])));
    stdout.zeroize();
    secret
}

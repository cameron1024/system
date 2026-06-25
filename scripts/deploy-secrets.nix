# Optional sidecar for scripts/deploy-secrets.py, picked up by the mkScripts
# walker in flake.nix. `runtimeInputs` are added to the wrapped script's PATH;
# `libraries` (unused here) would be Python packages made importable.
{pkgs}: {
  runtimeInputs = [pkgs.openssh];
}

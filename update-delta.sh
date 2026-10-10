#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 0 ]; then
    echo "usage: $0" >&2
    exit 2
fi

TRUNK_REPO="${DELTA_NIX_LINUX_PATH:-/home/cameron/work/delta-nix-linux}"
STABLE_REPO="${DELTA_NIX_PATH:-/home/cameron/work/delta-nix}"

version_or_missing() {
    if command -v "$1" >/dev/null 2>&1; then
        "$1" --version
    else
        echo "not installed"
    fi
}

sync_repo() {
    cd "$1"
    echo "==> [$1] Discarding local changes"
    git reset --hard
    git clean -fd
    echo "==> [$1] Switching to main and pulling"
    git switch main
    git fetch
    git pull
}

OLD_STABLE_VERSION="$(version_or_missing delta-stable)"
OLD_TRUNK_VERSION="$(version_or_missing delta)"

# Stable pins are published upstream in delta-nix; pulling is enough.
sync_repo "$STABLE_REPO"

sync_repo "$TRUNK_REPO"
echo "==> Updating trunk pin"
nix run .#update -- trunk

echo "==> Building stable and trunk"
if ! nix build --no-link "$STABLE_REPO#delta" "$TRUNK_REPO#delta-trunk"; then
    echo "==> Build failed, leaving profiles unchanged" >&2
    exit 1
fi

echo "==> Builds succeeded, installing launchers"
TRUNK_PACKAGE="$(nix path-info "$TRUNK_REPO#delta-trunk")"
STABLE_PACKAGE="$(nix path-info "$STABLE_REPO#delta")"
LAUNCHERS="$(nix build --no-link --print-out-paths --impure --expr "
    let
      flake = builtins.getFlake (toString $TRUNK_REPO);
      pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
      trunk = builtins.storePath \"$TRUNK_PACKAGE\";
      stable = builtins.storePath \"$STABLE_PACKAGE\";
    in pkgs.runCommand \"delta-launchers\" {} ''
      mkdir -p \$out/bin
      ln -s \${trunk}/bin/delta \$out/bin/delta
      ln -s \${stable}/bin/delta \$out/bin/delta-stable
    ''
")"

# Replace packages installed by previous versions of this script with one
# conflict-free launcher package in the normal, already-on-PATH Nix profile.
nix profile remove delta-nix-linux 2>/dev/null || true
nix profile remove delta-nightly 2>/dev/null || true
nix profile remove delta-trunk 2>/dev/null || true
nix profile remove delta-launchers 2>/dev/null || true
nix profile add "$LAUNCHERS"

# Clean up channel-specific profiles and aliases from the previous approach.
PROFILE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
for channel in nightly trunk; do
    nix profile remove --profile "$PROFILE_DIR/delta-$channel" \
        "delta-$channel" 2>/dev/null || true
done
for name in delta delta-nightly delta-trunk; do
    alias="$BIN_DIR/$name"
    if [ -L "$alias" ] &&
        [[ "$(readlink "$alias")" == "$PROFILE_DIR"/delta-*/bin/delta ]]; then
        rm "$alias"
    fi
done
hash -r

NEW_STABLE_VERSION="$(version_or_missing delta-stable)"
NEW_TRUNK_VERSION="$(version_or_missing delta)"

echo "==> Done"
if [ "$OLD_STABLE_VERSION" = "$NEW_STABLE_VERSION" ]; then
    echo "stable already on latest version: $NEW_STABLE_VERSION"
else
    echo "stable updated from $OLD_STABLE_VERSION to $NEW_STABLE_VERSION"
fi
if [ "$OLD_TRUNK_VERSION" = "$NEW_TRUNK_VERSION" ]; then
    echo "trunk already on latest version: $NEW_TRUNK_VERSION"
else
    echo "trunk updated from $OLD_TRUNK_VERSION to $NEW_TRUNK_VERSION"
fi

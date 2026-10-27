#!/usr/bin/env bash
# Checks out Zed at the rev Cargo.toml pins into vendor/zed (only what the shell builds from), and
# applies patches/*.patch to it. Cargo.toml's [patch] section builds GPUI from there. Only redone
# when the patches or the rev change, so GPUI isn't rebuilt needlessly.
#
# To change a patch: edit vendor/zed, then
#   git -C vendor/zed diff --no-ext-diff --no-color > patches/<name>.patch
set -euo pipefail
cd "$(dirname "$0")/.."

rev=$(grep -o 'zed-industries/zed", rev = "[0-9a-f]*"' Cargo.toml | head -1 | grep -o '[0-9a-f]\{40\}')
stamp="$rev $(cat patches/*.patch | sha256sum | cut -d' ' -f1)"
dir=vendor/zed
if [[ -f $dir/.myshell-stamp && $(cat "$dir/.myshell-stamp") == "$stamp" ]]; then
  exit 0
fi

# The workspace manifest the crates inherit from, the fonts GPUI embeds, and every crate
# Cargo.toml's [patch] section takes from here.
paths=(/Cargo.toml /assets/fonts/)
for crate in $(grep -o '"vendor/zed/[a-z_/]*"' Cargo.toml | tr -d '"'); do
  paths+=("${crate#vendor/zed}/")
done

if [[ ! -d $dir/.git ]]; then
  rm -rf "$dir"
  git init -q "$dir"
  git -C "$dir" remote add origin https://github.com/zed-industries/zed
fi
git -C "$dir" sparse-checkout set --no-cone "${paths[@]}"
if ! git -C "$dir" cat-file -e "$rev^{commit}" 2>/dev/null; then
  git -C "$dir" fetch -q --depth 1 --filter=blob:none origin "$rev"
fi
git -C "$dir" checkout -q --force --detach "$rev"
git -C "$dir" clean -qfdx
for patch in patches/*.patch; do
  [[ -s $patch ]] && git -C "$dir" apply "$PWD/$patch"
done
echo "$stamp" >"$dir/.myshell-stamp"

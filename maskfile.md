# System

## deploy (machine)

> Deploy a config to a remote machine

```sh
set -euo pipefail

git add -A
nixos-rebuild switch \
  --flake .#"$machine" \
  --target-host "cameron@$machine" \
  --sudo \
  --ask-sudo-password \
  "$@"
```

## switch

> Build a new config and switch to it

```sh
set -euo pipefail

git add -A
sudo nixos-rebuild switch --flake .#"$(hostname)" "$@"
```

## myshell

> The experimental GPUI Wayland shell

### myshell run

> Run the shell

```sh
set -euo pipefail
cd home/myshell

# Needs the myshell devshell for pkg-config deps and LD_LIBRARY_PATH (wayland/vulkan).
if [ -z "${MYSHELL_DEVSHELL:-}" ]; then
  exec nix develop ../..#myshell -c cargo run
fi
cargo run
```

### myshell fmt

> Format the shell (nightly rustfmt, needed for imports_granularity)

```sh
set -euo pipefail
cd home/myshell

cargo +nightly fmt
```

### myshell test

> Run the shell's tests

```sh
set -euo pipefail
cd home/myshell

if [ -z "${MYSHELL_DEVSHELL:-}" ]; then
  exec nix develop ../..#myshell -c cargo test
fi
cargo test
```

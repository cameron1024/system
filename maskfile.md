# System

## deploy (machine)

> Deploy a config to a remote machine

```sh
set -euo pipefail

git add -A
nixos-rebuild switch \
  --flake .#"$machine" \
  --target-host "cameron@$machine" \
  --use-remote-sudo \
  "$@"
```

## switch

> Build a new config and switch to it

```sh
set -euo pipefail

git add -A
sudo nixos-rebuild switch --flake .#"$(hostname)" "$@"
```

# System

## switch

> Build a new config and switch to it

```sh
set -euo pipefail

git add -A

if [ "$(uname)" == "Darwin" ]; then
  sudo nix run nix-darwin \
    --extra-experimental-features flakes \
    --extra-experimental-features nix-command \
    -- switch --flake . $@

  exit 0
fi

HOSTNAME=$(hostname)

case $HOSTNAME in
  "mini")
    sudo nixos-rebuild switch --flake .#mini $@
  ;;
  "thinkchad")
    sudo nixos-rebuild switch --flake .#thinkchad $@
  ;;
  *)
    # home-manager on non-nixos
    nix run home-manager/master -- --flake .#$(whoami)
  ;;
esac
```

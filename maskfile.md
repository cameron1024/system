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

### myshell run [cargo_args]

> Run the shell; pass additional Cargo arguments as one quoted string after `--`

**OPTIONS**
* release
    * flags: --release
    * desc: Build and run with optimizations
* release_fast
    * flags: --release-fast
    * desc: Optimize dependencies fully and shell code lightly for faster rebuilds

Examples: `mask myshell run --release-fast`, `mask myshell run --release`, `mask myshell run -- '--offline --features feature-name'`.

```python
import os
import shlex
import subprocess
from pathlib import Path

os.chdir(Path(os.environ["MASKFILE_DIR"]) / "home/myshell")
# GPUI is built from a local checkout with patches/*.patch applied.
subprocess.run(["patches/gpui.sh"], check=True)
command = ["cargo", "run"]
if os.environ.get("release_fast") == "true":
    if os.environ.get("release") == "true":
        raise SystemExit("Choose either --release or --release-fast, not both")
    command.extend(["--profile", "release-fast"])
elif os.environ.get("release") == "true":
    command.append("--release")
command.extend(shlex.split(os.environ.get("cargo_args", "")))
if not os.environ.get("MYSHELL_DEVSHELL"):
    command = ["nix", "develop", "../..#myshell", "-c", *command]
os.execvp(command[0], command)
```

### myshell fmt

> Format the shell (nightly rustfmt, needed for imports_granularity)

```sh
set -euo pipefail
cd home/myshell

cargo +nightly fmt
```

### myshell test [cargo_args]

> Run the shell's tests; pass additional Cargo arguments as one quoted string after `--`

**OPTIONS**
* release
    * flags: --release
    * desc: Build and test with optimizations
* release_fast
    * flags: --release-fast
    * desc: Optimize dependencies fully and shell code lightly for faster rebuilds

Examples: `mask myshell test --release-fast`, `mask myshell test --release`, `mask myshell test -- '--offline -- --nocapture'`.

```python
import os
import shlex
import subprocess
from pathlib import Path

os.chdir(Path(os.environ["MASKFILE_DIR"]) / "home/myshell")
# GPUI is built from a local checkout with patches/*.patch applied.
subprocess.run(["patches/gpui.sh"], check=True)
command = ["cargo", "test"]
if os.environ.get("release_fast") == "true":
    if os.environ.get("release") == "true":
        raise SystemExit("Choose either --release or --release-fast, not both")
    command.extend(["--profile", "release-fast"])
elif os.environ.get("release") == "true":
    command.append("--release")
command.extend(shlex.split(os.environ.get("cargo_args", "")))
if not os.environ.get("MYSHELL_DEVSHELL"):
    command = ["nix", "develop", "../..#myshell", "-c", *command]
os.execvp(command[0], command)
```

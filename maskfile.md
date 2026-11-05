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
from pathlib import Path

script = Path(os.environ["MASKFILE_DIR"]) / "home/myshell/dev.py"
os.execvp("python3", ["python3", str(script), "run"])
```

### myshell fmt

> Format the shell (nightly rustfmt, needed for imports_granularity)

```python
import os
from pathlib import Path

script = Path(os.environ["MASKFILE_DIR"]) / "home/myshell/dev.py"
os.execvp("python3", ["python3", str(script), "fmt"])
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
from pathlib import Path

script = Path(os.environ["MASKFILE_DIR"]) / "home/myshell/dev.py"
os.execvp("python3", ["python3", str(script), "test"])
```

### myshell restore

> Restore the managed shell after an interrupted development session

```sh
set -eu
python3 "$MASKFILE_DIR/home/myshell/dev.py" restore
```

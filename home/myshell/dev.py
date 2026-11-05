#!/usr/bin/env python3
"""Run development commands without competing with the managed shell."""

import fcntl
import os
from pathlib import Path
import shlex
import signal
import subprocess
import sys


UNIT = "myshell.service"


def systemctl(*args, **kwargs):
    return subprocess.run(["systemctl", "--user", *args], **kwargs)


def restore():
    systemctl("reset-failed", UNIT, check=True)
    systemctl("start", UNIT, check=True)


def main():
    action = sys.argv[1]
    if action == "restore":
        restore()
        return 0

    command = ["cargo", "+nightly", "fmt"] if action == "fmt" else ["cargo", action]
    if os.environ.get("release_fast") == "true":
        if os.environ.get("release") == "true":
            raise SystemExit("Choose either --release or --release-fast, not both")
        command.extend(["--profile", "release-fast"])
    elif os.environ.get("release") == "true":
        command.append("--release")
    command.extend(shlex.split(os.environ.get("cargo_args", "")))
    if action != "fmt" and not os.environ.get("MYSHELL_DEVSHELL"):
        command = ["nix", "develop", "../..#myshell", "-c", *command]

    os.chdir(Path(__file__).resolve().parent)
    # Serialize development sessions, so one cannot restore the service underneath another.
    lock_path = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / f"myshell-dev-{os.getuid()}.lock"
    with lock_path.open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        active = systemctl("is-active", "--quiet", UNIT).returncode == 0
        child = None

        def interrupted(signum, _frame):
            if child is not None:
                try:
                    os.killpg(child.pid, signum)
                except ProcessLookupError:
                    pass
            raise SystemExit(128 + signum)

        for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            signal.signal(sig, interrupted)
        try:
            if active:
                systemctl("stop", UNIT, check=True)
            commands = [command] if action == "fmt" else [["patches/gpui.sh"], command]
            for args in commands:
                child = subprocess.Popen(args, start_new_session=True)
                result = child.wait()
                child = None
                if result:
                    return result if result > 0 else 128 - result
            return 0
        finally:
            # Cleanup must not itself be interrupted by a second Ctrl-C.
            for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
                signal.signal(sig, signal.SIG_IGN)
            if child is not None:
                try:
                    os.killpg(child.pid, signal.SIGTERM)
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
                except ProcessLookupError:
                    child.wait()
            if active:
                restore()


if __name__ == "__main__":
    sys.exit(main())

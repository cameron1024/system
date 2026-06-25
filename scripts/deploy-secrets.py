#!/usr/bin/env python3
"""Copy subsets of secrets from the repo .env out to their destination env
files on remote hosts.

.env (matching .env.template) is the single source of truth for which secrets
exist and their values. Each service has its own helper that picks the keys it
needs and produces the file to deploy. Secret values are never printed.
"""

import argparse
import subprocess
import sys
import tempfile
from collections.abc import Callable, Sequence
from dataclasses import dataclass


@dataclass(frozen=True)
class Deployment:
    host: str
    path: str
    content: str
    needs_root: bool = False


# Parsed .env: env-var name -> value.
Source = dict[str, str]
# A per-service helper: given the parsed .env, produce one Deployment.
Service = Callable[[Source], Deployment]


def render(
    source: Source,
    keys: Sequence[str],
    rename: Callable[[str], str] = lambda key: key,
) -> str:
    """Render `KEY=value` lines for `keys`, optionally renaming each key."""
    missing = [key for key in keys if key not in source]
    if missing:
        raise KeyError(", ".join(missing))
    return "".join(f"{rename(key)}={source[key]}\n" for key in keys)


def homepage_dashboard(source: Source) -> Deployment:
    """Secrets for the homepage dashboard on mini."""
    keys = (
        "ROUTER_SSID",
        "ROUTER_WIFI_PASSWORD",
        "ROUTER_PASSWORD",
        "HOMEPAGE_HOME_ASSISTANT_KEY",
        "HOMEPAGE_JELLYFIN_KEY",
        "HOMEPAGE_IMMICH_KEY",
    )

    # homepage only substitutes {{...}} whose env var starts with HOMEPAGE_VAR_.
    # HOMEPAGE_* keys get that prefix; ROUTER_SSID / ROUTER_WIFI_PASSWORD are
    # read directly by the wifi-qr service so pass through unchanged; the shared
    # ROUTER_PASSWORD feeds the OpenWRT widget, so it's mapped to the prefixed
    # name homepage expects.
    def rename(key: str) -> str:
        if key == "ROUTER_PASSWORD":
            return "HOMEPAGE_VAR_ROUTER_PASSWORD"
        if key.startswith("HOMEPAGE_"):
            return key.replace("HOMEPAGE_", "HOMEPAGE_VAR_", 1)
        return key

    return Deployment(
        host="mini",
        path="/etc/homepage-dashboard/.env",
        content=render(source, keys, rename),
        needs_root=True,  # writing under /etc
    )


# One helper per service; add more as services are onboarded.
SERVICES: dict[str, Service] = {
    "homepage-dashboard": homepage_dashboard,
}


def parse_env(path: str) -> Source:
    """Parse a KEY=VALUE file into a dict (last occurrence wins)."""
    values: Source = {}
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.rstrip("\n")
            if not line or line.lstrip().startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            values[key.strip()] = value
    return values


def deploy(deployment: Deployment) -> None:
    """scp the rendered content into place with mode 600.

    Unprivileged steps (mktemp/scp/rm) run as the connecting user; only the
    final install is elevated with sudo when the target needs root. `-t`
    gives that sudo a TTY so it can prompt for the password.
    """
    with tempfile.NamedTemporaryFile("w", encoding="utf-8") as local:
        local.write(deployment.content)
        local.flush()
        remote_tmp = subprocess.run(
            ["ssh", deployment.host, "mktemp"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        install = ["install", "-D", "-m", "600", remote_tmp, deployment.path]
        try:
            subprocess.run(
                ["scp", "-q", local.name, f"{deployment.host}:{remote_tmp}"],
                check=True,
            )
            if deployment.needs_root:
                subprocess.run(
                    ["ssh", "-t", deployment.host, "sudo", *install],
                    check=True,
                )
            else:
                subprocess.run(
                    ["ssh", deployment.host, *install],
                    check=True,
                )
        finally:
            subprocess.run(
                ["ssh", deployment.host, "rm", "-f", remote_tmp],
                check=False,
            )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Deploy per-service secrets to remote env files.",
    )
    parser.add_argument(
        "--src", default=".env", help="source env file (default: .env)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="show what would be deployed without connecting",
    )
    parser.add_argument(
        "services",
        nargs="*",
        metavar="SERVICE",
        help=f"services to deploy (default: all of {', '.join(SERVICES)})",
    )
    args = parser.parse_args()

    unknown = [name for name in args.services if name not in SERVICES]
    if unknown:
        parser.error(f"unknown service(s): {', '.join(unknown)}")
    selected = args.services or list(SERVICES)

    try:
        source = parse_env(args.src)
    except FileNotFoundError:
        print(f"error: source env file not found: {args.src}", file=sys.stderr)
        return 1

    for name in selected:
        try:
            deployment = SERVICES[name](source)
        except KeyError as missing:
            print(
                f"error: service '{name}' needs key(s) {missing} "
                f"not present in {args.src}",
                file=sys.stderr,
            )
            return 1

        count = deployment.content.count("\n")
        dest = f"{deployment.host}:{deployment.path}"

        if args.dry_run:
            print(f"[{name}] would deploy {count} key(s) to {dest}")
            for line in deployment.content.splitlines():
                print(f"  {line.split('=', 1)[0]}=<redacted>")
            continue

        try:
            deploy(deployment)
        except subprocess.CalledProcessError as err:
            print(f"error: deploying '{name}' failed: {err}", file=sys.stderr)
            return 1
        print(f"[{name}] deployed {count} key(s) to {dest}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

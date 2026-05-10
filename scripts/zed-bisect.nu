#!/usr/bin/env nu

# zed-bisect: Binary search through Zed commits to find regressions.
# Only tests commits available in Zed's cachix binary cache,
# so you never have to wait for a full build from source.
#
# Usage:
#   zed-bisect path/to/project --good <commit> --bad <commit>

const ZED_REPO = "zed-industries/zed"
const CACHIX_URL = "https://zed.cachix.org"
const CACHIX_KEY = "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="

# Detect the nix system identifier (e.g. "x86_64-linux", "aarch64-darwin")
def nix_system []: nothing -> string {
  let arch = (^uname -m | str trim)
  let kernel = (^uname -s | str trim | str downcase)
  $"($arch)-($kernel)"
}

# Fetch the list of commits between `good` (older) and `bad` (newer) from GitHub.
# Returns them in chronological order (oldest first).
def fetch_commits [good: string, bad: string]: nothing -> list<record<sha: string, message: string>> {
  let url = $"https://api.github.com/repos/($ZED_REPO)/compare/($good)...($bad)"
  let resp = (http get --headers [Accept "application/vnd.github+json"] $url)

  if $resp.total_commits > 250 {
    print $"(ansi yellow_bold)warning:(ansi reset) ($resp.total_commits) commits in range but GitHub returns at most 250."
    print "Consider narrowing your range."
  }

  $resp.commits | each {|c|
    {
      sha: $c.sha
      message: ($c.commit.message | lines | first | str trim)
    }
  }
}

# Resolve the nix output path for a Zed commit, then check whether that
# path exists in Zed's cachix by hitting the narinfo endpoint.
def is_cached [rev: string]: nothing -> bool {
  let flake_ref = $"github:($ZED_REPO)/($rev)#packages.(nix_system).default"

  # Evaluate the derivation to learn its store path.
  # This downloads the flake source and evaluates -- no build happens.
  let eval = (
    do {
      ^nix eval --raw $"($flake_ref).outPath"
        --extra-substituters $CACHIX_URL
        --extra-trusted-public-keys $CACHIX_KEY
    } | complete
  )

  if $eval.exit_code != 0 {
    return false
  }

  # The store path looks like /nix/store/<hash>-zed-editor-X.Y.Z
  # Extract the hash and query the binary cache.
  let hash = ($eval.stdout | path basename | split row "-" | first)

  try {
    http head $"($CACHIX_URL)/($hash).narinfo" | ignore
    true
  } catch {
    false
  }
}

# Starting from `target`, search outward (±1, ±2, …) within [lo, hi],
# skipping indices in `skip_list`, and return the first index whose commit
# is present in cachix.  Returns -1 when nothing is found.
def find_cached_near [
  commits: list<record<sha: string, message: string>>
  target: int
  lo: int
  hi: int
  skip_list: list<int>
]: nothing -> int {
  mut offset = 0
  loop {
    let above = $target + $offset
    let below = $target - $offset

    # Both directions out of bounds → give up
    if $offset > 0 and $above > $hi and $below < $lo {
      return -1
    }

    if $above <= $hi and ($above not-in $skip_list) {
      let short = ($commits | get $above | get sha | str substring 0..8)
      print $"  checking ($short) …"
      if (is_cached ($commits | get $above | get sha)) {
        return $above
      }
    }

    if $offset > 0 and $below >= $lo and ($below not-in $skip_list) {
      let short = ($commits | get $below | get sha | str substring 0..8)
      print $"  checking ($short) …"
      if (is_cached ($commits | get $below | get sha)) {
        return $below
      }
    }

    $offset += 1
  }
}

# Prompt until the user gives a valid verdict.
def prompt_verdict []: nothing -> string {
  loop {
    let v = (
      input $"Is this commit (ansi green)[g]ood(ansi reset), (ansi red)[b]ad(ansi reset), or (ansi yellow)[s]kip(ansi reset)? "
      | str trim
      | str downcase
    )
    if $v in [g good b bad s skip] {
      return $v
    }
    print "Please enter g, b, or s."
  }
}

# Binary-search through Zed commits to find where a regression was introduced.
# Only commits with artefacts in Zed's cachix are tested, so no local builds
# are required.  The nix substituter arguments are passed on the CLI so the
# cache is used even without global configuration.
def main [
  project_path: path   # Directory to open in Zed for each test
  --good: string       # Older commit hash that is known to work
  --bad: string        # Newer commit hash where the bug is present
] {
  print $"(ansi cyan_bold)zed-bisect(ansi reset)"
  print $"  good    (ansi green)($good)(ansi reset)"
  print $"  bad     (ansi red)($bad)(ansi reset)"
  print $"  project ($project_path)\n"

  # ── Fetch commit list ──────────────────────────────────────────────
  print "Fetching commits from GitHub …"
  let commits = (fetch_commits $good $bad)
  let total = ($commits | length)

  if $total == 0 {
    print $"(ansi red)No commits found in range.(ansi reset) Make sure --good is older than --bad."
    return
  }

  print $"($total) commits in range\n"

  # ── Binary search ──────────────────────────────────────────────────
  mut lo = 0
  mut hi = ($total - 1)
  mut skipped: list<int> = []

  while $lo < $hi {
    let remaining = $hi - $lo + 1
    let mid = $lo + (($hi - $lo) / 2)

    print $"(ansi cyan)── ($remaining) commits left ──(ansi reset)"
    print "Looking for a cached commit near the midpoint …"

    let idx = (find_cached_near $commits $mid $lo $hi $skipped)
    if $idx == -1 {
      print $"(ansi red)No cached commits left in the current range – cannot continue.(ansi reset)"
      return
    }

    let commit = ($commits | get $idx)
    print $"\n  → testing (ansi white_bold)($commit.sha | str substring 0..8)(ansi reset)  ($commit.message)\n"

    # Launch Zed at this commit and wait for exit.
    # Download progress and Zed output stream to the terminal normally.
    print "  Downloading & launching Zed (close the window when done testing) …\n"
    try {
      ^nix run $"github:($ZED_REPO)/($commit.sha)"
        --extra-substituters $CACHIX_URL
        --extra-trusted-public-keys $CACHIX_KEY
        -- ($project_path | path expand | into string)
    } catch {|err|
      print $"(ansi yellow)Zed session ended with an error: ($err.msg)(ansi reset)"
    }

    print ""
    let verdict = (prompt_verdict)

    if $verdict in [g good] {
      print $"(ansi green)  ✓ marked good(ansi reset)\n"
      $lo = $idx + 1
    } else if $verdict in [b bad] {
      print $"(ansi red)  ✗ marked bad(ansi reset)\n"
      $hi = $idx
    } else {
      print $"(ansi yellow)  ⊘ skipped(ansi reset)\n"
      $skipped = ($skipped | append $idx)
    }
  }

  # ── Report result ──────────────────────────────────────────────────
  if $lo >= $total {
    print "All tested commits were good.  The regression may live in a commit that is not cached."
    return
  }

  let first_bad = ($commits | get $lo)
  print $"(ansi cyan)════════════════════════════════════════════════════════════(ansi reset)"
  print $"(ansi red_bold)First bad commit:(ansi reset)"
  print $"  (ansi white_bold)($first_bad.sha)(ansi reset)"
  print $"  ($first_bad.message)"
  print $"  https://github.com/($ZED_REPO)/commit/($first_bad.sha)"
  print $"(ansi cyan)════════════════════════════════════════════════════════════(ansi reset)"
}

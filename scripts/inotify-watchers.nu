#!/usr/bin/env nu

# Report inotify file-watcher usage per program.
#
# Works by finding every open inotify fd (/proc/<pid>/fd/* -> anon_inode:inotify)
# and counting the "inotify wd:" lines in the matching /proc/<pid>/fdinfo/<fd>.
#
# Notes:
# - You can only inspect processes you own; run with `sudo` for a system-wide view.
# - fs.inotify.max_user_watches / max_user_instances are per-UID limits, not
#   truly global, so compare the totals against the limit for the relevant user.

def main [
    --top: int = 10  # how many programs to show
] {
    # Every open inotify fd, as {pid, fd}
    let fds = (
        do { ^find /proc -maxdepth 3 -path '/proc/[0-9]*/fd/*' -lname 'anon_inode:inotify' }
        | complete
        | get stdout
        | lines
        | parse "/proc/{pid}/fd/{fd}"
    )

    # One row per inotify instance: {pid, program, exe, parent, watches}
    let instances = ($fds | each {|row|
        let watches = (try {
            open --raw $"/proc/($row.pid)/fdinfo/($row.fd)"
            | lines
            | where {|l| $l starts-with "inotify wd:"}
            | length
        } catch { 0 })
        let program = (try {
            open --raw $"/proc/($row.pid)/comm" | str trim
        } catch { "<gone>" })
        # Real binary path: catches processes whose comm was renamed by a thread
        let exe = (try {
            ^readlink $"/proc/($row.pid)/exe"
        } catch { "?" })
        let ppid = (try {
            open --raw $"/proc/($row.pid)/status"
            | lines
            | where {|l| $l starts-with "PPid:"}
            | first
            | parse "PPid:\t{ppid}"
            | get 0.ppid
        } catch { "?" })
        let parent = (try {
            (open --raw $"/proc/($ppid)/comm" | str trim) + $"(char lparen)($ppid)(char rparen)"
        } catch { $"?(char lparen)($ppid)(char rparen)" })
        {pid: $row.pid, program: $program, exe: $exe, parent: $parent, watches: $watches}
    })

    let total_watchers = ($instances | get watches | math sum)
    let max_watches = (^sysctl -n fs.inotify.max_user_watches | into int)
    let max_instances = (^sysctl -n fs.inotify.max_user_instances | into int)

    let by_program = (
        $instances
        | group-by program
        | items {|program, rows| {
            program: $program
            processes: ($rows | get pid | uniq | length)
            instances: ($rows | length)
            watchers: ($rows | get watches | math sum)
            max_per_instance: ($rows | get watches | math max)
            pct_of_limit: (($rows | get watches | math sum) * 100.0 / $max_watches | math round --precision 2)
            parents: ($rows | get parent | uniq | str join ", ")
            exe: ($rows | get exe | uniq | str join ", ")
        }}
        | sort-by --reverse watchers
        | first $top
    )

    print $by_program
    print {
        total_watchers: $total_watchers
        max_user_watches: $max_watches
        watcher_usage_pct: ($total_watchers * 100.0 / $max_watches | math round --precision 2)
        total_instances: ($instances | length)
        max_user_instances: $max_instances
    }
}

#!/usr/bin/env nu

def main [package: string] {
    nix flake update $package

    let lock = (open flake.lock | from json)
    let package_node_name = ($lock.nodes.root.inputs | get $package)
    let package_locked = ($lock.nodes | get $package_node_name | get locked)

    let upstream_lock = (
        http get $"https://raw.githubusercontent.com/($package_locked.owner)/($package_locked.repo)/($package_locked.rev)/flake.lock"
        | from json
    )

    for input_name in ($upstream_lock.nodes.root.inputs | columns) {
        let node_ref = ($upstream_lock.nodes.root.inputs | get $input_name)
        if ($node_ref | describe) != "string" { continue }

        let locked = ($upstream_lock.nodes | get $node_ref | get locked)
        if $locked.type != "github" { continue }

        nix flake lock --override-input $"($package)/($input_name)" $"github:($locked.owner)/($locked.repo)/($locked.rev)"
    }
}

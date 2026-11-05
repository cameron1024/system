# myshell

Custom Wayland shell environment

Do not make a readme

## Useful commands:

- `mask myshell run` - `cargo run` with the correct environment
- `mask myshell test` - `cargo test` with the correct environment
- `mask myshell fmt` - `cargo fmt` with the correct nightly rustfmt

GPUI is built from `vendor/zed` (gitignored): `patches/gpui.sh` checks out the pinned rev and applies `patches/*.patch`, and the run/test commands run it first. Edit GPUI there, then regenerate the patch (see the script).

## Goals (in order)

- Low idle resource consumption (CPU, RAM, battery, etc.)
  - "idle" in this context means "the user is not directly interacting with it"
- Pretty UI/animations
- Low resource consumption when in use
  - I am aware that animations will increase battery drain
- Simple, minimal code. The fewer lines, the better, unless this comes at the cost of readability
  - Code must also be formatted with rustfmt
- Tests only where clearly helpful
  - if a test is checking something which would be instantly noticed when running the shell, it probably doesn't need to exist. I will be running this continuously and will notice when things go wrong
  - you may create temporary tests when experimenting, mark them with `#[test] // temporary` and clean them up afterwards


## Nix

It is safe to assume this project will never be built without nix. This means it's safe to hardcode dependencies injected via env vars, which can be set in a devshell/nix build environment.

## Design

The shell should be all of the following:
- simple
- functional
- elegant

This applies to UI design, layout, animations, UX patterns, and more. Assume the user is paying attention, and has good reaction times.

Some specific realisations of these principles:
- simple:
  - the UI uses a simple transparent blur effect, rather than a liquid-glass-like shader
  - icons are used instead of text, where the meaning is obvious
- functional:
  - animations should be fast, and *non-blocking*
    - "fast" means "less than 300ms, likely even faster than that"
    - "non-blocking" means that, once the user has taken an action that changes the UI state in a way that triggers an animation, the "new state" should be interactible immediately". In other words, the user should never have to wait for an animation to finish
  - layout shift is evil - UI elements should move *when a user tells them to move*, and should avoid moving in any other circumstances. Sometimes this is not always possible, but it's a goal. A good example is the notification hover UI. It is specifically designed so that, when a notification appears and it is hovered, it does not move as the full notification shade appears.
- elegant:
  - state transitions are animated - for example, the performance profile switcher
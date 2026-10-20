# myshell

Custom Wayland shell environment

Do not make a readme

## Useful commands:

- `mask myshell run` - `cargo run` with the correct environment
- `mask myshell test` - `cargo test` with the correct environment
- `mask myshell fmt` - `cargo fmt` with the correct nightly rustfmt

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


Since low idle resource consumption is the highest priority, I want to stress the importance of usin

## Nix

It is safe to assume this project will never be built without nix. This means it's safe to hardcode dependencies injected via env vars, which can be set in a devshell/nix build environment.


{
  fetchFromGitHub,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "otter-launcher";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "cameron1024";
    repo = "otter-launcher";
    rev = "52deac079c1c9781730bc96d75cee0b631b6bd23";
    hash = "sha256-eZgPUlrKa0sNdSKGlT63bzOHk16toBp5ImJzx9zrwA0=";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";
}

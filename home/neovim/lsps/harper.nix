{
  rustPlatform,
  fetchFromGitHub,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "harper";
  version = "v0.9.0";

  src = fetchFromGitHub {
    owner = "elijah-potter";
    repo = pname;
    rev = version;
    hash = "sha256-LPDs+PUgHzrAT6Y3+YyA0FDbqyc31+cZR5v262kFxRI=";
  };

  cargoHash = "sha256-YIjrAbleyLbAnMmJo/PMTI9a0ofRxSrN8Bops1sJDUs=";
}

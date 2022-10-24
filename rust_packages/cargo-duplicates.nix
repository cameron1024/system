{ pkgs }:
pkgs.rustPlatform.buildRustPackage {
  pname = "cargo-duplicates";
  version = "0.5.1";
  src = pkgs.fetchFromGitHub {
    owner = "Keruspe";
    repo = "cargo-duplicates";
    rev = "5207b01eda50b448eb6910c65a96d769ae54c8c5";
    sha256 = "sha256-7SohH4fQV+ALMnZbCgnemgLKgko0/s/K3j+SLP+VO00=";
  };
  cargoSha256 = "sha256-i1IyHCa/w4DOGlPWjDE4IbVm3s/40DIwjwUGIMTYH4Y=";

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ];
}

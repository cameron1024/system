{ pkgs }:

pkgs.rustPlatform.buildRustPackage {
  pname = "erdtree";
  version = "1.7.1";
  src = pkgs.fetchFromGitHub {
    owner = "solidiquis";
    repo = "erdtree";
    rev = "4b28a2baf6bd9995c2f9f94149d331b9f9b404a0";
    sha256 = "sha256-dSIq6PNkFkdYvAzNQ1qBEZWEdiYYZCb/7rNICuUJAsE=";
  };
  cargoSha256 = "sha256-Dpg4AbDClqh6yzI/s5LQDP6QkyTMLP/IJIp2l2d+Ouw=";
}

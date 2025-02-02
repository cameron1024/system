{
  rustPlatform,
  fetchFromGitHub,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "iwe";
  version = "0.0.14";

  src = fetchFromGitHub {
    owner = "iwe-org";
    repo = pname;
    rev = "e76b8fd723611e2b8a8e4dd21ecea8313bb7e344";
    hash = "sha256-VHmPhl7IzRvQFrWMJ0bn2eR01CXSS0T96HTH2f6IhxI=";
  };

  cargoHash = "sha256-dFpMVlVB1+9aZPpTSXJLKsggVaARj1lLyZ+LckqYYfg=";
}

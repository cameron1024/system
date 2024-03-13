{
  naersk,
  lib,
  isDarwin,
  ...
}: let
  packages = ["cams-home-utilities" "device-manager"];

  build = pname:
    naersk.buildPackage {
      inherit pname;
      src = ./.;
    };
in {
  environment.systemPackages = lib.mkIf (!isDarwin) (map build packages);
}

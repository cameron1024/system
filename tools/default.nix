{ naersk, ... }:

let
  packages = [ "cams-home-utilities" "device-manager" ];

  build = pname: naersk.buildPackage {
    inherit pname; 
    src = ./.;
  };
in

{
  environment.systemPackages = map build packages;
}

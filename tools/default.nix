{ naersk, ... }:

let
  packages = [ "cams-home-utilities" ];

  build = pname: naersk.buildPackage {
    inherit pname; 
    src = ./.;
  };
in

{
  environment.systemPackages = map build packages;
}

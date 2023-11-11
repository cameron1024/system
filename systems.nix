{ nixos-hardware }:

{
  thinkpad = {
    specialArgs = {
      hardware = nixos-hardware.nixosModules.thinkpad;

      username = "cameron";
      gitName = "Cameron";
      email = "cameron.studdstreet@gmail.com";
    };
  };

  macbook = {

  };
}

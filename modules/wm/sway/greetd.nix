{ pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "sway";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    sway
    fish
  '';
}

{ pkgs, ... }:

let
  laptopScreen = { criteria = "eDP-1"; };
  benq = { criteria = "BNQ BenQ PD2700U ETD6L00692SL0"; transform = "90"; };
  lg = { criteria = "LG Electronics LG SDQHD 204NTDVCE898"; position = "2160,0"; };
in
{

  environment.systemPackages = [ pkgs.kanshi ];

  home-manager.users.cameron = {

    services.kanshi.enable = true;
    services.kanshi.profiles = {
      undocked = {
        outputs = [ laptopScreen ];
      };
      dockedClosed = {
        outputs = [
          benq
          lg
        ];
      };
      dockedOpen = {
        outputs = [
          (laptopScreen // { position = "2160,2880"; })
          benq
          lg
        ];
      };
    };
  };

}

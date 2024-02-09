{ linuxArgs, macArgs }:

let
  allDisplays = import ./displays.nix;
in

rec {
  shared = {
    username = "cameron";
    realName = "Cameron";
    email = "cameron.studdstreet@gmail.com";

    fonts = {
      normal = "Fira Sans";
      monospace = "Fira Code NerdFont";
    };
  };

  macos = shared // {
    naersk = macArgs.naersk;
    isDarwin = true;
    headless = false;
    laptop = true;
  };

  mini = shared // {
    hardware = import ./hardware/mini.nix;
    naersk = linuxArgs.naersk;
    isDarwin = false;
    headless = false;
    laptop = false; 
    hyprland = true;
    hostname = "teeny";
    boot = "/boot";
    displays = with allDisplays; [ benq lg ];
  };

  thinkpad = shared // {
    hardware = import ./hardware/thinkpad.nix;
    naersk = linuxArgs.naersk;
    isDarwin = false;
    headless = false;
    laptop = true;
    hyprland = true;
    hostname = "thinkchad";
    boot = "/boot/efi";
    displays = with allDisplays; [ thinkpadBuiltin ];
  };

  server = shared // {
    
  };

}

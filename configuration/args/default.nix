{
  linuxArgs,
  macArgs,
}: let
  allDisplays = import ./displays.nix;
in rec {
  shared = {
    username = "cameron";
    realName = "Cameron";
    email = "cameron.studdstreet@gmail.com";

    fonts = {
      normal = "Fira Sans";
      monospace = "Fira Code NerdFont";
    };
  };

  macos =
    shared
    // {
      naersk = macArgs.naersk;
      crane = macArgs.crane;
      isDarwin = true;
      headless = false;
      laptop = true;
    };

  mini =
    shared
    // {
      hardware = import ./hardware/mini.nix;
      naersk = linuxArgs.naersk;
      crane = linuxArgs.crane;
      isDarwin = false;
      headless = false;
      laptop = false;
      hyprland = true;
      hostname = "teeny";
      boot = "/boot";
      displays = with allDisplays; [benq lg];
      swapDevices = [
        {
          device = "/var/swap";
          size = 32 * 1024;
        }
      ];
    };

  thinkpad =
    shared
    // {
      hardware = import ./hardware/thinkpad.nix;
      naersk = linuxArgs.naersk;
      crane = linuxArgs.crane;
      isDarwin = false;
      headless = false;
      laptop = true;
      hyprland = true;
      hostname = "thinkchad";
      boot = "/boot/efi";
      displays = with allDisplays; [thinkpadBuiltin];
      swapDevices = [];
    };

  thinkpad2 =
    shared
    // {
      hardware = import ./hardware/thinkpad2.nix;
      naersk = linuxArgs.naersk;
      crane = linuxArgs.crane;
      isDarwin = false;
      headless = false;
      laptop = true;
      hyprland = true;
      hostname = "thinkchad";
      boot = "/boot";
      displays = with allDisplays; [thinkpad2Builtin];
      swapDevices = [];
    };

  server =
    shared
    // {
      naersk = linuxArgs.naersk;
      crane = linuxArgs.crane;
      isDarwin = false;
      headless = true;
      laptop = false;
      hyprland = false;
    };
}

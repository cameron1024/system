{ linuxArgs, macArgs }:

rec {
  shared = {
    username = "cameron";
  };

  mini = shared // {
    hardware = import ./hardware/mini.nix;
    naersk = linuxArgs.naersk;
    isDarwin = false;
    laptop = false; 
    hyprland = true;
    boot = "/boot";
  };

  thinkpad = shared // {
    hardware = import ./hardware/thinkpad.nix;
    naersk = linuxArgs.naersk;
    isDarwin = false;
    laptop = true;
    hyprland = false;
    boot = "/boot/efi";
  };

  macos = shared // {
    naersk = macArgs.naersk;
    isDarwin = true;
  };
}

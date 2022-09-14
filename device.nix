{ pkgs }:

with pkgs;

let
  machines = {
    razer = {
      fontSize = 12;
    };
    thinkpad = {
      fontSize = 9.5;
    };
  };

  currentDevice = lib.removeSuffix "\n" (builtins.readFile /home/cameron/.device);
in

machines.${currentDevice} // { name = currentDevice; }

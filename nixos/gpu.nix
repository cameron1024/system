{
  pkgs,
  config,
  lib,
  ...
}: let
  isAmd = config.machine.cpuArch == "znver5";
in {
  config = lib.mkIf isAmd {
    services.ollama.rocmOverrideGfx = "11.0.2";
    services.ollama.acceleration = "rocm";

    hardware.opengl.enable = true;
    hardware.opengl.extraPackages = with pkgs.rocmPackages; [clr clr.icd];

    environment.systemPackages = with pkgs; [
      rocmPackages.rocminfo
      clinfo
    ];

    # hardware.amdgpu.opencl.enable = true;
    # hardware.amdgpu.amdvlk.enable = true;
  };
}

{
  machine,
  lib,
  ...
}: let
  isAmd = machine.cpuArch == "znver5";
in {
  # config = lib.mkIf isAmd {
  #   hardware.amdgpu.opencl.enable = true;
  #   hardware.amdgpu.amdvlk.enable = true;
  # };
}

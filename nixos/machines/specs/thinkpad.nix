{inputs}: {
  hostname = "thinkchad";
  boot = "/boot";
  cpuArch = "alderlake";

  linux = true;
  wm.hyprland.enable = true;

  user = (import ../users.nix).cameron;
  colorscheme = (import ../colors.nix).everforest;
  displays = [
    (import ../displays.nix).thinkpadBuiltin
  ];
  wallpapers = with (import ../wallpapers.nix); [
    everforest
    leaves
    mistForest
    forestBridge
    forestFromSky
  ];

  # extraFirmware = pkgs: [
  #   (
  #     let
  #       model = "37xx";
  #       version = "0.0";
  #
  #       firmware = pkgs.fetchurl {
  #         url = "https://github.com/intel/linux-npu-driver/raw/v1.2.0/firmware/bin/vpu_${model}_v${version}.bin";
  #         hash = "sha256-qGhLLiBnOlmF/BEIGC7DEPjfgdLCaMe7mWEtM9uK1mo=";
  #       };
  #     in
  #       pkgs.runCommand "intel-vpu-firmware-${model}-${version}" {} ''
  #         mkdir -p "$out/lib/firmware/intel/vpu"
  #         cp '${firmware}' "$out/lib/firmware/intel/vpu/vpu_${model}_v${version}.bin"
  #       ''
  #   )
  # ];
}

{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options = {
    gpu'.arch = mkOption {
      type = types.nullOr (types.enum ["zen5" "intel"]);
      default = null;
    };
  };

  config = lib.mkMerge [
    {
      hardware.graphics.enable = true;
    }

    (lib.mkIf (config.gpu'.arch == "zen5") {
      services.ollama.rocmOverrideGfx = "11.0.2";
      services.ollama.acceleration = "rocm";

      hardware.graphics.extraPackages = with pkgs.rocmPackages; [clr clr.icd];

      environment.systemPackages = with pkgs; [
        rocmPackages.rocminfo
        clinfo
      ];
    })

    (lib.mkIf (config.gpu'.arch == "intel") {
      hardware.intel-gpu-tools.enable = true;
    })
  ];
}

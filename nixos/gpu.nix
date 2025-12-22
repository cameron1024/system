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
    # All GPUs
    {
      hardware.graphics.enable = true;
      environment.systemPackages = with pkgs; [
        vulkan-tools
        clinfo
      ];
    }

    # AMD GPUs
    (lib.mkIf (config.gpu'.arch == "zen5") {
      nixpkgs.config.rocmSupport = true;

      hardware.graphics.extraPackages = with pkgs.rocmPackages; [clr clr.icd];

      environment.systemPackages = with pkgs; [
        rocmPackages.rocminfo
      ];

      environment.variables = {
        RUSTICL_ENABLE = "radeonsi";
        ROC_ENABLE_PRE_VEGA = "1";
      };

      services.ollama.rocmOverrideGfx = "11.0.2";
      services.ollama.package = pkgs.ollama-rocm;
    })

    # Intel GPUs
    (lib.mkIf (config.gpu'.arch == "intel") {
      hardware.intel-gpu-tools.enable = true;
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
        vpl-gpu-rt
      ];

      nixpkgs.config.packageOverrides = pkgs: {
        intel-vaapi-driver = pkgs.intel-vaapi-driver.override {
          enableHybridCodec = true;
        };
      };
    })
  ];
}

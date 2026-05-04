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

    platform'.rocm.enable = mkOption {
      type = types.bool;
      default = config.gpu'.arch == "zen5";
      description = "Enable ROCm support for AMD GPUs. Defaults to true when gpu arch is zen5.";
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
      hardware.graphics.extraPackages = with pkgs.rocmPackages; [clr clr.icd];

      environment.systemPackages = with pkgs; [
        rocmPackages.rocminfo
      ];

      environment.variables = {
        RUSTICL_ENABLE = "radeonsi";
        ROC_ENABLE_PRE_VEGA = "1";
      };

      services.ollama.rocmOverrideGfx = "11.0.2";
    })

    # ROCm GPU compute (targeted per-package, not global)
    (lib.mkIf config.platform'.rocm.enable {
      nixpkgs.overlays = [
        (final: prev: {
          llama-cpp = prev.llama-cpp.override { rocmSupport = true; };
          ollama = prev.ollama.override { acceleration = "rocm"; };
        })
      ];
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

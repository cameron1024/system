{
  pkgs,
  naersk,
  ...
}: let
  recent-inlyne = naersk.buildPackage {
    src = pkgs.fetchFromGitHub {
      owner = "Inlyne-Project";
      repo = "inlyne";
      rev = "15e7d498c6c1c952b05e66714def307e1a45e5d7";
      hash = "sha256-Je0y4Af6ys4EifKXw4D9y200G0nOwr84/XMmF2AWu5c=";
    };

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      fontconfig
      openssl
      wayland

      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      xorg.libxcb
      libxkbcommon
    ];

    cargoBuildOptions = opts:
      opts
      ++ [
        "--no-default-features"
        "--features"
        "wayland"
      ];
  };
in {
  home.packages = [pkgs.inlyne];
  xdg.configFile."inlyne/inlyne.toml".text = ''
    theme = "Dark"

    [font-options]
    regular-font = "Fira Sans"
    monospace-font = "FiraCode Nerd Font"
  '';
}

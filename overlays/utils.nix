final: prev: {
  zmk-studio = final.callPackage ./packages/zmk-studio.nix {};
  euphonica = final.callPackage ./packages/euphonica.nix {};
  material-rounded = final.callPackage ./packages/material-rounded.nix {};
  proton-pass-cli = final.callPackage ./packages/pass-cli.nix {};

  # Fix: upstream nixpkgs package doesn't actually build the theme, it just copies source files
  everforest-gtk-theme = prev.everforest-gtk-theme.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [final.sassc];

    dontBuild = false;

    buildPhase = ''
      runHook preBuild
      cd themes
      bash install.sh -n Everforest -d "$TMPDIR/themes" -c light dark -t all
      cd ..
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/"{themes,icons}
      cp -a icons/* "$out/share/icons/"
      cp -a "$TMPDIR/themes/"* "$out/share/themes/"
      runHook postInstall
    '';
  });

  wrapWithNixGL = {
    name,
    package ? null,
  }: let
    realPackage =
      if package == null
      then final.${name}
      else package;
  in
    final.writeShellScriptBin name ''
      ${final.nixgl.nixGLIntel}/bin/nixGLIntel ${realPackage}/bin/${name} "$@"
    '';

  cams-utils = {
    hyprland = {
      mkColor = hex: "rgb(${prev.lib.strings.removePrefix "#" hex})";
    };
  };

  vimPlugins =
    prev.vimPlugins
    // {
      goose = prev.vimUtils.buildVimPlugin {
        pname = "goose";
        version = "0.0.0";
        src = prev.fetchFromGitHub {
          owner = "azorng";
          repo = "goose.nvim";
          rev = "5a72d3b3f7a2a01d174100c8c294da8cd3a2aeeb";
          hash = "sha256-jVWggPmdINFNVHJSCpbTZq8wKwGjldu6PNSkb7naiQE=";
        };
      };

      obsidian-nvim = prev.vimUtils.buildVimPlugin {
        pname = "obsidian.nvim";
        version = "3.11.0";
        src = prev.fetchFromGitHub {
          owner = "obsidian-nvim";
          repo = "obsidian.nvim";
          rev = "d6b996733e76549dbbf4741c16640caead1dc8e0";
          hash = "";
        };
      };
      magenta = prev.vimUtils.buildVimPlugin {
        pname = "magenta.nvim";
        version = "0.0.0";
        src = prev.fetchFromGitHub {
          owner = "dlants";
          repo = "magenta.nvim";
          rev = "53051e64e7021e1e983a6c771badca377dc0c94a";
          hash = "sha256-ugVqYxBEsrD/jInG0ecSKGaa37M4AimYEsr8NEyt9tA=";
        };
      };

      mdx = prev.vimUtils.buildVimPlugin {
        pname = "mdx.nvim";
        version = "0.0.0";
        src = prev.fetchFromGitHub {
          owner = "davidmh";
          repo = "mdx.nvim";
          rev = "464a74be368dce212cff02f6305845dc7f209ab3";
          hash = "sha256-jpMcrWx/Rg9sMfkQFXnIM8VB5qRuSB/70wuSh6Y5uFk=";
        };
      };

      lean-nvim = prev.vimPlugins.lean-nvim.overrideAttrs {
        version = "0.0.0";
        src = prev.fetchFromGitHub {
          owner = "Julian";
          repo = "lean.nvim";
          rev = "68ad9a01b7da30213441016667ad3f946d080fe8";
          hash = "sha256-FfYfDPQi0MUPnUV1bcHP7cpHdUkqcH9lHZS8ZNpWCso=";
        };
      };


    };

  wayscriber = prev.rustPlatform.buildRustPackage rec {
    name = "wayscriber";
    version = "0.0.0";
    src = prev.fetchFromGitHub {
      owner = "devmobasa";
      repo = "wayscriber";
      rev = "a7c5e488b8a58ce3abfc9d9f2214e51f47cc2c56";
      hash = "sha256-whYrvShYBUdhSlFaWV07K/FGWxYGBySlxw06fEfutag=";
    };
    cargoLock.lockFile = "${src}/Cargo.lock";

    nativeBuildInputs = with prev; [
      pkg-config
    ];

    buildInputs = with prev; [
      libxkbcommon
      glib
      cairo
      pango
    ];
  };

  writeShellScriptNu = name: script: let
    scriptFile = final.writeText "script.nu" script;
  in
    final.writeShellScriptBin name "${final.nushell}/bin/nu${scriptFile}\n";

  home-assistant-custom-components =
    prev.home-assistant-custom-components
    // {
      dreo = final.callPackage ./packages/dreo-hass.nix {};
    };

  josefin = final.callPackage ./packages/josefin-sans.nix {};
}

final: prev: {
  fetchDrive = {
    id,
    hash,
  }: pkgs:
    pkgs.fetchurl {
      inherit hash;
      url = "https://drive.usercontent.google.com/download?id=${id}";
    };

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

  everforest-collection = prev.fetchFromGitHub {
    owner = "neuromaancer";
    repo = "everforest_collection";
    rev = "88ef139be4f2b75fc640619fd2ac0176b60037b6";
    hash = "sha256-WuVh8kvLLJjnWqcPgAtKT8567o46/xE+0xOrPVIlaYY=";
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
    };

  writeShellScriptNu = name: script: let
    scriptFile = final.writeText "script.nu" script;
  in
    final.writeShellScriptBin name "${final.nushell}/bin/nu ${scriptFile}\n";

  # everforest-gtk = prev.callPackage ./packages/everforest-gtk.nix {};
}

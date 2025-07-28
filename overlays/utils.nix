final: prev: {
  zmk-studio = final.callPackage ./packages/zmk-studio.nix {};
  euphonica = final.callPackage ./packages/euphonica.nix {};
  
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


    };

  writeShellScriptNu = name: script: let
    scriptFile = final.writeText "script.nu" script;
  in
    final.writeShellScriptBin name "${final.nushell}/bin/nu ${scriptFile}\n";

}

{ pkgs, ...}:
let
  flutter-tools = pkgs.vimUtils.buildVimPlugin {
  pname = "flutter-tools";
  version = "0.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "akinsho";
    repo = "flutter-tools.nvim";
    rev = "b666a057108c7655882cbc64217222228aad68da";
    sha256 = "sha256-/9+6znJ5YA/yTNp5nZlusG5+FF4Ogz0QluuPbdmtX1Q=";
  };
};
in
{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = flutter-tools;
      config =''
      lua << EOF
      ${builtins.readFile ./config.lua}
      EOF
      '';
    }
  ];
}

{pkgs, ...}: {
  extraPlugins = [
    # (pkgs.vimUtils.buildVimPlugin {
    #   name = "vim-raku";                   
    #   src = pkgs.fetchFromGitHub {     
    #     owner = "Raku";
    #     repo = "vim-raku";
    #     rev = "84a65c415f966c3cd5536fdbc6d70ee8f0d73508";
    #   };                  
    # })
  ];
}

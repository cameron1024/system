{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    shellWrapperName = "y";
    settings = {
      opener = {
        text = [
          {
            run = ''nvim "$@"'';
            block = true;
          }
        ];
      };
    };
  };
}

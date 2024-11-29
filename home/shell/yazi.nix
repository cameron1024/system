{
  programs.yazi = {
    # enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
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

  home.shellAliases = {
    "f" = "yazi";
  };
}

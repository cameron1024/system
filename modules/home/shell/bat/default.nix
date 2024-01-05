{
  programs.bat = {
    enable = true;
  };

  programs.nushell = {
    shellAliases = {
      cat = "bat";
    };
  };
}

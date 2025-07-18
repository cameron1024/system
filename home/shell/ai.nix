{pkgs, ...}: {
  home.packages = [pkgs.opencode];
  xdg.configFile."opencode/.opencode.json".text = /* json */ ''
    {
      "autoCompact": true,
      "agents": {
        "coder": {
          "model": "local.devstral-small-2505",
        }
      }
    }
  '';
}

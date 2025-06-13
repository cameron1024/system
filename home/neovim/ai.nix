{pkgs, ...}: {
  home.packages = [pkgs.goose-cli];
  programs.nixvim = {
    plugins.avante.enable = true;
    plugins.avante.settings = {
      provider = "ollama" ;
      providers.ollama = {
        endpoint = "http://mini:11434";
        model = "qwen2.5";
      };
    };
  };
}

{
  programs.nixvim = {
    plugins.codecompanion = {
      enable = true;
      settings = {
        strategies = {
          chat.adapter = "ollama";
          inline.adapter = "ollama";
          cmd.adapter = "ollama";

          # adapters.ollama.__raw = ''
          #   function()
          #     require "codecompanion.adapters".extend("ollama", {
          #       schema = { model = { default = "qwen2.5-coder:7b" } }
          #     })
          #   end
          # '';
        };
      };
    };
  };
}

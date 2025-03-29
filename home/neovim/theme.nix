{
  programs.nixvim = {
    colorscheme = "everforest";
    colorschemes.everforest.enable = true;

    opts.winborder = "rounded";

    plugins.web-devicons.enable = true;
    plugins.web-devicons.lazyLoad.enable = true;
    plugins.web-devicons.lazyLoad.settings.events = ["BufReadPost"];
    plugins.lualine = {
        enable = true;
        lazyLoad.enable = true;
        lazyLoad.settings.event = "BufReadPost";
        luaConfig.post = /* lua */ ''
          if vim.g.started_by_firenvim == true then
            vim.o.laststatus = 0
          else
            vim.o.laststatus = 3
          end
        '';
    };

    extraConfigVim = ''
        autocmd TextYankPost * silent! lua vim.hl.on_yank {higroup='IncSearch', timeout=300}
    '';
  };
}

let
  lualineMacro = {
    __raw = ''
      function()
        local reg = vim.fn.reg_recording()
        if reg == "" then return "" end
        return "M[" .. reg .. "]"
      end
    '';
  };
  lualineModes = {
    __raw = ''
      function()
        local mode_map = {
          ["n"] = "N",
          ["no"] = "O·P",
          ["nov"] = "O·P",
          ["noV"] = "O·P",
          ["no\22"] = "O·P",
          ["niI"] = "N·I",
          ["niR"] = "N·R",
          ["niV"] = "N",
          ["nt"] = "N·T",
          ["v"] = "V",
          ["vs"] = "V",
          ["V"] = "V·L",
          ["Vs"] = "V·L",
          ["\22"] = "V·B",
          ["\22s"] = "V·B",
          ["s"] = "S",
          ["S"] = "S·L",
          ["\19"] = "S·B",
          ["i"] = "I",
          ["ic"] = "I·C",
          ["ix"] = "I·X",
          ["R"] = "R",
          ["Rc"] = "R·C",
          ["Rx"] = "R·X",
          ["Rv"] = "V·R",
          ["Rvc"] = "RVC",
          ["Rvx"] = "RVX",
          ["c"] = "C",
          ["cv"] = "EX",
          ["ce"] = "EX",
          ["r"] = "R",
          ["rm"] = "M",
          ["r?"] = "C",
          ["!"] = "SH",
          ["t"] = "T",
        }

        return mode_map[vim.api.nvim_get_mode().mode] or "__"
      end
    '';
  };
  simpleConfig = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.event = "BufEnter";
  };
in {
  programs.nixvim = {
    colorscheme = "everforest";
    colorschemes.everforest.enable = true;

    plugins.web-devicons = simpleConfig;

    plugins.lualine = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.event = "BufReadPost";
      luaConfig.post = ''
        if vim.g.started_by_firenvim == true then
          vim.o.laststatus = 0
        else
          vim.o.laststatus = 3
        end
      '';

      settings = {
        extensions = [
          "fugitive"
          "man"
          "oil"
          "quickfix"
          "trouble"
        ];
        options = {
          component_separators = {
            left = "|";
            right = "|";
          };
          section_separators = {
            left = "";
            right = "";
          };
        };

        sections = {
          lualine_a = [lualineModes];
          lualine_b = ["branch" "diff"];
          lualine_c = [
            "diagnostics"

            {
              __unkeyed-1 = "filename";
              path = 1;
            }
          ];
          lualine_x = ["searchcount"];
          lualine_y = [lualineMacro];
          lualine_z = ["location"];
        };
      };
    };

    plugins.nvim-bqf.enable = true;
    plugins.visual-whitespace.enable = true;
    plugins.visual-whitespace.lazyLoad.enable = true;
    plugins.visual-whitespace.lazyLoad.settings.event = "BufReadPost";

    extraConfigVim = ''
      autocmd TextYankPost * silent! lua vim.hl.on_yank {higroup='IncSearch', timeout=300}
    '';
  };
}

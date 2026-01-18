{
  programs.qutebrowser = {
    enable = true;
    
    keyBindings.normal = {
      "<Ctrl-o>" = "back";
      "<Ctrl-i>" = "forward";
      "H" = "tab-prev";
      "L" = "tab-next";
    };

    settings = let
      colors = {
        bg_dim = "#1e2326";
        bg0 = "#272e33";
        bg1 = "#2e383c";
        bg2 = "#374145";
        bg3 = "#414b50";
        bg4 = "#495156";
        bg5 = "#4f5b58";
        bg_visual = "#4c3743";
        bg_red = "#493b40";
        bg_green = "#3c4841";
        bg_blue = "#384b55";
        bg_yellow = "#45443c";
        fg = "#d3c6aa";
        red = "#e67e80";
        orange = "#e69875";
        yellow = "#dbbc7f";
        green = "#a7c080";
        aqua = "#83c092";
        blue = "#7fbbb3";
        purple = "#d699b6";
        grey0 = "#7a8478";
        grey1 = "#859289";
        grey2 = "#9da9a0";
        statusline1 = "#a7c080";
        statusline2 = "#d3c6aa";
        statusline3 = "#e67e80";
      };
    in {
      scrolling.smooth = true;

      fonts.default_family = "Josefin Sans";
      fonts.default_size = "24px";

      colors.webpage.bg = colors.bg0;
      colors.keyhint.fg = colors.fg;
      colors.keyhint.suffix.fg = colors.red;
      colors.messages.error.bg = colors.bg_red;
      colors.messages.error.fg = colors.fg;
      colors.messages.info.bg = colors.bg_blue;
      colors.messages.info.fg = colors.fg;
      colors.messages.warning.bg = colors.bg_yellow;
      colors.messages.warning.fg = colors.fg;
      colors.prompts.bg = colors.bg0;
      colors.prompts.fg = colors.fg;
      colors.completion.category.bg = colors.bg0;
      colors.completion.category.fg = colors.fg;
      colors.completion.fg = colors.fg;
      colors.completion.even.bg = colors.bg0;
      colors.completion.odd.bg = colors.bg1;
      colors.completion.match.fg = colors.red;
      colors.completion.item.selected.fg = colors.fg;
      colors.completion.item.selected.bg = colors.bg_yellow;
      colors.completion.item.selected.border.top = colors.bg_yellow;
      colors.completion.item.selected.border.bottom = colors.bg_yellow;
      colors.completion.scrollbar.bg = colors.bg_dim;
      colors.completion.scrollbar.fg = colors.fg;
      colors.hints.bg = colors.bg0;
      colors.hints.fg = colors.fg;
      colors.hints.match.fg = colors.red;
      colors.statusbar.normal.fg = colors.fg;
      colors.statusbar.normal.bg = colors.bg3;
      colors.statusbar.insert.fg = colors.bg0;
      colors.statusbar.insert.bg = colors.statusline1;
      colors.statusbar.command.fg = colors.fg;
      colors.statusbar.command.bg = colors.bg0;
      colors.statusbar.url.error.fg = colors.orange;
      colors.statusbar.url.fg = colors.fg;
      colors.statusbar.url.hover.fg = colors.blue;
      colors.statusbar.url.success.http.fg = colors.green;
      colors.statusbar.url.success.https.fg = colors.green;
      colors.tabs.bar.bg = colors.bg_dim;
      colors.tabs.even.bg = colors.bg0;
      colors.tabs.odd.bg = colors.bg0;
      colors.tabs.even.fg = colors.fg;
      colors.tabs.odd.fg = colors.fg;
      colors.tabs.selected.even.bg = colors.bg2;
      colors.tabs.selected.odd.bg = colors.bg2;
      colors.tabs.selected.even.fg = colors.fg;
      colors.tabs.selected.odd.fg = colors.fg;
      colors.tabs.indicator.start = colors.blue;
      colors.tabs.indicator.stop = colors.green;
      colors.tabs.indicator.error = colors.red;
    };
  };
}

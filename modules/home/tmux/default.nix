{ pkgs, laptop, ... }:

let 
  shell = "${pkgs.fish}/bin/fish";

  batteryString = if laptop then "battery " else "";
  modules = "${batteryString}date_time session";

  laptopModules = with pkgs.tmuxPlugins; [
    {
      plugin = battery;
      extraConfig = "set -g @plugin 'tmux-plugins/tmux-battery'";
    }
  ];

  tmuxWithSixel = pkgs.tmux.overrideAttrs (final: prev: {
    configureFlags = prev.configureFlags ++ ["--enable-sixel"];
  });
in

{
  imports = [
    ./tmate.nix
    ./twm.nix
  ];
  
  config = {
    programs.tmux = {
      enable = true;
      package = tmuxWithSixel;
      prefix = "C-a";
      inherit shell;
      escapeTime = 0;
      clock24 = true; mouse = true;
      resizeAmount = 5;
      sensibleOnTop = true;
      historyLimit = 50000;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [

        {
          plugin = sessionist;
          extraConfig = "set -g @plugin 'tmux-plugins/tmux-sessionist'";
        }

        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @plugin 'catppuccin/tmux'
            set -g @catppuccin_flavour 'mocha'

            set -g @catppuccin_date_time_text "%H:%M %d/%m"

            set -g @catppuccin_window_left_separator "█"
            set -g @catppuccin_window_right_separator "█ "
            set -g @catppuccin_window_number_position "right"
            set -g @catppuccin_window_middle_separator "  █"

            set -g @catppuccin_window_default_fill "number"

            set -g @catppuccin_window_current_fill "number"

            set -g @catppuccin_status_modules "${modules}"
            set -g @catppuccin_status_left_separator  ""
            set -g @catppuccin_status_right_separator " "
            set -g @catppuccin_status_right_separator_inverse "yes"
            set -g @catppuccin_status_fill "all"
            set -g @catppuccin_status_connect_separator "no"
          '';
        }

        vim-tmux-navigator

      ] ++ (if laptop then laptopModules else []);
      extraConfig = ''

        set -g default-terminal "tmux-256color"
        set -ag terminal-overrides ",xterm-256color:RGB" 

        # set -as terminal-features ",xterm-256color:RGB:Sxl"
        set -g default-command ${shell}

        bind-key -n M-\; command-prompt

        bind -n M-x split-window -v -c "#{pane_current_path}"
        bind -n M-v split-window -h -c "#{pane_current_path}"

        bind -n M-z resize-pane -Z

        unbind '"'
        unbind %

        bind c new-window -c "#{pane_current_path}"
        bind-key C-a command-prompt -p "window name:" "new-window -c #{pane_current_path}; rename-window '%%'"

        bind C-a last-window

        bind -n M-enter set -g status

      '';
    };
  };
}

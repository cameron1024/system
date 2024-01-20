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
in

{
  imports = [
    ./tmate.nix
    ./twm.nix
  ];
  
  config = {
    programs.tmux = {
      enable = true;
      prefix = "C-a";
      inherit shell;
      terminal = "screen-256color";
      escapeTime = 0;
      clock24 = true; mouse = true;
      resizeAmount = 5;
      sensibleOnTop = true;
      historyLimit = 50000;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [


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
      ] ++ (if laptop then laptopModules else []);
      extraConfig = ''
        
        set -as terminal-features ",xterm-256color:RGB"
        set -g default-command ${shell}

        bind-key -n M-\; command-prompt

        bind -n M-x split-window -v -c "#{pane_current_path}"
        bind -n M-v split-window -h -c "#{pane_current_path}"

        unbind '"'
        unbind %

        bind c new-window -c "#{pane_current_path}"
        bind-key C-a command-prompt -p "window name:" "new-window -c #{pane_current_path}; rename-window '%%'"

        bind C-a last-window

        bind -n M-h select-pane -L
        bind -n M-l select-pane -R
        bind -n M-k select-pane -U
        bind -n M-j select-pane -D

        bind -n M-enter set -g status

      '';
    };
  };
}

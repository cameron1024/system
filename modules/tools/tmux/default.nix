{ username, pkgs, ... }:

let 
  nushell = "${pkgs.nushell}/bin/nu";
in

{
  imports = [
    ./tmuxp.nix
  ];
  
  config.home-manager.users.${username} = {
    programs.tmux = {
      enable = true;
      prefix = "C-a";
      shell = nushell;
      terminal = "screen-256color";
      escapeTime = 0;
      clock24 = true;
      mouse = true;
      resizeAmount = 5;
      sensibleOnTop = true;
      historyLimit = 50000;
      keyMode = "vi";
      plugins = with pkgs.tmuxPlugins; [
        power-theme
        net-speed
      ];
      extraConfig = ''
        
        set -as terminal-features ",xterm-256color:RGB"
        set -g default-command ${nushell}

        thm_bg="#1e1e2e"
        thm_fg="#cdd6f4"
        thm_cyan="#89dceb"
        thm_black="#181825"
        thm_gray="#313244"
        thm_magenta="#cba6f7"
        thm_pink="#f5c2e7"
        thm_red="#f38ba8"
        thm_green="#a6e3a1"
        thm_yellow="#f9e2af"
        thm_blue="#89b4fa"
        thm_orange="#fab387"
        thm_black4="#585b70"

        set -g @plugin 'wfxr/tmux-net-speed'
        set -g @tmux_power_theme '#f5c2e7'

        bind-key -n M-\; command-prompt

        bind -n M-x split-window -v -c "#{pane_current_path}"
        bind -n M-v split-window -h -c "#{pane_current_path}"

        unbind '"'
        unbind %

        bind c new-window -c "#{pane_current_path}"

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

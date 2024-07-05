{pkgs, ...}: let
  plugins = with pkgs.tmuxPlugins; [
    {
      plugin = gruvbox;
      extraConfig = ''
        set -g @plugin 'egel/tmux-gruvbox'
        set -g @tmux-gruvbox 'dark'
      '';
    }
  ];
in {
  programs.tmux = {
    enable = true;

    inherit plugins;

    prefix = "C-a";
    escapeTime = 0;
    shell = "${pkgs.fish}/bin/fish";

    extraConfig = ''
      set -g default-terminal "xterm-256color"
      set -ag terminal-overrides ",xterm-256color:RGB:Sxl"

      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'

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
}

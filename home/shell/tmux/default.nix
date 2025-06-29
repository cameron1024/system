{
  pkgs,
  machine,
  ...
}: let
  plugins = with pkgs.tmuxPlugins; [
    tmux-fzf
    vim-tmux-navigator
    extrakto
  ];
in {
  home.packages = [pkgs.fzf];
  programs.tmux = {
    enable = true;

    inherit plugins;

    prefix = "C-a";
    escapeTime = 0;
    shell = "${pkgs.fish}/bin/fish";
    # shell = "${pkgs.nushell}/bin/nu";
    mouse = true;

    extraConfig =
      ''
        ${builtins.readFile ./everforest.tmux}


        set -g default-terminal "xterm-256color"
        set -ag terminal-overrides ",xterm-256color:RGB:Sxl"

        set -s extended-keys on
        set -as terminal-features 'extkeys'

        set -gq allow-passthrough on
        set -g visual-activity off

        bind-key -n M-\; command-prompt

        bind -n M-x split-window -v -c "#{pane_current_path}"
        bind -n M-v split-window -h -c "#{pane_current_path}"

        bind -n M-n next-window
        bind -n M-p previous-window
        bind -n M-c new-window -c "#{pane_current_path}"

        bind -n M-z resize-pane -Z

        unbind '"'
        unbind %

        bind c new-window -c "#{pane_current_path}"
        bind-key C-a command-prompt -p "window name:" "new-window -c #{pane_current_path}; rename-window '%%'"

        set-option -g automatic-rename-format '#{b:pane_current_path}'


        bind C-a last-window

        bind -n M-enter set -g status
      ''
      + (
        if machine.linux
        then ""
        else ''
          set-option -g default-command ${pkgs.fish}/bin/fish
        ''
      );
  };
}

{ pkgs, colors }:

let
  leftArrow = { before, after }: "#[bg=${before},fg=${after} nobold, nounderscore, noitalics]";
  rightArrow = { before, after }: "#[bg=${after},fg=${before},noitalics]";

in
{
  enable = true;
  clock24 = true;
  historyLimit = 30000;
  resizeAmount = 20;
  prefix = "C-a";
  newSession = true;
  keyMode = "vi";
  terminal = "screen-256color";
  plugins = with pkgs.tmuxPlugins; [
    cpu
    battery
    tmux-thumbs
  ];

  # colors
  #
  # 214 = yellow
  # 237 = mid-grey

  extraConfig = with colors.tmux; ''
    
    # alt-z to zoom pane
    bind-key -n M-z resize-pane -Z

    set -g @plugin 'tmux-plugins/tmux-battery'
    set -g @plugin 'fcsonline/tmux-thumbs'

    set -g @thumbs-osc52 1

    set-option -ga update-environment 'SWAYSOCK'

    unbind h
    unbind j
    unbind k
    unbind l
    unbind '"'
    unbind %

    bind-key C-a last-window

    # split panes using | and - (and start from cwd)
    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
    bind c new-window -c "#{pane_current_path}"


    # switch panes using hjkl
    bind h select-pane -L
    bind l select-pane -R
    bind k select-pane -U
    bind j select-pane -D

    # switch panes using alt+hjkl without prefix
    bind-key -n M-h select-pane -L
    bind-key -n M-l select-pane -R
    bind-key -n M-k select-pane -U
    bind-key -n M-j select-pane -D

    # switch panes using alt+arrows without prefix
    bind-key -n M-Left select-pane -L
    bind-key -n M-Right select-pane -R
    bind-key -n M-Up select-pane -U
    bind-key -n M-Down select-pane -D

    set -g  default-terminal "screen-256color"
    set -ga terminal-overrides ",xterm-256color:Tc"

    set-option -g status-style bg=${default.background},fg=${default.foreground}


    ${builtins.readFile ./tmux.conf}


set-option -g status-right "#[bg=colour237,fg=colour239 nobold, nounderscore, noitalics]#[bg=colour239,fg=colour246] %Y-%m-%d  %H:%M #[bg=colour239,fg=colour248,nobold,noitalics,nounderscore]#[bg=colour248,fg=colour237] #h "


#set -g status-right '#{battery_status_bg} Batt: #{battery_icon} #{battery_percentage} #{battery_remain} | %a %h-%d %H:%M '
     # set -g status-right '#{cpu_bg_color} CPU: #{cpu_icon} #{cpu_percentage} | %a %h-%d %H:%M '
    

    run-shell ${pkgs.tmuxPlugins.battery}/share/tmux-plugins/battery/battery.tmux
    run-shell ${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux
    run-shell ${pkgs.tmuxPlugins.tmux-thumbs}/share/tmux-plugins/tmux-thumbs/tmux-thumbs.tmux
     
  '';


}

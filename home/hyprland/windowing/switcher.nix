{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    inputs.hyprswitch.packages.${pkgs.system}.default
  ];

  wayland.windowManager.hyprland = {
    settings.exec-once = [
      "hyprswitch init"
    ];

    extraConfig = ''
      $key = TAB
      $modifier = ALT
      $modifier_release = ALT_L
      $reverse = SHIFT

      # allows repeated switching with same keypress that starts the submap
      binde = $modifier, $key, exec, hyprswitch --daemon --do-initial-execute
      bind = $modifier, $key, submap, switch

      # allows repeated switching with same keypress that starts the submap
      binde = $modifier $reverse, $key, exec, hyprswitch --daemon --do-initial-execute -r
      bind = $modifier $reverse, $key, submap, switch

      submap = switch
      # allow repeated window switching in submap (same keys as repeating while starting)
      binde = $modifier, $key, exec, hyprswitch --daemon
      binde = $modifier $reverse, $key, exec, hyprswitch --daemon -r

      # switch to specific window offset
      bind = $modifier, 1, exec, hyprswitch --daemon --offset=1
      bind = $modifier, 2, exec, hyprswitch --daemon --offset=2
      bind = $modifier, 3, exec, hyprswitch --daemon --offset=3
      bind = $modifier, 4, exec, hyprswitch --daemon --offset=4
      bind = $modifier, 5, exec, hyprswitch --daemon --offset=5

      bind = $modifier $reverse, 1, exec, hyprswitch --daemon --offset=1 -r
      bind = $modifier $reverse, 2, exec, hyprswitch --daemon --offset=2 -r
      bind = $modifier $reverse, 3, exec, hyprswitch --daemon --offset=3 -r
      bind = $modifier $reverse, 4, exec, hyprswitch --daemon --offset=4 -r
      bind = $modifier $reverse, 5, exec, hyprswitch --daemon --offset=5 -r


      # exit submap and stop hyprswitch
      bindrt = $modifier, $modifier_release, exec, hyprswitch --stop-daemon
      bindrt = $modifier, $modifier_release, submap, reset

      # if it somehow doesn't close on releasing $switch_release, escape can kill
      bindr = ,escape, exec, pkill hyprswitch
      bindr = ,escape, submap, reset
      submap = reset
    '';

  };
}

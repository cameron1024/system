Steps:
- Add nixos config
```nix
{
  services.gnome.at-spi2-core.enable = true;
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/desktop/interface".toolkit-accessibility = true;
  }];
  environment.systemPackages = with pkgs; [
    kdePackages.accessibility-inspector
  ];
}
```
- `gsettings set org.gnome.desktop.interface toolkit-accessibility true`
- run zed
- Request accessibility from dbus (automatically triggered by screen readers)
  - this causes our activation callback to trigger
```sh
dbus-send --session --dest=org.a11y.Bus --type=method_call \
  /org/a11y/bus org.freedesktop.DBus.Properties.Set \
  string:org.a11y.Status string:ScreenReaderEnabled variant:boolean:true
```
- Run `accessibilityInspector`
- ???
- profit

colors: with colors; ''

* {
  transition: none;
  box-shadow: none;
}

#waybar {
  color: ${base04};
  background: ${base01};
}

#workspaces {
  margin: 0 4px;
}

#workspaces button {
  margin: 4px 0;
  padding: 0 6px;
  color: ${base05};
}

#workspaces button.visible {
}

#workspaces button.focused {
  border-radius: 4px;
  background-color: ${base02};
}

#workspaces button.urgent {
  color: rgba(238, 46, 36, 1);
}

#tray {
  margin: 4px 16px 4px 4px;
  border-radius: 4px;
  background-color: ${base02};
}

#tray * {
  padding: 0 6px;
  border-left: 1px solid ${base00};
}

#tray *:first-child {
  border-left: none;
}

#mode, #battery, #cpu, #memory, #network, #pulseaudio, #idle_inhibitor, #backlight, #custom-storage, #custom-spotify, #custom-weather, #custom-mail, #clock, #temperature {
  margin: 4px 2px;
  padding: 0 6px;
  background-color: ${base02};
  border-radius: 4px;
  min-width: 20px;
}

#pulseaudio.muted {
  color: ${base0F};
}

#pulseaudio.bluetooth {
  color: ${base0C};
}

#clock {
  margin-left: 12px;
  margin-right: 4px;
  background-color: transparent;
}

#temperature.critical {
  color: ${base0F};
}

''

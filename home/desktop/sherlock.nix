{
  programs.sherlock.enable = true;
  programs.sherlock.settings = {
    appearance = {
      # Window dimensions
      width = 600;
      height = 400;
      # Use Linux-style modifier symbols: Shift, Caps, Ctrl, Meta, Alt, Super, Hyper, Fallback
      mod_key_ascii = ["⇧" "⇧" "Ctrl" "Meta" "Alt" "Super" "Hyper" "Ctrl"];
    };
    binds = {
      modifier = "control";
    };
  };
  programs.sherlock.launchers = [
    {
      name = "Apps";
      type = "app_launcher";
      args = {};
      priority = 2;
      home = "Home";
    }
    {
      name = "Calculator";
      type = "calculation";
      args = {
        capabilities = ["calc.math" "calc.units"];
      };
      priority = 1;
    }
    {
      name = "Clipboard";
      type = "clipboard-execution";
      args = {
        capabilities = ["url" "colors.hex" "colors.rgb"];
      };
      priority = 1;
      home = "Home";
    }
    {
      name = "Web Search";
      alias = "gg";
      type = "web_launcher";
      args = {
        search_engine = "google";
        icon = "google";
      };
      priority = 100;
    }
    {
      name = "Emoji Picker";
      type = "emoji_picker";
      alias = "emoji";
      args = {};
      priority = 4;
      home = "Search";
    }
    {
      name = "Kill Process";
      alias = "kill";
      type = "process";
      args = {};
      priority = 6;
      home = "Search";
    }
  ];
  programs.sherlock.style = ''
    :root {
      /* Everforest Dark Medium Background Colors */
      --background: #2D353B;
      --background-dim: #232A2E;
      --background-soft: #343F44;
      --background-alt: #3D484D;
      --border: #475258;
      --border-soft: #4F585E;

      /* Everforest Foreground Colors */
      --text: #D3C6AA;
      --text-active: #232A2E;
      --text-muted: #859289;

      /* Everforest Accent Colors */
      --foreground: #A7C080;
      --foreground-soft: #83C092;
      --tag-background: #A7C080;

      --error: #E67E80;
      --success: #A7C080;
      --warning: #DBBC7F;
      --blue: #7FBBB3;
      --purple: #D699B6;
      --aqua: #83C092;
      --orange: #E69875;
      --yellow: #DBBC7F;
      --red: #E67E80;
      --green: #A7C080;
    }

    /* Global font family */
    * {
      font-family: "Josefin Sans", sans-serif;
    }

    /* Main window styling */
    window {
      background: var(--background);
      border-radius: 12px;
      border: 1px solid var(--border);
    }

    /* Search bar */
    #search-entry {
      font-family: "Josefin Sans", sans-serif;
      font-size: 16px;
      color: var(--text);
      background: var(--background-soft);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 8px 12px;
    }

    #search-entry:focus {
      border-color: var(--foreground);
    }

    /* Search icon styling */
    #search-icon-holder image,
    image.reactive {
      -gtk-icon-filter: brightness(10) saturate(100%) contrast(100%);
    }

    row:selected .tile image.reactive {
      -gtk-icon-filter: brightness(0.1) saturate(100%) contrast(100%);
    }

    /* Search icon animation */
    #search-icon-holder image {
      transition: 0.1s ease;
    }

    #search-icon-holder.search image:nth-child(1) {
      transition-delay: 0.05s;
      opacity: 1;
    }

    #search-icon-holder.search image:nth-child(2) {
      transform: rotate(-180deg);
      opacity: 0;
    }

    #search-icon-holder.back image:nth-child(1) {
      opacity: 0;
    }

    #search-icon-holder.back image:nth-child(2) {
      transition-delay: 0.05s;
      opacity: 1;
    }

    /* Tile styling */
    .tile {
      background: var(--background);
      border-radius: 8px;
      padding: 8px 12px;
      margin: 2px 4px;
      transition: background 0.15s ease;
    }

    .tile:focus {
      outline: none;
    }

    row:selected .tile {
      background: var(--foreground);
    }

    /* Title styling */
    #title {
      font-family: "Josefin Sans", sans-serif;
      font-size: 14px;
      font-weight: 500;
      color: var(--text);
    }

    row:selected .tile #title {
      color: var(--text-active);
    }

    /* Subtitle/description styling */
    #subtitle,
    #description {
      font-family: "Josefin Sans", sans-serif;
      font-size: 12px;
      color: var(--text-muted);
    }

    row:selected .tile #subtitle,
    row:selected .tile #description {
      color: var(--background-alt);
    }

    /* Launcher type label */
    #launcher-type {
      font-family: "Josefin Sans", sans-serif;
      font-size: 10px;
      color: alpha(var(--text), 0.4);
      margin-left: 0px;
    }

    row:selected .tile #launcher-type {
      color: alpha(var(--text-active), 0.5);
    }

    /* Tag styling */
    .tag {
      font-family: "Josefin Sans", sans-serif;
      font-size: 11px;
      border-radius: 4px;
      padding: 2px 8px;
      margin-left: 7px;
      border: 1px solid alpha(var(--text-active), 0.2);
      box-shadow: 0px 0px 10px 0px alpha(var(--background), 0.2);
    }

    .tag-start {
      background: alpha(var(--tag-background), 0.7);
      color: var(--text-active);
    }

    .tag-end {
      background: var(--success);
      color: var(--text-active);
    }

    row:selected .tile .tag-start {
      background: alpha(var(--background), 0.5);
      color: var(--text);
    }

    row:selected .tile .tag-end {
      background: var(--background-alt);
      color: var(--text);
    }

    /* Shortcut holder */
    #shortcut-holder {
      margin-right: 25px;
      padding: 5px 10px;
      background: alpha(var(--foreground), 0.3);
      border-radius: 6px;
      border: 1px solid alpha(var(--text), 0.1);
    }

    #shortcut-holder label {
      font-family: "Josefin Sans", sans-serif;
      color: var(--text);
    }

    #shortcut-modkey {
      font-size: 13px;
    }

    row:selected .tile #shortcut-holder {
      background: alpha(var(--background), 0.5);
    }

    row:selected .tile #shortcut-holder label {
      color: var(--text);
    }

    /* Bulk text tile */
    .bulk-text {
      padding-bottom: 10px;
      min-height: 50px;
    }

    #bulk-text-title {
      font-family: "Josefin Sans", sans-serif;
      margin-left: 10px;
      padding: 10px 0px;
      font-size: 10px;
      color: alpha(var(--text), 0.5);
    }

    #bulk-text-content-title {
      font-family: "Josefin Sans", sans-serif;
      font-size: 17px;
      font-weight: bold;
      color: var(--text);
      min-height: 20px;
    }

    #bulk-text-content-body {
      font-family: "Josefin Sans", sans-serif;
      font-size: 14px;
      color: var(--text);
      line-height: 1.4;
      min-height: 20px;
    }

    /* Event tile */
    .tile.event-tile #time-label,
    .tile.event-tile #title-label {
      font-family: "Josefin Sans", sans-serif;
      color: var(--text);
    }

    .tile.event-tile:selected #time-label,
    .tile.event-tile:selected #title-label {
      color: var(--text-active);
    }

    /* Next page tile */
    .next_tile {
      color: var(--text);
      background: var(--background);
    }

    .next_tile #content-body {
      background: var(--background);
      padding: 10px;
      color: var(--text);
      font-family: "Fira Code", "JetBrains Mono", monospace;
      font-feature-settings: "kern" off;
      font-kerning: none;
    }

    .raw_text {
      font-family: "Fira Code", "JetBrains Mono", monospace;
      font-feature-settings: "kern" off;
      font-kerning: none;
    }

    /* Context menu */
    #context-menu {
      background: var(--background-soft);
      border: 1px solid var(--border);
      border-radius: 8px;
    }

    #context-menu row:selected label {
      color: var(--text-active);
    }

    /* Status bar */
    .status-bar {
      background: var(--background-dim);
      border-top: 1px solid var(--border);
    }

    .status-bar label {
      font-family: "Josefin Sans", sans-serif;
      color: var(--text-muted);
    }

    .status-bar #shortcut-key,
    .status-bar #shortcut-modifier {
      color: var(--text);
    }

    /* Emoji items */
    .emoji-item {
      background: alpha(var(--foreground), 0.15);
      border-radius: 6px;
    }

    .emoji-item:hover {
      background: alpha(var(--foreground), 0.3);
    }

    /* Scrollbar styling */
    scrollbar {
      background: transparent;
    }

    scrollbar slider {
      background: alpha(var(--text-muted), 0.3);
      border-radius: 4px;
      min-width: 6px;
      min-height: 6px;
    }

    scrollbar slider:hover {
      background: alpha(var(--text-muted), 0.5);
    }
  '';
}

{
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      mdcat
      slides
      jnv
      presenterm
    ]
    ++ (
      if pkgs.stdenv.isLinux
      then [pkgs.tdf]
      else []
    );

  xdg.configFile."presenterm/config.yaml".text = ''
    defaults:
      image_protocol: kitty-local
      theme: everforest-dark
      # Tell presenterm the real kitty base font size (see kitty.conf) so its
      # font_size multipliers and overflow detection are accurate.
      terminal_font_size: 12
    speaker_notes:
      always_publish: true
  '';

  # Everforest (Dark Hard) theme, matching the kitty `everforest_dark_hard`
  # colorscheme. presenterm has no built-in Everforest theme, so we ship our
  # own; it extends the built-in `dark` theme and overrides colors.
  xdg.configFile."presenterm/themes/everforest-dark.yaml".text = ''
    ---
    extends: dark

    palette:
      colors:
        # Everforest Dark Hard - backgrounds
        bg_dim: "16191c"
        bg0: "1e2326"
        bg1: "272e33"
        bg2: "2e383c"
        bg3: "374145"
        bg4: "414b50"
        # Everforest Dark Hard - foregrounds
        fg: "d3c6aa"
        red: "e67e80"
        orange: "e69875"
        yellow: "dbbc7f"
        green: "a7c080"
        aqua: "83c092"
        blue: "7fbbb3"
        purple: "d699b6"
        # Everforest Dark Hard - greys
        grey0: "7a8478"
        grey1: "859289"
        grey2: "9da9a0"

    # font_size values are integer multipliers of the terminal font (12px),
    # so 2 => 24px (body) and 4 => 48px (titles).
    default:
      font_size: 2
      colors:
        foreground: "palette:fg"
        background: "palette:bg0"

    intro_slide:
      title:
        font_size: 4
        colors:
          foreground: "palette:green"
      subtitle:
        colors:
          foreground: "palette:aqua"
      author:
        colors:
          foreground: "palette:grey2"

    slide_title:
      font_size: 4
      colors:
        foreground: "palette:green"

    headings:
      h1:
        font_size: 4
        colors:
          foreground: "palette:orange"
      h2:
        colors:
          foreground: "palette:yellow"
      h3:
        colors:
          foreground: "palette:aqua"
      h4:
        colors:
          foreground: "palette:blue"
      h5:
        colors:
          foreground: "palette:purple"
      h6:
        colors:
          foreground: "palette:purple"

    block_quote:
      colors:
        foreground: "palette:fg"
        background: "palette:bg1"

    inline_code:
      colors:
        foreground: "palette:aqua"
        background: "palette:bg1"

    code:
      colors:
        foreground: "palette:fg"
        background: "palette:bg1"
      theme_name: base16-eighties.dark

    footer:
      style: template
      left: "{title}"
      right: "{current_slide} / {total_slides}"
      colors:
        foreground: "palette:grey1"
  '';
}

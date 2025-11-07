{config, ...}: {
  programs.jujutsu.enable = true;
  programs.jujutsu.settings = {
    user.name = toString config.programs.git.settings.user.email;
    user.email = toString config.programs.git.settings.user.email;
    ui.diff-editor = ["nvim" "-c" "DiffEditor" "$left" "$right" "$output"];
  };
}

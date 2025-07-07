{config, ...}: {
  programs.jujutsu.enable = true;
  programs.jujutsu.settings = {
    user.name = config.programs.git.userName;
    user.email = config.programs.git.userEmail;
    ui.diff-editor = ["nvim" "-c" "DiffEditor" "$left" "$right" "$output"];
  };
}

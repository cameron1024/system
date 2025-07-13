{config, ...}: {
  programs.jujutsu.enable = true;
  programs.jujutsu.settings = {
    user.name = toString config.programs.git.userName;
    user.email = toString config.programs.git.userEmail;
    ui.diff-editor = ["nvim" "-c" "DiffEditor" "$left" "$right" "$output"];
  };
}

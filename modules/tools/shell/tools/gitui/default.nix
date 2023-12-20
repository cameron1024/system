{ username, ... }:

{
  home-manager.users.${username} = {
    programs.gitui.enable = true;
    programs.gitui.theme = ./theme.ron;
  };
}

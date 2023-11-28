{ pkgs, username, ... }:

let
  config = pkgs.writeText "tmuxp.yaml" (builtins.readFile ./tmuxp.yaml);
in

{
  home-manager.users.${username} = {
    # programs.tmuxp = {
    #
    # };
    #
    # programs.nushell.environmentVariables = {
    #   
    # };
  };
}

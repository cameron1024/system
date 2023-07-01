{ pkgs, ... }:

{

  home-manager.users.cameron = {
    xdg.configFile."swaylock/config".source = ./swaylock.conf;
  };

  environment.systemPackages = with pkgs; [
    swaylock-effects
  ];

  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;


  #  environment.etc."pam.d/swaylock".text = '' 
  #    auth            sufficient      pam_unix.so try_first_pass likeauth nullok
  #    auth            sufficient      pam_fprintd.so 
  #  '';
}

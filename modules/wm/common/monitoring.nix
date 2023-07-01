{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sutils
    light
  ];
}

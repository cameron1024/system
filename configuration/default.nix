{isDarwin, ...}: let
  platformSpecific =
    if isDarwin
    then ./mac
    else ./linux;
in {
  imports = [
    ./shared
    platformSpecific
  ];
}

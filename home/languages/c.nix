{pkgs, ...}: {
  home.packages = with pkgs; [
    clang
    cmake
    clang-tools
  ];
}

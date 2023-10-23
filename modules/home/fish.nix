{
  enable = true;

  shellAbbrs = {
    e = "nvim";
    ed = "neovide --multigrid";
    p = "cd ~/projects/playground";
    x = "./x.py";
    ls = "exa -l";
    dev = "nix develop --command fish";
    dr = "direnv reload";
    rs = "rust-script";
    t = "cd /tmp";
    c = "cd -";
    pub = "flutter pub";
    fr = "flutter run";
    g = "z";
    gr = "zoxide remove .";
  };

  interactiveShellInit = ''
    	starship init fish | source
    	zoxide init fish | source
    	direnv hook fish | source
      navi widget fish | source

      set PATH $HOME/.cargo/bin $PATH

      set fish_greeting


      set -gx RUST_BACKTRACE 1
      set -gx RUST_LOG "info"

      set -gx EDITOR nvim

      set -gx NIXPKGS_ALLOW_UNFREE 1

      set -gx XCURSOR_THEME Adwaita
      set -gx fish_term24bit 1
      set -gx theme_nerd_fonts yes

      set -gx CHROME_EXECUTABLE (which google-chrome-stable)

      set -gx _ZO_EXCLUDE_DIRS ~/.config

      alias gc "git add -A; git commit -m $argv"

      alias sl "silicon --from-clipboard --to-clipboard --language $argc"
  '';



}

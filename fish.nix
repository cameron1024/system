{
  enable = true;

  shellAliases = {
    o = "cd -";
    g = "z";
    q = "exit";
    p = "cd ~/projects/playground";

    # git stuff
    gps = "git push $argv";
    gpl = "git pull $argv";
    grst = "git reset --hard HEAD";

  };

  shellAbbrs = {
    e = "nvim";
    cg = "cargo";
    x = "./x.py";
    hm = "home-manager";
    ls = "exa";
    dev = "nix develop --command fish";
    dr = "direnv reload";
    rs = "rust-script";
    t = "cd /tmp";
    c = "cd -";
    h = "nvim ~/nixpkgs/tunables.nix";
    nt = "cargo nextest run";
  };
  interactiveShellInit = ''
    	starship init fish | source
    	zoxide init fish | source
    	direnv hook fish | source
      navi widget fish | source

      set fish_greeting


      set -gx RUST_BACKTRACE 1
      set -gx RUST_LOG "info"

      set -gx EDITOR nvim

      set -gx fish_term24bit 1
      set -gx theme_nerd_fonts yes

      set -gx FZF_DEFAULT_COMMAND 'rg --hidden'
      set -gx CHROME_EXECUTABLE (which google-chrome-stable)

      set -gx _ZO_EXCLUDE_DIRS ~/.config

      alias gc "git add -A; git commit -m $argv"

      alias sl "silicon --from-clipboard --to-clipboard --langauge $argc"

      if status is-interactive
      and not set -q TMUX
          exec tmux
      end
  '';



}
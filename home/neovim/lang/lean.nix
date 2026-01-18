{pkgs, lib, ...}: {
  plugins.lean = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.ft = "lean";
    settings.mappings = true;
  };
  dependencies.lean.enable = lib.mkForce false;

  plugins.treesitter.grammarPackages = [
    (pkgs.tree-sitter.buildGrammar {
      language = "lean";
      version = "0.0.0";
      src = pkgs.fetchFromGitHub {
        owner = "Julian";
        repo = "tree-sitter-lean";
        rev = "efe6b87145608d12f5996bd7f0cf6095a0e82261";
        hash = "sha256-MF+LRzhDw3V/l/h11ZTyWCUCm3b+g0oyOdaCZMVlJc4=";
      };
    })
  ];
}

{
  pkgs,
  lib,
  ...
}: {
  plugins.lean = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.ft = "lean";
    settings.mappings = true;
    settings.on_imports_out_of_date.__raw = "function(_) end";
  };
  dependencies.lean.enable = lib.mkForce false;
  autoCmd = [
    {
      command = "set nospell";
      event = "FileType";
      pattern = "lean";
    }
  ];
}

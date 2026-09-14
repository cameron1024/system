{lib, ...}: {
  imports = [./cli.nix];

  programs.nixvim = {
    # Remote editing must not depend on a display server or local browser.
    opts.clipboard = lib.mkForce "";
    plugins.firenvim.enable = lib.mkForce false;
    plugins.img-clip.enable = lib.mkForce false;
    plugins.typst-preview.enable = lib.mkForce false;
    plugins.lsp.servers.qmlls.enable = lib.mkForce false;
    plugins.snacks.settings.image.enabled = false;
  };
}

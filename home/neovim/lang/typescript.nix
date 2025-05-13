{pkgs, ...}: {
  home.packages = [pkgs.nodejs];
  programs.nixvim = {
    plugins.lsp.servers.tailwindcss.enable = true;
    plugins.lsp.servers.svelte.enable = true;
    plugins.typescript-tools.enable = true;
    plugins.tailwind-tools.enable = true;
    plugins.ts-autotag.enable = true;
  };
}

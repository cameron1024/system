let
  lazyLoad = {
    settings.ft = ["typescript" "typescriptreact"];
  };
in {
  plugins.lsp.servers.tailwindcss.enable = true;
  plugins.lsp.servers.svelte.enable = true;

  plugins.typescript-tools.enable = true;
  plugins.typescript-tools.lazyLoad = lazyLoad;
  plugins.tailwind-tools.enable = true;
  plugins.tailwind-tools.lazyLoad = lazyLoad;
  plugins.ts-autotag.enable = true;
  plugins.ts-autotag.lazyLoad = lazyLoad;
}

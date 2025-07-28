{
  arch,
}:

(final: prev: {
  optimizeGccArch = pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = [ (old.NIX_CFLAGS_COMPILE or "") ] ++ flags;
    });

  linux = final.optimizeWithFlags prev.linux [ "-O3" "-march=${arch}" ];
})

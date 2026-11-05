{
  lib,
  rustPlatform,
  fetchFromGitHub,
  runCommand,
  applyPatches,
  pkg-config,
  makeWrapper,
  fontconfig,
  freetype,
  wayland,
  libxkbcommon,
  vulkan-loader,
  pulseaudio,
  libqalculate,
  wtype,
}: let
  manifest = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  zed = applyPatches {
    src = fetchFromGitHub {
      owner = "zed-industries";
      repo = "zed";
      rev = manifest.dependencies.gpui.rev;
      hash = "sha256-Gd+7KpOH2wbfimdA7oAJrFMfxPCmFiVs8fOGLhrxlkY=";
    };
    patches = map (name: ./patches + "/${name}")
      (builtins.filter (lib.hasSuffix ".patch") (builtins.attrNames (builtins.readDir ./patches)));
  };
  source = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      !(builtins.elem (builtins.baseNameOf path) ["target" "vendor" "__pycache__" ".git"]);
  };
  # Cargo's local GPUI patches must exist before dependency vendoring as well as compilation.
  src = runCommand "myshell-source" {} ''
    cp -r ${source} $out
    chmod u+w $out
    mkdir -p $out/vendor
    ln -s ${zed} $out/vendor/zed
  '';
  runtimeLibs = [wayland libxkbcommon vulkan-loader];
in
  rustPlatform.buildRustPackage {
    pname = "myshell";
    inherit (manifest.package) version;
    inherit src;
    cargoLock = {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "async-process-2.5.0" = "sha256-Y37QTr6sjayv+JjGz00v0AMLQtsix1nH1lNKmky+6bU=";
        "async-task-4.7.1" = "sha256-+ee4Mqd/Uj8Ki3Vjo6U9gtpZnuFeJtji5kgH3u3IBrA=";
        "calloop-0.14.3" = "sha256-5lWGGm6Wehf3RNFnhll0hMlUCXeVFHeoyHN4pbMS9zQ=";
        "wasm_thread-0.3.3" = "sha256-+lRLCIk0S6Y5ORYjDKsYYHia2FtoSoh+rWkQh7mnPBE=";
        "zed-font-kit-0.14.1-zed" = "sha256-KXygi0olNQi5yM8eaJVykNDtbPMDjT+cWPBF8UrtXR4=";
      };
    };
    nativeBuildInputs = [pkg-config makeWrapper];
    buildInputs = [fontconfig freetype] ++ runtimeLibs;
    MYSHELL_QALC = "${libqalculate}/bin/qalc";
    MYSHELL_WTYPE = "${wtype}/bin/wtype";
    postFixup = ''
      wrapProgram $out/bin/myshell \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
        --prefix PATH : ${lib.makeBinPath [pulseaudio]}
    '';
    meta.mainProgram = "myshell";
  }

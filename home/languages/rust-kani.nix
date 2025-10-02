{ 
  rust-overlay,
  kani-tarball, 
  kani-repo, 
  glibc, 
  extend, 
  system, 
  rsync, 
  makeWrapper, 
  stdenv, 
  autoPatchelfHook 
}:
let
  rustPkgs = extend (import rust-overlay);

  rustHome = rustPkgs.rust-bin.nightly."2025-07-02".default.override {
    extensions = ["rustc-dev" "rust-src" "llvm-tools" "rustfmt"];
  };

  rustPlatform = rustPkgs.makeRustPlatform {
    cargo = rustHome;
    rustc = rustHome;
  };

  kani-home = stdenv.mkDerivation {
    name = "kani-home";

    src = kani-tarball;

    buildInputs = [
      stdenv.cc.cc.lib #libs needed by patchelf
    ];

    runtimeDependencies = [
      glibc #not detected as missing by patchelf for some reason
    ];

    nativeBuildInputs = [ autoPatchelfHook ];

    installPhase = ''
    runHook preInstall
    ${rsync}/bin/rsync -av $src/ $out --exclude kani-compiler
    runHook postInstall
    '';
  };

  kani = rustPlatform.buildRustPackage rec {
    pname = "kani";

    version = "kani-0.64.0";

    src = kani-repo;

    nativeBuildInputs = [ makeWrapper ];

    patches = [ ./rust-kani.patch ];

    postInstall = ''
    mkdir -p $out/lib/
    ${rsync}/bin/rsync -av ${kani-home}/ $out/lib/${version} --perms --chmod=D+rw,F+rw
    cp $out/bin/* $out/lib/${version}/bin/
    ln -s ${rustHome} $out/lib/${version}/toolchain
    '';

    postFixup = ''
    wrapProgram $out/bin/kani --set KANI_HOME $out/lib/
    wrapProgram $out/bin/cargo-kani --set KANI_HOME $out/lib/
    '';

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit patches pname version src;
      hash = "sha256-1MfK2O4F0YJZJgDRxwAQ8vRM4Xgx9i1Xl1+InH6r2b4=";
    };

    env = {
      RUSTUP_HOME = "${rustHome}";
      RUSTUP_TOOLCHAIN = "..";
    };
  };
in 
  if system == "x86_64-linux" then kani 
  else throw "Oops! ${system} not supported by this kani derivation"

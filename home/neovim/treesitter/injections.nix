{
  programs.nixvim = {
    extraFiles."after/queries/rust/injections.scm".source = ./injections-rust.scm;
    extraFiles."after/queries/dart/injections.scm".source = ./injections-dart.scm;
  };
}

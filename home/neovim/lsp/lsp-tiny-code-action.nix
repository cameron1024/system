{
  fetchFromGitHub,
  vimUtils,
  ...
}:
vimUtils.buildVimPlugin {
  pname = "tiny-code-action";
  version = "0.0.0";
  doCheck = false;
  src = fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-code-action.nvim";
    rev = "aba93f1f71f3820e0a4d50f0de9b841f522376f7";
    hash = "sha256-Bp6+s4aJLQ7wK6+sVjtF65WZzP+MqVeSsHgQveVHSio=";
  };
}

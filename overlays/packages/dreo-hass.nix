{
  fetchFromGitHub,
  buildHomeAssistantComponent,
  python313Packages,
  ...
}: let
  pydreo = python313Packages.buildPythonPackage {
    name = "pydreo-cloud";
    propagatedBuildInputs = with python313Packages; [
      tzlocal
      pycryptodome
      setuptools
      requests
    ];
    pyproject = true;
    src = fetchFromGitHub {
      owner = "dreo-team";
      repo = "pydreo-cloud";
      rev = "v0.0.6";
      hash = "sha256-OLouQg1Venf5IP9aLcbORyS3vB8Wxa6OQ0SZAYvdmhw=";
    };
  };
in
  buildHomeAssistantComponent rec {
    owner = "dreo-team";
    domain = "dreo";
    version = "v2.0.0";

    src = fetchFromGitHub {
      owner = "dreo-team";
      repo = "hass-dreoverse";
      rev = version;
      hash = "sha256-KxH/dscxgqKhOZrIJYTNzqUl4KiQL0G2BxxFwk+Nc1I=";
    };

    buildInputs = with python313Packages; [
      websockets
      pydreo
    ];

    # postPatch = ''
    #   substituteInPlace custom_components/dirigera_platform/manifest.json \
    #     --replace-fail "0.0.1" "${version}"
    # '';
    #
    # meta = with lib; {
    #   description = "Home-assistant integration for IKEA Dirigera hub";
    #   homepage = "https://github.com/sanjoyg/dirigera_platform";
    #   maintainers = with maintainers; [ rhoriguchi ];
    #   license = licenses.mit;
    # };
  }

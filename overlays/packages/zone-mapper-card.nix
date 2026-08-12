{
  stdenvNoCC,
  fetchFromGitHub,
}:
  stdenvNoCC.mkDerivation {
    pname = "zone-mapper-card";
    # No upstream release tags; pinned to a `main` commit that ships a
    # prebuilt dist/zone-mapper-card.js.
    version = "0-unstable-2026-04-23";

    src = fetchFromGitHub {
      owner = "ApolloAutomation";
      repo = "zone-mapper-card";
      rev = "67f3acba24c5f1c8f6e4eb131870394d8d6eb23e";
      hash = "sha256-YANjl68bQJkjEoqc2N4fF6I/rluhtL5JmQPWnwuXRSQ=";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp dist/zone-mapper-card.js $out/
      runHook postInstall
    '';
  }

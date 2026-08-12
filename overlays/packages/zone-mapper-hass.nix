{
  fetchFromGitHub,
  buildHomeAssistantComponent,
  ...
}:
  buildHomeAssistantComponent rec {
    owner = "ApolloAutomation";
    domain = "zone_mapper";
    version = "1.0.1";

    src = fetchFromGitHub {
      owner = "ApolloAutomation";
      repo = "zone-mapper";
      rev = version;
      hash = "sha256-MxDafJ2xgnPFWEIslqxSnw35PZ0dZ9JrqDhutgiOYQ4=";
    };
  }

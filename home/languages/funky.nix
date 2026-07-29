{pkgs, ...}: {
  home.packages = with pkgs; [
    fstar
    elan # lean theorem prover
    mistral-vibe # mistral's open-source (apache-2.0) cli coding agent
  ];

  # Pre-configure Mistral Vibe. Managed declaratively, so this becomes a
  # read-only symlink into the Nix store. Your API key is NOT stored here:
  # put `MISTRAL_API_KEY` in the environment or in ~/.vibe/.env (writable).
  home.file.".vibe/config.toml".text = ''
    # --- Privacy: disable all telemetry and "phoning home" ----------------
    # The only network traffic left is what's actually required to serve API
    # requests to Mistral.
    enable_telemetry = false          # usage telemetry + crash reporting
    enable_update_checks = false      # daily PyPI "new version?" ping
    enable_auto_update = false        # never self-update over the network
    include_commit_signature = false  # stop attaching your git name/email/GPG
                                      # to every API request (defaults to true)

    # --- Leanstral: Mistral's open-source (Apache-2.0) Lean 4 model --------
    # Registered as a selectable model + a dedicated "lean" agent mode. It is
    # NOT set as the global default, so general coding keeps Vibe's normal
    # model; switch to it with the model picker / Shift+Tab lean mode.
    #
    # NOTE: `name` / `api_base` below target Mistral's hosted (free) endpoint
    # and are best-effort. If Mistral changes the model id, the supported
    # fallback is to run `/leanstall` once inside `vibe`.
    installed_agents = ["lean"]

    [[providers]]
    name = "mistral-labs"
    api_base = "https://api.mistral.ai/v1"
    api_key_env_var = "MISTRAL_API_KEY"
    backend = "generic"
    reasoning_field_name = "reasoning_content"

    [[models]]
    name = "labs-leanstral-1-5"
    provider = "mistral-labs"
    alias = "leanstral"
    thinking = "high"
    temperature = 1.0
  '';
}

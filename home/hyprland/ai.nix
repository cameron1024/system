{
  pkgs,
  lib,
  machine,
  ...
}: let
  storeKey = "voice-typing-pid";
  toggleVoiceTyping = pkgs.writeShellScriptBin "toggle-voice-typing" ''
    BASE_DIR="$XDG_CACHE_HOME/voice-typing"
    AUDIO_LOCATION="$BASE_DIR/output.wav"

    RUNNING_PID=$(hypr-utils store get ${storeKey})


    if [ -z "''${RUNNING_PID}" ]; then
      # RUNNING_PID is empty - no session is active - start a new session

      mkdir -p "$BASE_DIR" 2> /dev/null || true
      rm "$BASE_DIR"/* 2> /dev/null || true

      ${pkgs.alsa-utils}/bin/arecord --max-file-time=600 --file-type wav "$AUDIO_LOCATION" &
      NEW_PID=$!

      hypr-utils store set ${storeKey} "$NEW_PID"
      disown "$NEW_PID"
    else
      kill -SIGABRT "$RUNNING_PID"  # end recording
      hypr-utils store unset ${storeKey}

      ${pkgs.openai-whisper}/bin/whisper \
        --task transcribe \
        --language en \
        --output_dir "$BASE_DIR" \
        "$AUDIO_LOCATION"
      # rm $AUDIO_LOCATION
    fi
  '';
in {
  config = lib.mkIf machine.linux {
  home.packages = with pkgs; [
    toggleVoiceTyping
    whisper
    alsa-utils
  ];
  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, z, exec, ${toggleVoiceTyping}/bin/toggle-voice-typing"
    ];
  };
}

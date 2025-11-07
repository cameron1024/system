#!/usr/bin/env sh

#$ nix shell nixpkgs#whisper-cpp

RECORDING_TEXT_PATH=/tmp/whisper-recording.txt

whisper-cli \
  --output-txt "$RECORDING_TEXT_PATH"

#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/bin"
install -m 775 flac2mp3.sh "$HOME/bin/flac2mp3"

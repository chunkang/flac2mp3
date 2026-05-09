#!/usr/bin/env bash
#
# flac2mp3 - Recursive FLAC to MP3 batch converter
#
# Contributor: Chun Kang <ck@qsok.com>
#
# Usage:
#   ./flac2mp3.sh                    # convert every *.flac under the current folder
#   ./flac2mp3.sh '*.flac'           # same as above (quoted to defer glob expansion)
#   ./flac2mp3.sh 'hello*.flac'      # convert files matching the pattern, recursively
#   ./flac2mp3.sh song.flac other.flac
#

set -uo pipefail

print_credit() {
    cat <<'EOF'
============================================================
 flac2mp3 - FLAC to MP3 batch converter
 Contributor: Chun Kang <ck@qsok.com>
============================================================
EOF
}

err() { printf 'Error: %s\n' "$*" >&2; }

install_ffmpeg() {
    if command -v ffmpeg >/dev/null 2>&1; then
        return 0
    fi

    echo "ffmpeg not found - attempting automatic install..."

    local os
    os="$(uname -s)"
    case "$os" in
        Linux*)
            if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y ffmpeg
            elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y ffmpeg
            elif command -v yum     >/dev/null 2>&1; then sudo yum install -y ffmpeg
            elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm ffmpeg
            elif command -v zypper  >/dev/null 2>&1; then sudo zypper install -y ffmpeg
            elif command -v apk     >/dev/null 2>&1; then sudo apk add ffmpeg
            else err "No supported Linux package manager found. Install ffmpeg manually."; exit 1
            fi
            ;;
        Darwin*)
            if command -v brew >/dev/null 2>&1; then
                brew install ffmpeg
            else
                err "Homebrew not found. Install it from https://brew.sh and rerun."
                exit 1
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if   command -v pacman >/dev/null 2>&1; then pacman -S --noconfirm mingw-w64-x86_64-ffmpeg
            elif command -v winget >/dev/null 2>&1; then winget install --id=Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
            elif command -v choco  >/dev/null 2>&1; then choco install ffmpeg -y
            elif command -v scoop  >/dev/null 2>&1; then scoop install ffmpeg
            else err "No supported Windows package manager found (pacman/winget/choco/scoop)."; exit 1
            fi
            ;;
        *)
            err "Unsupported OS: $os"
            exit 1
            ;;
    esac

    if ! command -v ffmpeg >/dev/null 2>&1; then
        err "ffmpeg is still not on PATH after install. Open a new shell or install manually."
        exit 1
    fi
}

convert_one() {
    local src="$1"
    local dst="${src%.[Ff][Ll][Aa][Cc]}.mp3"

    if [[ -f "$dst" ]]; then
        echo "[skip] $dst already exists"
        return 0
    fi

    echo "[conv] $src"
    if ffmpeg -hide_banner -loglevel error -y -i "$src" \
              -map 0:a -map 0:v? \
              -codec:a libmp3lame -qscale:a 2 \
              -c:v copy -disposition:v attached_pic \
              -map_metadata 0 -id3v2_version 3 -write_id3v1 1 \
              "$dst" </dev/null; then
        return 0
    fi

    err "failed: $src"
    [[ -f "$dst" ]] && rm -f "$dst"
    return 1
}

main() {
    print_credit
    install_ffmpeg

    local -a patterns
    if [[ $# -eq 0 ]]; then
        patterns=("*.flac")
    else
        patterns=("$@")
    fi

    local seen
    seen="$(mktemp)"
    trap 'rm -f "$seen"' EXIT

    local -a files=()
    local pattern f
    for pattern in "${patterns[@]}"; do
        while IFS= read -r -d '' f; do
            if ! grep -qxF -- "$f" "$seen"; then
                printf '%s\n' "$f" >> "$seen"
                files+=("$f")
            fi
        done < <(find . -type f -iname "$pattern" -print0 2>/dev/null)
    done

    local total=${#files[@]}
    if [[ $total -eq 0 ]]; then
        echo "No FLAC files matched: ${patterns[*]}"
        exit 0
    fi

    echo "Found $total FLAC file(s). Starting conversion..."

    local i=0 fail=0
    for f in "${files[@]}"; do
        i=$((i + 1))
        printf '[%d/%d] ' "$i" "$total"
        convert_one "$f" || fail=$((fail + 1))
    done

    echo
    echo "Done. Processed: $total | Failed: $fail"
    [[ $fail -eq 0 ]] || exit 1
}

main "$@"

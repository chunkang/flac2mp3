# flac2mp3

A small Bash script that recursively converts FLAC files to MP3 while preserving
their metadata (ID3 tags) and embedded cover art.

## Features

- Recursive scan of the current folder (and any sub-folders).
- Optional glob patterns (`*.flac`, `hello*.flac`, ...) or explicit file lists.
- Auto-installs `ffmpeg` on first run if it is missing
  (apt / dnf / yum / pacman / zypper / apk on Linux, Homebrew on macOS,
  pacman / winget / choco / scoop on Windows / MSYS / Cygwin).
- Preserves tag information from FLAC (Vorbis comments &rarr; ID3v2.3 + ID3v1).
- Preserves embedded album artwork as the MP3's attached picture.
- Skips files whose `.mp3` already exists; cleans up partial output on failure.
- High-quality VBR encode (`libmp3lame -qscale:a 2`, ~190 kbps average).

## Requirements

- Bash 4+ (Linux, macOS, WSL, Git Bash / MSYS2 / Cygwin on Windows).
- `ffmpeg` &mdash; installed automatically if missing, or install it yourself.

## Usage

```bash
# Convert every *.flac under the current folder
./flac2mp3.sh

# Same, but with the pattern made explicit (quote it so the shell does not expand it)
./flac2mp3.sh '*.flac'

# Only files whose name matches a pattern, anywhere under the current folder
./flac2mp3.sh 'hello*.flac'

# Specific files
./flac2mp3.sh song.flac other.flac
```

The script prints a `[conv] / [skip] / [fail]` line per file and a final
`Processed / Failed` summary. It exits non-zero if any file failed.

## What gets preserved

| FLAC source                                  | MP3 output                            |
| -------------------------------------------- | ------------------------------------- |
| Vorbis comments (artist, album, title, ...) | ID3v2.3 + ID3v1 tags                  |
| Embedded picture (cover art)                 | ID3 attached picture (copied as-is)   |
| Audio                                        | LAME VBR, `-qscale:a 2` (~190 kbps)   |

## Contributor

- Chun Kang &lt;ck@qsok.com&gt;

## License

See [LICENSE](LICENSE).

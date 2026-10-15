#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
  printf 'test-bemenu-themed: FAIL: %s\n' "$1" >&2
  exit 1
}

contains() {
  local haystack="$1" needle="$2" label="$3"
  case "$haystack" in
    *"$needle"*) ;;
    *) fail "$label: missing '$needle' in: $haystack" ;;
  esac
}

# Hermetic: ignore any inherited bemenu overrides.
unset BEMENU_LINES BEMENU_WIDTH BEMENU_MARGIN BEMENU_BORDER BEMENU_RADIUS \
  BEMENU_LINE_HEIGHT BEMENU_FONT

bin="$tmp/bin"
nobin="$tmp/nobin"
mkdir -p "$bin" "$nobin"

# Fixture palette: quoted values, distinct per key, leading '#'.
cat >"$tmp/colors.toml" <<'EOF'
background = "#111c18"
foreground = "#c1c497"
accent = "#509475"
selection_background = "#32473b"
bright_foreground = "#f7e8b2"
muted = "#53685b"
lighter_background = "#23372b"
darker_background = "#090f0d"
EOF

# Renderer stubs echo their argv, tagged by binary.
cat >"$bin/bemenu" <<'EOF'
#!/usr/bin/env bash
printf 'BEMENU: %s\n' "$*"
EOF
cat >"$bin/bemenu-run" <<'EOF'
#!/usr/bin/env bash
printf 'BEMENU-RUN: %s\n' "$*"
EOF
chmod +x "$bin/bemenu" "$bin/bemenu-run"

# Isolated PATH for the direct-read case: only the stubs and the coreutils the
# sed fallback needs. This excludes /usr/bin, where omarchy-theme-color is also
# installed, so the resolver is genuinely absent.
bash_bin=$(command -v bash)
ln -s "$bin/bemenu" "$nobin/bemenu"
ln -s "$bin/bemenu-run" "$nobin/bemenu-run"
ln -s "$bash_bin" "$nobin/bash"
ln -s "$(command -v sed)" "$nobin/sed"
ln -s "$(command -v head)" "$nobin/head"

# Resolver stub: returns a distinct value per key, never the fixture value, so
# a passing assertion proves the resolver path (not the sed fallback) ran.
cat >"$bin/omarchy-theme-color" <<'EOF'
#!/usr/bin/env bash
# invoked as: omarchy-theme-color --file <file> <key> [<fallback>]
key="${3:-}"
fallback="${4:-}"
case "$key" in
  background)          printf '#101010' ;;
  foreground)          printf '#e0e0e0' ;;
  accent)              printf '#00ff00' ;;
  selection_background) printf '#202020' ;;
  bright_foreground)   printf '#ffffff' ;;
  muted)               printf '#808080' ;;
  lighter_background)  printf '#303030' ;;
  darker_background)   printf '#000000' ;;
  *)                   printf '%s' "$fallback" ;;
esac
EOF
chmod +x "$bin/omarchy-theme-color"

wrapper="$root/scripts/bemenu-themed"
run_path="$bin:/usr/bin:/bin"

# --- Resolver present, piped stdin (selects bemenu) ---
out=$(printf '' | PATH="$run_path" OMARCHY_THEME_COLORS="$tmp/colors.toml" bash "$wrapper")

contains "$out" 'BEMENU:' 'piped stdin selects bemenu'
contains "$out" '-c' 'center flag'
contains "$out" '--fixed-height' 'fixed-height flag'
contains "$out" '-l 10' 'lines'
contains "$out" '-W 0.4' 'width'
contains "$out" '-M 8' 'margin'
contains "$out" '-B 2' 'border'
contains "$out" '-R 8' 'radius'
contains "$out" '-H 26' 'line height'
contains "$out" '--fn JetBrainsMono Nerd Font 12' 'font'

# Every key -> flag mapping (resolver values).
contains "$out" '--nb #101010' 'normal background'
contains "$out" '--nf #e0e0e0' 'normal foreground'
contains "$out" '--hb #202020' 'highlight background'
contains "$out" '--sb #202020' 'selected background'
contains "$out" '--hf #ffffff' 'highlight foreground'
contains "$out" '--sf #ffffff' 'selected foreground'
contains "$out" '--tb #101010' 'title background'
contains "$out" '--tf #e0e0e0' 'title foreground'
contains "$out" '--fb #101010' 'filter background'
contains "$out" '--ff #00ff00' 'filter foreground (accent)'
contains "$out" '--cb #00ff00' 'cursor background (accent)'
contains "$out" '--cf #101010' 'cursor foreground'
contains "$out" '--fbb #101010' 'feedback background'
contains "$out" '--fbf #808080' 'feedback foreground (muted)'
contains "$out" '--ab #303030' 'alternate background (lighter)'
contains "$out" '--af #808080' 'alternate foreground (muted)'
contains "$out" '--scb #000000' 'scrollbar background (darker)'
contains "$out" '--scf #808080' 'scrollbar foreground (muted)'

# --- Resolver absent: direct sed read of colors.toml ---
if PATH="$nobin" command -v omarchy-theme-color >/dev/null 2>&1; then
  fail 'resolver unexpectedly present on fallback PATH'
fi
dout=$(printf '' | PATH="$nobin" OMARCHY_THEME_COLORS="$tmp/colors.toml" "$bash_bin" "$wrapper")

contains "$dout" 'BEMENU:' 'direct-read selects bemenu'
contains "$dout" '--nb #111c18' 'direct-read background'
contains "$dout" '--ff #509475' 'direct-read accent'
contains "$dout" '--hb #32473b' 'direct-read selection_background'
contains "$dout" '--hf #f7e8b2' 'direct-read bright_foreground'
contains "$dout" '--ab #23372b' 'direct-read lighter_background'
contains "$dout" '--scb #090f0d' 'direct-read darker_background'
contains "$dout" '--fbf #53685b' 'direct-read muted'

# --- TTY stdin (selects bemenu-run) ---
if ! command -v script >/dev/null 2>&1; then
  fail 'pseudo-tty tool script is required for the TTY dispatch test'
fi
tty_out=$(PATH="$run_path" OMARCHY_THEME_COLORS="$tmp/colors.toml" \
  script -qec "bash \"$wrapper\"" /dev/null)
contains "$tty_out" 'BEMENU-RUN:' 'TTY stdin selects bemenu-run'

printf 'test-bemenu-themed: passed\n'

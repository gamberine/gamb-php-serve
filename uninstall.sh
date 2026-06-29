#!/usr/bin/env bash
set -euo pipefail

purge=0
while [ $# -gt 0 ]; do
  case "$1" in
    --purge)
      purge=1
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Uso:
  uninstall.sh
  uninstall.sh --purge
EOF
      exit 0
      ;;
    *)
      printf 'Argumento desconhecido: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

bin_dir="$HOME/.local/bin"
config_dir="$HOME/.config/gamb-php"
state_dir="$HOME/.local/state/gamb-php"
bashrc_file="$HOME/.bashrc"

rm -f \
  "$bin_dir/gamb-php-serve" \
  "$bin_dir/gamb-php-auto" \
  "$bin_dir/gamb-php-stop" \
  "$bin_dir/gamb-php-status" \
  "$bin_dir/gamb-php-list" \
  "$bin_dir/gamb-php-remove" \
  "$bin_dir/gamb-php-check"

if [ -f "$bashrc_file" ]; then
  tmp_file="${bashrc_file}.tmp.$$"
  awk '
    BEGIN { skip = 0 }
    /# >>> gamb-php-serve PATH >>>/ { skip = 1; next }
    /# <<< gamb-php-serve PATH <<</ { skip = 0; next }
    /# >>> gamb-php-serve HOOK >>>/ { skip = 1; next }
    /# <<< gamb-php-serve HOOK <<</ { skip = 0; next }
    skip == 0 { print }
  ' "$bashrc_file" > "$tmp_file"
  mv "$tmp_file" "$bashrc_file"
fi

if [ "$purge" -eq 1 ]; then
  rm -rf "$config_dir" "$state_dir"
fi

cat <<'EOF'
Desinstalação concluída.
EOF


#!/usr/bin/env bash
set -euo pipefail

GAMB_PHP_SERVE_REPO="${GAMB_PHP_SERVE_REPO:-https://raw.githubusercontent.com/gamberine/gamb-php-serve/main}"

script_dir=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -e "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

dest_bin_dir="$HOME/.local/bin"
dest_config_dir="$HOME/.config/gamb-php"
dest_lib_dir="$dest_config_dir/lib"
dest_share_dir="$dest_config_dir/share"
dest_dashboard_dir="$dest_share_dir/dashboard"
dest_assets_dir="$dest_share_dir/assets"
dest_state_dir="$HOME/.local/state/gamb-php"
dest_pids_dir="$dest_state_dir/pids"
dest_logs_dir="$dest_state_dir/logs"
dest_routers_dir="$dest_state_dir/routers"
projects_file="$dest_config_dir/projects.tsv"
projects_meta_file="$dest_config_dir/projects-meta.tsv"
bashrc_file="$HOME/.bashrc"
bash_profile_file=""

files_bin=(
  "bin/gamb-php-serve"
  "bin/gamb-php-auto"
  "bin/gamb-php-stop"
  "bin/gamb-php-status"
  "bin/gamb-php-list"
  "bin/gamb-php-remove"
  "bin/gamb-php-check"
)

files_lib=(
  "lib/gamb-php-common.sh"
)

files_share=(
  "share/dashboard/index.php"
  "docs/assets/dashboard.css"
  "docs/assets/dashboard.js"
  "docs/assets/hero-illustration.png"
)

ensure_dirs() {
  mkdir -p \
    "$dest_bin_dir" \
    "$dest_config_dir" \
    "$dest_lib_dir" \
    "$dest_dashboard_dir" \
    "$dest_assets_dir" \
    "$dest_pids_dir" \
    "$dest_logs_dir" \
    "$dest_routers_dir"
}

copy_local_or_remote() {
  local rel_path="$1"
  local dest_path="$2"
  local local_candidate=""

  if [ -n "$script_dir" ] && [ -f "$script_dir/$rel_path" ]; then
    local_candidate="$script_dir/$rel_path"
  fi

  if [ -n "$local_candidate" ]; then
    cp "$local_candidate" "$dest_path"
    return 0
  fi

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GAMB_PHP_SERVE_REPO/$rel_path" -o "$dest_path"
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$dest_path" "$GAMB_PHP_SERVE_REPO/$rel_path"
    return 0
  fi

  printf '%s\n' 'curl ou wget não encontrado para baixar os arquivos.' >&2
  exit 1
}

resolve_login_profile_file() {
  local candidate=""

  for candidate in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf '%s\n' "$HOME/.bash_profile"
}

append_block_if_missing() {
  local file="$1"
  local marker_start="$2"
  local marker_end="$3"
  local content="$4"

  if [ -f "$file" ] && grep -Fq "$marker_start" "$file"; then
    return 0
  fi

  {
    printf '\n%s\n' "$marker_start"
    printf '%s\n' "$content"
    printf '%s\n' "$marker_end"
  } >> "$file"
}

ensure_bashrc_path() {
  local marker_start="# >>> gamb-php-serve PATH >>>"
  local marker_end="# <<< gamb-php-serve PATH <<<"
  local content='export PATH="$HOME/.local/bin:$PATH"'
  touch "$bashrc_file"
  append_block_if_missing "$bashrc_file" "$marker_start" "$marker_end" "$content"
}

ensure_bashrc_hook() {
  local marker_start="# >>> gamb-php-serve HOOK >>>"
  local marker_end="# <<< gamb-php-serve HOOK <<<"
  local content='gamb_php_auto_hook() {
  command -v gamb-php-auto >/dev/null 2>&1 && gamb-php-auto
}

case ";$PROMPT_COMMAND;" in
  *"gamb_php_auto_hook"*) ;;
  *) PROMPT_COMMAND="gamb_php_auto_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac'
  touch "$bashrc_file"
  append_block_if_missing "$bashrc_file" "$marker_start" "$marker_end" "$content"
}

ensure_login_profile_sources_bashrc() {
  local marker_start="# >>> gamb-php-serve LOGIN PROFILE >>>"
  local marker_end="# <<< gamb-php-serve LOGIN PROFILE <<<"
  local content='[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
  touch "$bash_profile_file"
  append_block_if_missing "$bash_profile_file" "$marker_start" "$marker_end" "$content"
}

main() {
  ensure_dirs
  bash_profile_file="$(resolve_login_profile_file)"

  for rel_path in "${files_bin[@]}"; do
    copy_local_or_remote "$rel_path" "$dest_bin_dir/$(basename "$rel_path")"
  done

  for rel_path in "${files_lib[@]}"; do
    copy_local_or_remote "$rel_path" "$dest_lib_dir/$(basename "$rel_path")"
  done

  for rel_path in "${files_share[@]}"; do
    case "$rel_path" in
      share/dashboard/*)
        copy_local_or_remote "$rel_path" "$dest_dashboard_dir/$(basename "$rel_path")"
        ;;
      docs/assets/*)
        copy_local_or_remote "$rel_path" "$dest_assets_dir/$(basename "$rel_path")"
        ;;
    esac
  done

  chmod +x "$dest_bin_dir"/gamb-php-*
  chmod +x "$dest_lib_dir"/gamb-php-common.sh

  [ -f "$projects_file" ] || : > "$projects_file"
  [ -f "$projects_meta_file" ] || : > "$projects_meta_file"
  ensure_bashrc_path
  ensure_bashrc_hook
  ensure_login_profile_sources_bashrc

  cat <<EOF
Instalação concluída.

Próximos passos:
  source ~/.bashrc
  gamb-php-check
  gamb-php-serve
EOF
}

main "$@"

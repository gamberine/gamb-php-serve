#!/usr/bin/env bash

gamb_php_config_dir="${GAMB_PHP_CONFIG_DIR:-$HOME/.config/gamb-php}"
gamb_php_state_dir="${GAMB_PHP_STATE_DIR:-$HOME/.local/state/gamb-php}"
gamb_php_bin_dir="${GAMB_PHP_BIN_DIR:-$HOME/.local/bin}"
gamb_php_projects_file="${GAMB_PHP_PROJECTS_FILE:-$gamb_php_config_dir/projects.tsv}"
gamb_php_lib_install_dir="${GAMB_PHP_LIB_INSTALL_DIR:-$gamb_php_config_dir/lib}"
gamb_php_pids_dir="$gamb_php_state_dir/pids"
gamb_php_logs_dir="$gamb_php_state_dir/logs"
gamb_php_routers_dir="$gamb_php_state_dir/routers"

gamb_php_ensure_dirs() {
  mkdir -p \
    "$gamb_php_bin_dir" \
    "$gamb_php_config_dir" \
    "$gamb_php_lib_install_dir" \
    "$gamb_php_pids_dir" \
    "$gamb_php_logs_dir" \
    "$gamb_php_routers_dir"
}

gamb_php_current_dir() {
  pwd -P
}

gamb_php_norm_path() {
  local path="${1:-}"
  if [ -z "$path" ]; then
    printf '%s\n' ""
    return 0
  fi

  if command -v cygpath >/dev/null 2>&1; then
    case "$path" in
      /*) printf '%s\n' "$path" ;;
      *) cygpath -u "$path" 2>/dev/null || printf '%s\n' "$path" ;;
    esac
    return 0
  fi

  printf '%s\n' "$path"
}

gamb_php_slug_from_path() {
  local path="${1:-}"
  path="${path#./}"
  path="${path#/}"
  path="${path//\\//}"
  path="$(printf '%s' "$path" | sed -E 's#[[:space:]/:\\]+#-#g; s#-+#-#g; s#^-##; s#-$##')"
  if [ -z "$path" ]; then
    path="project"
  fi
  printf '%s\n' "$path"
}

gamb_php_router_file_for_slug() {
  printf '%s/%s-router.php\n' "$gamb_php_routers_dir" "$1"
}

gamb_php_pid_file_for_slug() {
  printf '%s/%s.pid\n' "$gamb_php_pids_dir" "$1"
}

gamb_php_log_file_for_slug() {
  printf '%s/%s.log\n' "$gamb_php_logs_dir" "$1"
}

gamb_php_detect_php() {
  if [ -n "${GAMB_PHP_BIN:-}" ]; then
    if [ -x "$GAMB_PHP_BIN" ] || command -v "$GAMB_PHP_BIN" >/dev/null 2>&1; then
      printf '%s\n' "$GAMB_PHP_BIN"
      return 0
    fi
  fi

  if command -v php >/dev/null 2>&1; then
    command -v php
    return 0
  fi

  local candidate
  for candidate in '/d/tools/php/php.exe' '/c/tools/php/php.exe' 'D:/tools/php/php.exe'; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

gamb_php_detect_composer() {
  command -v composer >/dev/null 2>&1
}

gamb_php_php_version_line() {
  local php_bin="${1:-}"
  if [ -z "$php_bin" ]; then
    return 1
  fi
  "$php_bin" -v 2>/dev/null | awk 'NR==1 { print; exit }'
}

gamb_php_port_available() {
  local php_bin="${1:-}"
  local host="${2:-127.0.0.1}"
  local port="${3:-8000}"
  "$php_bin" -r '
    $host = $argv[1];
    $port = $argv[2];
    $errno = 0;
    $errstr = "";
    $socket = @stream_socket_server("tcp://{$host}:{$port}", $errno, $errstr);
    if ($socket) {
      fclose($socket);
      exit(0);
    }
    exit(1);
  ' "$host" "$port" >/dev/null 2>&1
}

gamb_php_choose_port() {
  local php_bin="${1:-}"
  local host="${2:-127.0.0.1}"
  local start_port="${3:-8000}"
  local port

  for port in "$start_port" 8001 8002 8003 8004 8005; do
    if gamb_php_port_available "$php_bin" "$host" "$port"; then
      printf '%s\n' "$port"
      return 0
    fi
  done

  return 1
}

gamb_php_detect_project_root() {
  local start_dir
  start_dir="$(gamb_php_current_dir)"
  local dir="$start_dir"
  local parent

  while :; do
    if [ -f "$dir/artisan" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    if [ -f "$dir/public/index.php" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    if [ -f "$dir/wp-config.php" ] && [ -f "$dir/index.php" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    if [ -f "$dir/index.php" ]; then
      printf '%s\n' "$dir"
      return 0
    fi

    parent="$(dirname "$dir")"
    if [ "$parent" = "$dir" ]; then
      break
    fi
    dir="$parent"
  done

  return 1
}

gamb_php_detect_project_type() {
  local root="${1:-}"
  if [ -z "$root" ]; then
    return 1
  fi

  if [ -f "$root/artisan" ]; then
    printf '%s\t%s\t%s\n' 'laravel' "$root" "$root/artisan"
    return 0
  fi

  if [ -f "$root/public/index.php" ]; then
    printf '%s\t%s\t%s\n' 'php_public' "$root/public" "$root/public/index.php"
    return 0
  fi

  if [ -f "$root/wp-config.php" ] && [ -f "$root/index.php" ]; then
    printf '%s\t%s\t%s\n' 'wordpress' "$root" "$root/index.php"
    return 0
  fi

  if [ -f "$root/index.php" ]; then
    printf '%s\t%s\t%s\n' 'php_root' "$root" "$root/index.php"
    return 0
  fi

  return 1
}

gamb_php_read_registry_rows() {
  if [ ! -f "$gamb_php_projects_file" ]; then
    return 0
  fi

  cat "$gamb_php_projects_file"
}

gamb_php_find_registered_row_for_cwd() {
  local cwd="${1:-$(gamb_php_current_dir)}"
  local best_row=""
  local best_path=""
  local slug path type host port docroot index

  [ -f "$gamb_php_projects_file" ] || return 1

  while IFS=$'\t' read -r slug path type host port docroot index; do
    [ -z "${slug:-}" ] && continue
    case "$cwd" in
      "$path"|"$path"/*)
        if [ ${#path} -gt ${#best_path} ]; then
          best_path="$path"
          best_row="${slug}"$'\t'"${path}"$'\t'"${type}"$'\t'"${host}"$'\t'"${port}"$'\t'"${docroot}"$'\t'"${index}"
        fi
        ;;
    esac
  done < "$gamb_php_projects_file"

  if [ -n "$best_row" ]; then
    printf '%s\n' "$best_row"
    return 0
  fi

  return 1
}

gamb_php_get_registry_row_by_path() {
  local path="${1:-}"
  local slug reg_path type host port docroot index

  [ -f "$gamb_php_projects_file" ] || return 1

  while IFS=$'\t' read -r slug reg_path type host port docroot index; do
    [ -z "${slug:-}" ] && continue
    if [ "$reg_path" = "$path" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$slug" "$reg_path" "$type" "$host" "$port" "$docroot" "$index"
      return 0
    fi
  done < "$gamb_php_projects_file"

  return 1
}

gamb_php_registry_upsert_row() {
  local slug="$1"
  local path="$2"
  local type="$3"
  local host="$4"
  local port="$5"
  local docroot="$6"
  local index="$7"
  local tmp_file="${gamb_php_projects_file}.tmp.$$"
  local existing=0
  local row_slug row_path row_type row_host row_port row_docroot row_index

  mkdir -p "$gamb_php_config_dir"
  : > "$tmp_file"

  if [ -f "$gamb_php_projects_file" ]; then
    while IFS=$'\t' read -r row_slug row_path row_type row_host row_port row_docroot row_index; do
      [ -z "${row_slug:-}" ] && continue
      if [ "$row_path" = "$path" ]; then
        existing=1
        continue
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$row_slug" "$row_path" "$row_type" "$row_host" "$row_port" "$row_docroot" "$row_index" >> "$tmp_file"
    done < "$gamb_php_projects_file"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$slug" "$path" "$type" "$host" "$port" "$docroot" "$index" >> "$tmp_file"
  mv "$tmp_file" "$gamb_php_projects_file"
  return 0
}

gamb_php_registry_remove_path() {
  local path="$1"
  local tmp_file="${gamb_php_projects_file}.tmp.$$"
  local row_slug row_path row_type row_host row_port row_docroot row_index
  local removed=1

  [ -f "$gamb_php_projects_file" ] || return 1

  : > "$tmp_file"
  while IFS=$'\t' read -r row_slug row_path row_type row_host row_port row_docroot row_index; do
    [ -z "${row_slug:-}" ] && continue
    if [ "$row_path" = "$path" ]; then
      removed=0
      continue
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$row_slug" "$row_path" "$row_type" "$row_host" "$row_port" "$row_docroot" "$row_index" >> "$tmp_file"
  done < "$gamb_php_projects_file"

  mv "$tmp_file" "$gamb_php_projects_file"
  return "$removed"
}

gamb_php_pid_file_for_row() {
  local slug="$1"
  gamb_php_pid_file_for_slug "$slug"
}

gamb_php_log_file_for_row() {
  local slug="$1"
  gamb_php_log_file_for_slug "$slug"
}

gamb_php_router_file_for_row() {
  local slug="$1"
  gamb_php_router_file_for_slug "$slug"
}

gamb_php_pid_is_alive() {
  local pid="${1:-}"
  [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1
}

gamb_php_running_state_for_row() {
  local slug="$1"
  local pid_file
  pid_file="$(gamb_php_pid_file_for_row "$slug")"

  if [ -f "$pid_file" ]; then
    local pid
    pid="$(tr -d '[:space:]' < "$pid_file" 2>/dev/null || true)"
    if [ -n "$pid" ] && gamb_php_pid_is_alive "$pid"; then
      printf '%s\n' "$pid"
      return 0
    fi
    rm -f "$pid_file"
  fi

  return 1
}

gamb_php_write_router() {
  local router_file="$1"
  local docroot="$2"
  local index="$3"

  {
    printf '%s\n' '<?php'
    printf '%s\n' '$uri = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);'
    printf ' $docroot = "%s";\n' "$docroot"
    printf ' $index = "%s";\n\n' "$index"
    printf '%s\n' '$file = realpath($docroot . DIRECTORY_SEPARATOR . ltrim($uri, "/"));'
    printf '%s\n' ''
    printf '%s\n' 'if ($file && strpos($file, realpath($docroot)) === 0 && is_file($file)) {'
    printf '%s\n' '    return false;'
    printf '%s\n' '}'
    printf '%s\n' ''
    printf '%s\n' 'require $index;'
  } > "$router_file"
}

gamb_php_command_url() {
  local host="$1"
  local port="$2"
  printf 'http://%s:%s\n' "$host" "$port"
}

gamb_php_print_usage_serve() {
  cat <<'EOF'
Uso:
  gamb-php-serve
  gamb-php-serve --port 8080
  gamb-php-serve --foreground
  gamb-php-serve --help
EOF
}

gamb_php_print_usage_status() {
  cat <<'EOF'
Uso:
  gamb-php-status
  gamb-php-status --all
  gamb-php-status --help
EOF
}

gamb_php_print_usage_stop() {
  cat <<'EOF'
Uso:
  gamb-php-stop
  gamb-php-stop --all
  gamb-php-stop --help
EOF
}

gamb_php_print_usage_list() {
  cat <<'EOF'
Uso:
  gamb-php-list
  gamb-php-list --help
EOF
}

gamb_php_print_usage_remove() {
  cat <<'EOF'
Uso:
  gamb-php-remove
  gamb-php-remove --with-logs
  gamb-php-remove --help
EOF
}

gamb_php_print_usage_check() {
  cat <<'EOF'
Uso:
  gamb-php-check
  gamb-php-check --help
EOF
}

gamb_php_print_usage_auto() {
  cat <<'EOF'
Uso:
  gamb-php-auto
EOF
}

gamb_php_help_text_common() {
  cat <<'EOF'
Comandos:
  gamb-php-serve
  gamb-php-auto
  gamb-php-stop
  gamb-php-status
  gamb-php-list
  gamb-php-remove
  gamb-php-check
EOF
}

gamb_php_start_background_server() {
  local php_bin="$1"
  local type="$2"
  local host="$3"
  local port="$4"
  local root="$5"
  local docroot="$6"
  local index="$7"
  local slug="$8"
  local log_file="$9"
  local router_file="${10}"
  local pid=""
  local oldpwd=""

  if [ "$type" = "laravel" ]; then
    oldpwd="$PWD"
    cd "$root"
    if command -v nohup >/dev/null 2>&1; then
      nohup "$php_bin" artisan serve --host="$host" --port="$port" > "$log_file" 2>&1 &
    else
      "$php_bin" artisan serve --host="$host" --port="$port" > "$log_file" 2>&1 &
    fi
    pid="$!"
    cd "$oldpwd"
  else
    gamb_php_write_router "$router_file" "$docroot" "$index"
    if command -v nohup >/dev/null 2>&1; then
      nohup "$php_bin" -S "$host:$port" -t "$docroot" "$router_file" > "$log_file" 2>&1 &
    else
      "$php_bin" -S "$host:$port" -t "$docroot" "$router_file" > "$log_file" 2>&1 &
    fi
    pid="$!"
  fi

  printf '%s\n' "$pid"
}

gamb_php_start_foreground_server() {
  local php_bin="$1"
  local type="$2"
  local host="$3"
  local port="$4"
  local root="$5"
  local docroot="$6"
  local index="$7"
  local router_file="$8"

  if [ "$type" = "laravel" ]; then
    cd "$root"
    exec "$php_bin" artisan serve --host="$host" --port="$port"
  fi

  gamb_php_write_router "$router_file" "$docroot" "$index"
  exec "$php_bin" -S "$host:$port" -t "$docroot" "$router_file"
}

gamb_php_format_row() {
  local slug="$1"
  local path="$2"
  local type="$3"
  local host="$4"
  local port="$5"
  local docroot="$6"
  local index="$7"
  local pid="${8:-}"
  local url
  url="$(gamb_php_command_url "$host" "$port")"

  printf 'Slug: %s\n' "$slug"
  printf 'Caminho: %s\n' "$path"
  printf 'Tipo: %s\n' "$type"
  printf 'Host: %s\n' "$host"
  printf 'Porta: %s\n' "$port"
  printf 'URL: %s\n' "$url"
  if [ -n "$pid" ]; then
    printf 'PID: %s\n' "$pid"
    printf 'Rodando: sim\n'
  else
    printf 'PID: -\n'
    printf 'Rodando: não\n'
  fi
  printf 'Docroot: %s\n' "$docroot"
  printf 'Index: %s\n' "$index"
  printf 'Log: %s\n' "$(gamb_php_log_file_for_row "$slug")"
  printf 'Router: %s\n' "$(gamb_php_router_file_for_row "$slug")"
}

gamb_php_start_registered_project() {
  local cwd="${1:-$(gamb_php_current_dir)}"
  local requested_port="${2:-}"
  local foreground="${3:-0}"
  local quiet="${4:-0}"
  local php_bin=""
  local row=""
  local slug=""
  local root=""
  local type=""
  local host=""
  local port=""
  local docroot=""
  local index=""
  local pid_file=""
  local log_file=""
  local router_file=""
  local pid=""
  local chosen_port=""
  local type_row=""
  local start_port=""
  local existing_port=""

  if ! php_bin="$(gamb_php_detect_php)"; then
    if [ "$quiet" -eq 0 ]; then
      printf '%s\n' 'PHP não encontrado.'
      printf '%s\n' 'Configure o PHP no PATH ou defina:'
      printf '%s\n' 'export GAMB_PHP_BIN="/d/tools/php/php.exe"'
    fi
    return 1
  fi

  if row="$(gamb_php_find_registered_row_for_cwd "$cwd")"; then
    IFS=$'\t' read -r slug root type host port docroot index <<<"$row"
    existing_port="$port"
    if [ -n "$requested_port" ]; then
      port="$requested_port"
    fi
  else
    if ! root="$(gamb_php_detect_project_root)"; then
      if [ "$quiet" -eq 0 ]; then
        printf '%s\n' 'Nenhuma estrutura PHP reconhecida neste projeto.'
        printf '%s\n' 'Esperado: artisan, public/index.php, wp-config.php + index.php ou index.php.'
      fi
      return 1
    fi

    type_row="$(gamb_php_detect_project_type "$root")" || {
      if [ "$quiet" -eq 0 ]; then
        printf '%s\n' 'Nenhuma estrutura PHP reconhecida neste projeto.'
        printf '%s\n' 'Esperado: artisan, public/index.php, wp-config.php + index.php ou index.php.'
      fi
      return 1
    }
    IFS=$'\t' read -r type docroot index <<<"$type_row"

    host="127.0.0.1"
    port="${requested_port:-8000}"
    slug="$(gamb_php_slug_from_path "$root")"
  fi

  slug="${slug:-$(gamb_php_slug_from_path "$root")}"
  host="${host:-127.0.0.1}"

  pid_file="$(gamb_php_pid_file_for_row "$slug")"
  log_file="$(gamb_php_log_file_for_row "$slug")"
  router_file="$(gamb_php_router_file_for_row "$slug")"

  if [ -f "$pid_file" ]; then
    pid="$(tr -d '[:space:]' < "$pid_file" 2>/dev/null || true)"
    if [ -n "$pid" ] && gamb_php_pid_is_alive "$pid"; then
      if [ "$quiet" -eq 0 ]; then
        printf 'Projeto já está rodando em %s\n' "$(gamb_php_command_url "$host" "${existing_port:-$port}")"
      fi
      return 0
    fi
    rm -f "$pid_file"
  fi

  chosen_port="$port"
  if ! gamb_php_port_available "$php_bin" "$host" "$chosen_port"; then
    start_port="${requested_port:-8000}"
    chosen_port="$(gamb_php_choose_port "$php_bin" "$host" "$start_port")"
  fi

  port="$chosen_port"
  gamb_php_registry_upsert_row "$slug" "$root" "$type" "$host" "$port" "$docroot" "$index"

  if [ "$foreground" -eq 1 ]; then
    if [ "$quiet" -eq 0 ]; then
      printf 'Projeto registrado em %s\n' "$root"
      printf 'URL: %s\n' "$(gamb_php_command_url "$host" "$port")"
    fi
    gamb_php_start_foreground_server "$php_bin" "$type" "$host" "$port" "$root" "$docroot" "$index" "$router_file"
  fi

  pid="$(gamb_php_start_background_server "$php_bin" "$type" "$host" "$port" "$root" "$docroot" "$index" "$slug" "$log_file" "$router_file")"
  printf '%s\n' "$pid" > "$pid_file"

  if [ "$quiet" -eq 0 ]; then
    printf 'Projeto registrado em %s\n' "$root"
    printf 'URL: %s\n' "$(gamb_php_command_url "$host" "$port")"
    printf 'PID: %s\n' "$pid"
  fi
}

gamb_php_stop_project_by_row() {
  local slug="$1"
  local host="$2"
  local port="$3"
  local pid_file log_file router_file pid
  pid_file="$(gamb_php_pid_file_for_row "$slug")"
  log_file="$(gamb_php_log_file_for_row "$slug")"
  router_file="$(gamb_php_router_file_for_row "$slug")"

  if [ -f "$pid_file" ]; then
    pid="$(tr -d '[:space:]' < "$pid_file" 2>/dev/null || true)"
    if [ -n "$pid" ]; then
      kill "$pid" >/dev/null 2>&1 || true
      if gamb_php_pid_is_alive "$pid"; then
        kill -9 "$pid" >/dev/null 2>&1 || true
      fi
    fi
    rm -f "$pid_file"
  fi

  [ -f "$router_file" ] && rm -f "$router_file"

  printf '%s\n' "$slug"
}

gamb_php_all_rows() {
  gamb_php_read_registry_rows
}

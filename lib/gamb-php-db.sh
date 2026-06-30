#!/usr/bin/env bash

gamb_php_db_config_dir="${GAMB_PHP_DB_CONFIG_DIR:-$gamb_php_config_dir/db}"
gamb_php_db_state_dir="${GAMB_PHP_DB_STATE_DIR:-$gamb_php_state_dir/db}"
gamb_php_db_pids_dir="$gamb_php_db_state_dir/pids"
gamb_php_db_logs_dir="$gamb_php_db_state_dir/logs"
gamb_php_db_meta_dir="$gamb_php_db_state_dir/meta"

gamb_php_db_ensure_dirs() {
  mkdir -p \
    "$gamb_php_db_config_dir" \
    "$gamb_php_db_state_dir" \
    "$gamb_php_db_pids_dir" \
    "$gamb_php_db_logs_dir" \
    "$gamb_php_db_meta_dir"
}

gamb_php_db_pid_file_for_profile() {
  printf '%s/%s.pid\n' "$gamb_php_db_pids_dir" "$1"
}

gamb_php_db_log_file_for_profile() {
  printf '%s/%s.log\n' "$gamb_php_db_logs_dir" "$1"
}

gamb_php_db_stderr_log_file_for_profile() {
  printf '%s/%s.stderr.log\n' "$gamb_php_db_logs_dir" "$1"
}

gamb_php_db_meta_file_for_profile() {
  printf '%s/%s.tsv\n' "$gamb_php_db_meta_dir" "$1"
}

gamb_php_db_windows_path() {
  local path="${1:-}"
  if [ -z "$path" ]; then
    printf '%s\n' ""
    return 0
  fi

  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$path" 2>/dev/null || printf '%s\n' "$path"
    return 0
  fi

  printf '%s\n' "$path"
}

gamb_php_db_windows_cmd_path() {
  local path="${1:-}"
  if [ -z "$path" ]; then
    printf '%s\n' ""
    return 0
  fi

  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$path" 2>/dev/null || gamb_php_db_windows_path "$path"
    return 0
  fi

  gamb_php_db_windows_path "$path"
}

gamb_php_db_default_scan_roots() {
  cat <<'EOF'
/d/ProjetosWeb/wamp64/bin
/c/ProjetosWeb/wamp64/bin
/d/wamp64/bin
/c/wamp64/bin
/d/laragon/bin
/c/laragon/bin
/d/ProjetosWeb/laragon/bin
/c/ProjetosWeb/laragon/bin
/d/xampp/mysql
/c/xampp/mysql
/d/tools/mysql
/c/tools/mysql
EOF
}

gamb_php_db_scan_roots() {
  if [ -n "${GAMB_PHP_DB_SCAN_ROOTS:-}" ]; then
    printf '%s' "$GAMB_PHP_DB_SCAN_ROOTS" | tr ';' '\n' | awk 'NF && !seen[$0]++'
    return 0
  fi

  gamb_php_db_default_scan_roots | awk 'NF && !seen[$0]++'
}

gamb_php_db_find_config_files() {
  local root=""

  while IFS= read -r root; do
    [ -n "$root" ] || continue
    [ -d "$root" ] || continue
    find "$root" -maxdepth 5 \( -iname 'my.ini' -o -iname 'my.cnf' \) 2>/dev/null
  done < <(gamb_php_db_scan_roots) | awk 'NF' | sort -f
}

gamb_php_db_ini_value() {
  local file_path="${1:-}"
  local key_name="${2:-}"

  [ -f "$file_path" ] || return 1
  [ -n "$key_name" ] || return 1

  awk -v target="$(printf '%s' "$key_name" | tr '[:upper:]' '[:lower:]')" '
    /^[[:space:]]*[#;]/ { next }
    {
      line = $0
      sub(/\r$/, "", line)
      key = line
      sub(/=.*/, "", key)
      key = tolower(key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key != target) {
        next
      }

      value = line
      sub(/^[^=]*=/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^["'\''"]|["'\''"]$/, "", value)
      print value
      exit
    }
  ' "$file_path"
}

gamb_php_db_origin_from_path() {
  local path_lower
  path_lower="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"

  case "$path_lower" in
    *"/wamp64/"*) printf '%s\n' 'wamp64' ;;
    *"/laragon/"*) printf '%s\n' 'laragon' ;;
    *"/xampp/"*) printf '%s\n' 'xampp' ;;
    *) printf '%s\n' 'local' ;;
  esac
}

gamb_php_db_engine_from_reference() {
  local ref_lower
  ref_lower="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"

  case "$ref_lower" in
    *"mariadb"*|*"mariadbd"*) printf '%s\n' 'mariadb' ;;
    *"mysql"*) printf '%s\n' 'mysql' ;;
    *) return 1 ;;
  esac
}

gamb_php_db_version_from_dir() {
  local engine="${1:-}"
  local dir_path="${2:-}"
  local dir_name=""
  local version=""

  dir_name="$(basename "$dir_path")"
  case "$engine" in
    mariadb)
      version="${dir_name#mariadb}"
      ;;
    mysql)
      version="${dir_name#mysql}"
      ;;
    *)
      version="$dir_name"
      ;;
  esac

  version="${version#-}"
  version="${version#_}"
  version="${version#.}"
  version="$(printf '%s' "$version" | sed -E 's/[^0-9.]+/-/g; s/^-+//; s/-+$//')"
  [ -n "$version" ] || version="manual"
  printf '%s\n' "$version"
}

gamb_php_db_version_key() {
  local version="${1:-0}"
  local cleaned=""
  cleaned="$(printf '%s' "$version" | sed -E 's/[^0-9.]+/./g; s/\.+/./g; s/^\.//; s/\.$//')"
  awk -v raw="$cleaned" 'BEGIN {
    split(raw, parts, ".")
    for (i = 1; i <= 5; i++) {
      value = parts[i]
      if (value !~ /^[0-9]+$/) {
        value = 0
      }
      printf "%05d", value
      if (i < 5) {
        printf "."
      }
    }
    printf "\n"
  }'
}

gamb_php_db_display_name() {
  local engine="${1:-}"
  local origin="${2:-}"
  local version="${3:-}"
  local label=""

  case "$engine" in
    mysql) label="MySQL" ;;
    mariadb) label="MariaDB" ;;
    *) label="Banco local" ;;
  esac

  if [ -n "$origin" ] && [ "$origin" != "local" ]; then
    label="$label $origin"
  fi

  if [ -n "$version" ] && [ "$version" != "manual" ]; then
    label="$label $version"
  fi

  printf '%s\n' "$label"
}

gamb_php_db_resolve_server_bin() {
  local engine="${1:-}"
  local base_dir="${2:-}"
  local basedir="${3:-}"
  local candidate=""

  if [ "$engine" = "mariadb" ]; then
    for candidate in \
      "$base_dir/bin/mariadbd.exe" \
      "$base_dir/bin/mysqld.exe" \
      "$base_dir/mariadbd.exe" \
      "$base_dir/mysqld.exe" \
      "$basedir/bin/mariadbd.exe" \
      "$basedir/bin/mysqld.exe" \
      "$basedir/mariadbd.exe" \
      "$basedir/mysqld.exe"; do
      [ -f "$candidate" ] || continue
      printf '%s\n' "$candidate"
      return 0
    done
  fi

  for candidate in \
    "$base_dir/bin/mysqld.exe" \
    "$base_dir/mysqld.exe" \
    "$basedir/bin/mysqld.exe" \
    "$basedir/mysqld.exe"; do
    [ -f "$candidate" ] || continue
    printf '%s\n' "$candidate"
    return 0
  done

  if [ "$engine" = "mariadb" ] && command -v mariadbd >/dev/null 2>&1; then
    command -v mariadbd
    return 0
  fi

  if command -v mysqld >/dev/null 2>&1; then
    command -v mysqld
    return 0
  fi

  return 1
}

gamb_php_db_resolve_admin_bin() {
  local engine="${1:-}"
  local base_dir="${2:-}"
  local basedir="${3:-}"
  local candidate=""

  if [ "$engine" = "mariadb" ]; then
    for candidate in \
      "$base_dir/bin/mariadb-admin.exe" \
      "$base_dir/bin/mysqladmin.exe" \
      "$base_dir/mariadb-admin.exe" \
      "$base_dir/mysqladmin.exe" \
      "$basedir/bin/mariadb-admin.exe" \
      "$basedir/bin/mysqladmin.exe" \
      "$basedir/mariadb-admin.exe" \
      "$basedir/mysqladmin.exe"; do
      [ -f "$candidate" ] || continue
      printf '%s\n' "$candidate"
      return 0
    done
  fi

  for candidate in \
    "$base_dir/bin/mysqladmin.exe" \
    "$base_dir/mysqladmin.exe" \
    "$basedir/bin/mysqladmin.exe" \
    "$basedir/mysqladmin.exe"; do
    [ -f "$candidate" ] || continue
    printf '%s\n' "$candidate"
    return 0
  done

  if [ "$engine" = "mariadb" ] && command -v mariadb-admin >/dev/null 2>&1; then
    command -v mariadb-admin
    return 0
  fi

  if command -v mysqladmin >/dev/null 2>&1; then
    command -v mysqladmin
    return 0
  fi

  return 1
}

gamb_php_db_profile_row_from_ini() {
  local defaults_file="${1:-}"
  local base_dir=""
  local engine=""
  local basedir=""
  local server_bin=""
  local admin_bin=""
  local port=""
  local datadir=""
  local log_error=""
  local origin=""
  local version=""
  local profile=""
  local label=""

  [ -f "$defaults_file" ] || return 1

  defaults_file="$(gamb_php_norm_path "$defaults_file")"
  base_dir="$(dirname "$defaults_file")"
  engine="$(gamb_php_db_engine_from_reference "$defaults_file" 2>/dev/null || true)"
  [ -n "$engine" ] || return 1

  basedir="$(gamb_php_db_ini_value "$defaults_file" "basedir" 2>/dev/null || true)"
  [ -n "$basedir" ] && basedir="$(gamb_php_norm_path "$basedir")"

  server_bin="$(gamb_php_db_resolve_server_bin "$engine" "$base_dir" "$basedir" 2>/dev/null || true)"
  [ -n "$server_bin" ] || return 1
  admin_bin="$(gamb_php_db_resolve_admin_bin "$engine" "$base_dir" "$basedir" 2>/dev/null || true)"

  port="$(gamb_php_db_ini_value "$defaults_file" "port" 2>/dev/null || true)"
  if [ -z "$port" ]; then
    if [ "$engine" = "mysql" ]; then
      port="3306"
    else
      port="3307"
    fi
  fi

  datadir="$(gamb_php_db_ini_value "$defaults_file" "datadir" 2>/dev/null || true)"
  [ -n "$datadir" ] && datadir="$(gamb_php_norm_path "$datadir")"

  log_error="$(gamb_php_db_ini_value "$defaults_file" "log_error" 2>/dev/null || true)"
  [ -n "$log_error" ] && log_error="$(gamb_php_norm_path "$log_error")"

  origin="$(gamb_php_db_origin_from_path "$defaults_file")"
  version="$(gamb_php_db_version_from_dir "$engine" "$base_dir")"
  profile="$(gamb_php_slug_from_path "$engine-$origin-$version")"
  label="$(gamb_php_db_display_name "$engine" "$origin" "$version")"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$profile" \
    "$engine" \
    "$label" \
    "$origin" \
    "$server_bin" \
    "$defaults_file" \
    "$port" \
    "$datadir" \
    "$admin_bin" \
    "$basedir" \
    "$log_error" \
    "$version"
}

gamb_php_db_env_profile_row() {
  local server_bin="${GAMB_PHP_DB_BIN:-}"
  local defaults_file="${GAMB_PHP_DB_DEFAULTS_FILE:-}"
  local engine="${GAMB_PHP_DB_ENGINE:-}"
  local basedir=""
  local admin_bin=""
  local port=""
  local datadir=""
  local log_error=""
  local label=""

  [ -n "$server_bin" ] || return 1
  [ -n "$defaults_file" ] || return 1

  server_bin="$(gamb_php_norm_path "$server_bin")"
  defaults_file="$(gamb_php_norm_path "$defaults_file")"
  [ -f "$defaults_file" ] || return 1
  [ -f "$server_bin" ] || return 1

  if [ -z "$engine" ]; then
    engine="$(gamb_php_db_engine_from_reference "$server_bin" 2>/dev/null || true)"
  fi
  [ -n "$engine" ] || engine="mysql"

  basedir="$(gamb_php_db_ini_value "$defaults_file" "basedir" 2>/dev/null || true)"
  [ -n "$basedir" ] && basedir="$(gamb_php_norm_path "$basedir")"

  admin_bin="$(gamb_php_db_resolve_admin_bin "$engine" "$(dirname "$defaults_file")" "$basedir" 2>/dev/null || true)"
  port="$(gamb_php_db_ini_value "$defaults_file" "port" 2>/dev/null || true)"
  [ -n "$port" ] || port="${GAMB_PHP_DB_PORT:-3306}"
  datadir="$(gamb_php_db_ini_value "$defaults_file" "datadir" 2>/dev/null || true)"
  [ -n "$datadir" ] && datadir="$(gamb_php_norm_path "$datadir")"
  log_error="$(gamb_php_db_ini_value "$defaults_file" "log_error" 2>/dev/null || true)"
  [ -n "$log_error" ] && log_error="$(gamb_php_norm_path "$log_error")"
  label="$(gamb_php_db_display_name "$engine" "manual" "manual")"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "env-$engine" \
    "$engine" \
    "$label" \
    "manual" \
    "$server_bin" \
    "$defaults_file" \
    "$port" \
    "$datadir" \
    "$admin_bin" \
    "$basedir" \
    "$log_error" \
    "manual"
}

gamb_php_db_detect_profiles() {
  {
    gamb_php_db_env_profile_row 2>/dev/null || true
    while IFS= read -r defaults_file; do
      [ -n "$defaults_file" ] || continue
      gamb_php_db_profile_row_from_ini "$defaults_file" 2>/dev/null || true
    done < <(gamb_php_db_find_config_files)
  } | awk -F '\t' '!seen[$1]++'
}

gamb_php_db_state_row_for_profile() {
  local profile="${1:-}"
  local state_file=""

  [ -n "$profile" ] || return 1
  state_file="$(gamb_php_db_meta_file_for_profile "$profile")"
  [ -f "$state_file" ] || return 1
  cat "$state_file"
}

gamb_php_db_write_state_row() {
  local row="${1:-}"
  local profile=""
  local state_file=""

  [ -n "$row" ] || return 1
  IFS=$'\t' read -r profile _rest <<EOF
$row
EOF
  [ -n "$profile" ] || return 1
  state_file="$(gamb_php_db_meta_file_for_profile "$profile")"
  printf '%s\n' "$row" > "$state_file"
}

gamb_php_db_clear_profile_state() {
  local profile="${1:-}"
  [ -n "$profile" ] || return 1
  rm -f "$(gamb_php_db_pid_file_for_profile "$profile")"
  rm -f "$(gamb_php_db_meta_file_for_profile "$profile")"
}

gamb_php_db_all_profiles_with_state() {
  {
    gamb_php_db_detect_profiles
    if [ -d "$gamb_php_db_meta_dir" ]; then
      local state_file=""
      for state_file in "$gamb_php_db_meta_dir"/*.tsv; do
        [ -f "$state_file" ] || continue
        cat "$state_file"
      done
    fi
  } | awk -F '\t' '!seen[$1]++'
}

gamb_php_db_target_matches() {
  local target="${1:-}"
  local profile="${2:-}"
  local engine="${3:-}"

  case "$target" in
    ""|auto|all) return 0 ;;
    mysql|mariadb) [ "$engine" = "$target" ] ;;
    *) [ "$profile" = "$target" ] ;;
  esac
}

gamb_php_db_candidate_score() {
  local target="${1:-}"
  local engine="${2:-}"
  local port="${3:-}"
  local score=0

  if [ -z "$target" ] || [ "$target" = "auto" ]; then
    if [ "$engine" = "mysql" ]; then
      score=400
    elif [ "$engine" = "mariadb" ]; then
      score=300
    else
      score=100
    fi
  elif [ "$target" = "mysql" ] || [ "$target" = "mariadb" ]; then
    score=500
  else
    score=600
  fi

  if [ "$port" = "3306" ]; then
    score=$((score + 30))
  elif [ "$port" = "3307" ]; then
    score=$((score + 20))
  fi

  printf '%s\n' "$score"
}

gamb_php_db_select_profile_from_stream() {
  local target="${1:-}"
  local best_row=""
  local best_score=""
  local best_version_key=""
  local row=""
  local profile=""
  local engine=""
  local label=""
  local origin=""
  local server_bin=""
  local defaults_file=""
  local port=""
  local datadir=""
  local admin_bin=""
  local basedir=""
  local log_error=""
  local version=""
  local score=""
  local version_key=""

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    IFS=$'\t' read -r profile engine label origin server_bin defaults_file port datadir admin_bin basedir log_error version <<EOF
$row
EOF
    [ -n "$profile" ] || continue
    gamb_php_db_target_matches "$target" "$profile" "$engine" || continue
    score="$(gamb_php_db_candidate_score "$target" "$engine" "$port")"
    version_key="$(gamb_php_db_version_key "$version")"

    if [ -z "$best_row" ] || [ "$score" -gt "$best_score" ] || { [ "$score" -eq "$best_score" ] && [[ "$version_key" > "$best_version_key" ]]; }; then
      best_row="$row"
      best_score="$score"
      best_version_key="$version_key"
    fi
  done

  [ -n "$best_row" ] || return 1
  printf '%s\n' "$best_row"
}

gamb_php_db_select_detected_profile() {
  local target="${1:-${GAMB_PHP_DB_PROFILE:-}}"
  gamb_php_db_detect_profiles | gamb_php_db_select_profile_from_stream "$target"
}

gamb_php_db_select_any_profile() {
  local target="${1:-${GAMB_PHP_DB_PROFILE:-}}"
  gamb_php_db_all_profiles_with_state | gamb_php_db_select_profile_from_stream "$target"
}

gamb_php_db_pid_is_alive() {
  local pid="${1:-}"
  local output=""

  [ -n "$pid" ] || return 1

  if command -v tasklist.exe >/dev/null 2>&1; then
    output="$(MSYS2_ARG_CONV_EXCL='*' tasklist.exe /FI "PID eq $pid" /FO CSV /NH 2>/dev/null | tr -d '\r' || true)"
    case "$output" in
      ""|*"No tasks are running which match the specified criteria."*|*"nenhuma tarefa em execu"*)
        return 1
        ;;
      *)
        return 0
        ;;
    esac
  fi

  kill -0 "$pid" >/dev/null 2>&1
}

gamb_php_db_listener_pid_for_port() {
  local port="${1:-}"
  [ -n "$port" ] || return 1

  netstat -ano -p tcp 2>/dev/null | awk -v port=":$port" '
    tolower($1) == "tcp" && $2 ~ port "$" && toupper($4) == "LISTENING" {
      print $5
      exit
    }
  '
}

gamb_php_db_managed_pid_for_profile() {
  local profile="${1:-}"
  local pid_file=""
  local pid=""

  [ -n "$profile" ] || return 1

  pid_file="$(gamb_php_db_pid_file_for_profile "$profile")"
  if [ -f "$pid_file" ]; then
    pid="$(tr -d '[:space:]' < "$pid_file" 2>/dev/null || true)"
    if [ -n "$pid" ] && gamb_php_db_pid_is_alive "$pid"; then
      printf '%s\n' "$pid"
      return 0
    fi
    gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
  fi

  return 1
}

gamb_php_db_running_state_for_profile() {
  local profile="${1:-}"
  local port="${2:-}"
  local pid=""

  pid="$(gamb_php_db_managed_pid_for_profile "$profile" 2>/dev/null || true)"
  if [ -n "$pid" ]; then
    printf 'managed\t%s\n' "$pid"
    return 0
  fi

  pid="$(gamb_php_db_listener_pid_for_port "$port" 2>/dev/null || true)"
  if [ -n "$pid" ]; then
    printf 'external\t%s\n' "$pid"
    return 0
  fi

  printf 'stopped\t-\n'
}

gamb_php_db_tail_log() {
  local log_file="${1:-}"
  [ -f "$log_file" ] || return 1

  if command -v tail >/dev/null 2>&1; then
    tail -n 20 "$log_file" 2>/dev/null || true
    return 0
  fi

  cat "$log_file" 2>/dev/null || true
}

gamb_php_db_extract_server_pid_from_log() {
  local log_file="${1:-}"
  [ -f "$log_file" ] || return 1

  sed -En 's/.*starting as process ([0-9]+).*/\1/p' "$log_file" | tail -n 1
}

gamb_php_db_start_process() {
  local server_bin="${1:-}"
  local defaults_file="${2:-}"
  local stdout_log="${3:-}"
  local stderr_log="${4:-}"

  [ -n "$server_bin" ] || return 1
  [ -n "$defaults_file" ] || return 1

  if command -v nohup >/dev/null 2>&1; then
    nohup "$server_bin" "--defaults-file=$(gamb_php_db_windows_path "$defaults_file")" --console > "$stdout_log" 2> "$stderr_log" &
  else
    "$server_bin" "--defaults-file=$(gamb_php_db_windows_path "$defaults_file")" --console > "$stdout_log" 2> "$stderr_log" &
  fi
  disown >/dev/null 2>&1 || true
  return 0
}

gamb_php_db_start_windows_and_wait() {
  local server_bin="${1:-}"
  local defaults_file="${2:-}"
  local stdout_log="${3:-}"
  local stderr_log="${4:-}"
  local port="${5:-}"
  local timeout="${6:-35}"
  local server_bin_win=""
  local defaults_win=""
  local pid=""

  command -v powershell.exe >/dev/null 2>&1 || return 1
  [ -n "$server_bin" ] || return 1
  [ -n "$defaults_file" ] || return 1
  [ -n "$port" ] || return 1

  server_bin_win="$(gamb_php_db_windows_path "$server_bin")"
  defaults_win="$(gamb_php_db_windows_path "$defaults_file")"
  : "${stdout_log:=}"
  : "${stderr_log:=}"

  pid="$(
    GAMB_PHP_DB_SERVER_BIN_WIN="$server_bin_win" \
    GAMB_PHP_DB_DEFAULTS_WIN="$defaults_win" \
    GAMB_PHP_DB_PORT="$port" \
    GAMB_PHP_DB_START_TIMEOUT="$timeout" \
    powershell.exe -NoProfile -Command '
      $argsList = @("--defaults-file=" + $env:GAMB_PHP_DB_DEFAULTS_WIN, "--console")
      Start-Process -FilePath $env:GAMB_PHP_DB_SERVER_BIN_WIN -ArgumentList $argsList -WindowStyle Hidden | Out-Null
      $limit = [int]$env:GAMB_PHP_DB_START_TIMEOUT
      $deadline = (Get-Date).AddSeconds($limit)
      while ((Get-Date) -lt $deadline) {
        $connection = Get-NetTCPConnection -LocalPort ([int]$env:GAMB_PHP_DB_PORT) -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($connection) {
          [Console]::Out.WriteLine($connection.OwningProcess)
          exit 0
        }

        $line = netstat -ano -p tcp | Select-String (":" + $env:GAMB_PHP_DB_PORT + "\s+") | Select-Object -First 1
        if ($line -and $line.Line -match "LISTENING\s+(\d+)$") {
          [Console]::Out.WriteLine($Matches[1])
          exit 0
        }

        Start-Sleep -Seconds 1
      }

      exit 1
    ' 2>/dev/null | tr -d '\r' | sed -n '1p'
  )"

  [ -n "$pid" ] || return 1
  printf '%s\n' "$pid"
}

gamb_php_db_format_profile() {
  local profile="${1:-}"
  local engine="${2:-}"
  local label="${3:-}"
  local origin="${4:-}"
  local server_bin="${5:-}"
  local defaults_file="${6:-}"
  local port="${7:-}"
  local datadir="${8:-}"
  local admin_bin="${9:-}"
  local basedir="${10:-}"
  local log_error="${11:-}"
  local state_kind="${12:-stopped}"
  local pid="${13:-}"

  printf 'Perfil: %s\n' "$profile"
  printf 'Nome: %s\n' "$label"
  printf 'Engine: %s\n' "$engine"
  printf 'Origem: %s\n' "$origin"
  printf 'Porta: %s\n' "$port"
  case "$state_kind" in
    managed)
      printf 'Rodando: sim (gerenciado)\n'
      printf 'PID: %s\n' "$pid"
      ;;
    external)
      printf 'Rodando: sim (externo)\n'
      printf 'PID: %s\n' "$pid"
      ;;
    *)
      printf 'Rodando: nao\n'
      printf 'PID: -\n'
      ;;
  esac
  printf 'Executavel: %s\n' "$server_bin"
  printf 'Config: %s\n' "$defaults_file"
  printf 'Base dir: %s\n' "${basedir:--}"
  printf 'Data dir: %s\n' "${datadir:--}"
  printf 'Log do banco: %s\n' "${log_error:--}"
  printf 'Log do modulo: %s\n' "$(gamb_php_db_log_file_for_profile "$profile")"
}

gamb_php_db_print_usage_check() {
  cat <<'EOF'
Uso:
  gamb-php-db-check
  gamb-php-db-check --help
EOF
}

gamb_php_db_print_usage_status() {
  cat <<'EOF'
Uso:
  gamb-php-db-status
  gamb-php-db-status mysql
  gamb-php-db-status mariadb
  gamb-php-db-status --profile mysql-wamp64-8.0.31
  gamb-php-db-status --help
EOF
}

gamb_php_db_print_usage_start() {
  cat <<'EOF'
Uso:
  gamb-php-db-start
  gamb-php-db-start mysql
  gamb-php-db-start mariadb
  gamb-php-db-start --profile mysql-wamp64-8.0.31
  gamb-php-db-start --foreground
  gamb-php-db-start --help
EOF
}

gamb_php_db_print_usage_stop() {
  cat <<'EOF'
Uso:
  gamb-php-db-stop
  gamb-php-db-stop all
  gamb-php-db-stop mysql
  gamb-php-db-stop mariadb
  gamb-php-db-stop --profile mysql-wamp64-8.0.31
  gamb-php-db-stop --help
EOF
}

gamb_php_db_check() {
  local rows=""
  local row=""
  local suggested=""
  local count=0
  local profile=""
  local engine=""
  local label=""
  local origin=""
  local server_bin=""
  local defaults_file=""
  local port=""
  local datadir=""
  local admin_bin=""
  local basedir=""
  local log_error=""
  local version=""
  local state_kind=""
  local pid=""

  gamb_php_db_ensure_dirs
  rows="$(gamb_php_db_detect_profiles)"

  printf 'Raizes de busca:\n'
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    printf '  - %s\n' "$row"
  done < <(gamb_php_db_scan_roots)

  if [ -z "$rows" ]; then
    printf '\n%s\n' 'Perfis detectados: 0'
    printf '%s\n' 'Nenhum MySQL/MariaDB local foi encontrado nas raizes configuradas.'
    return 0
  fi

  suggested="$(gamb_php_db_select_detected_profile 2>/dev/null || true)"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    count=$((count + 1))
  done <<EOF
$rows
EOF

  printf '\nPerfis detectados: %s\n' "$count"
  if [ -n "$suggested" ]; then
    IFS=$'\t' read -r profile engine label origin server_bin defaults_file port datadir admin_bin basedir log_error version <<EOF
$suggested
EOF
    printf 'Perfil sugerido: %s (%s)\n' "$profile" "$label"
  fi

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    IFS=$'\t' read -r profile engine label origin server_bin defaults_file port datadir admin_bin basedir log_error version <<EOF
$row
EOF
    IFS=$'\t' read -r state_kind pid <<EOF
$(gamb_php_db_running_state_for_profile "$profile" "$port")
EOF
    printf '\n'
    gamb_php_db_format_profile "$profile" "$engine" "$label" "$origin" "$server_bin" "$defaults_file" "$port" "$datadir" "$admin_bin" "$basedir" "$log_error" "$state_kind" "$pid"
  done <<EOF
$rows
EOF
}

gamb_php_db_status() {
  local target="${1:-}"
  local rows=""
  local row=""
  local matched=0
  local profile=""
  local engine=""
  local label=""
  local origin=""
  local server_bin=""
  local defaults_file=""
  local port=""
  local datadir=""
  local admin_bin=""
  local basedir=""
  local log_error=""
  local version=""
  local state_kind=""
  local pid=""

  gamb_php_db_ensure_dirs
  rows="$(gamb_php_db_all_profiles_with_state)"

  [ -n "$rows" ] || {
    printf '%s\n' 'Nenhum perfil de banco conhecido foi encontrado.'
    return 0
  }

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    IFS=$'\t' read -r profile engine label origin server_bin defaults_file port datadir admin_bin basedir log_error version <<EOF
$row
EOF
    gamb_php_db_target_matches "$target" "$profile" "$engine" || continue
    matched=1
    IFS=$'\t' read -r state_kind pid <<EOF
$(gamb_php_db_running_state_for_profile "$profile" "$port")
EOF
    gamb_php_db_format_profile "$profile" "$engine" "$label" "$origin" "$server_bin" "$defaults_file" "$port" "$datadir" "$admin_bin" "$basedir" "$log_error" "$state_kind" "$pid"
    printf '\n'
  done <<EOF
$rows
EOF

  [ "$matched" -eq 1 ] || {
    printf 'Nenhum perfil corresponde a: %s\n' "$target" >&2
    return 1
  }
}

gamb_php_db_start() {
  local target="${1:-}"
  local foreground="${2:-0}"
  local row=""
  local profile=""
  local engine=""
  local label=""
  local origin=""
  local server_bin=""
  local defaults_file=""
  local port=""
  local datadir=""
  local admin_bin=""
  local basedir=""
  local log_error=""
  local version=""
  local state_kind=""
  local pid=""
  local pid_file=""
  local state_file=""
  local log_file=""
  local stderr_log=""
  local startup_timeout="${GAMB_PHP_DB_START_TIMEOUT:-35}"
  local listener_pid=""
  local attempt=0
  local actual_pid=""

  gamb_php_db_ensure_dirs
  row="$(gamb_php_db_select_detected_profile "$target" 2>/dev/null || true)"
  [ -n "$row" ] || {
    if [ -n "$target" ]; then
      printf 'Nenhum perfil de banco foi encontrado para: %s\n' "$target" >&2
    else
      printf '%s\n' 'Nenhum perfil MySQL/MariaDB local foi detectado.' >&2
    fi
    return 1
  }

  IFS=$'\t' read -r profile engine label origin server_bin defaults_file port datadir admin_bin basedir log_error version <<EOF
$row
EOF
  IFS=$'\t' read -r state_kind pid <<EOF
$(gamb_php_db_running_state_for_profile "$profile" "$port")
EOF

  if [ "$state_kind" = "managed" ]; then
    printf '%s\n' 'Banco ja esta rodando.'
    gamb_php_db_format_profile "$profile" "$engine" "$label" "$origin" "$server_bin" "$defaults_file" "$port" "$datadir" "$admin_bin" "$basedir" "$log_error" "$state_kind" "$pid"
    return 0
  fi

  if [ "$state_kind" = "external" ]; then
    printf '%s\n' 'A porta do perfil escolhido ja esta ocupada por um processo externo.'
    gamb_php_db_format_profile "$profile" "$engine" "$label" "$origin" "$server_bin" "$defaults_file" "$port" "$datadir" "$admin_bin" "$basedir" "$log_error" "$state_kind" "$pid"
    return 1
  fi

  pid_file="$(gamb_php_db_pid_file_for_profile "$profile")"
  state_file="$(gamb_php_db_meta_file_for_profile "$profile")"
  log_file="$(gamb_php_db_log_file_for_profile "$profile")"
  stderr_log="$(gamb_php_db_stderr_log_file_for_profile "$profile")"

  gamb_php_db_write_state_row "$row"

  if [ "$foreground" -eq 1 ]; then
    printf 'Perfil: %s\n' "$profile"
    printf 'Log do modulo: %s\n' "$log_file"
    exec "$server_bin" "--defaults-file=$(gamb_php_db_windows_path "$defaults_file")" --console
  fi

  if command -v powershell.exe >/dev/null 2>&1; then
    pid="$(gamb_php_db_start_windows_and_wait "$server_bin" "$defaults_file" "$log_file" "$stderr_log" "$port" "$startup_timeout" 2>/dev/null || true)"
    if [ -n "$pid" ]; then
      printf '%s\n' "$row" > "$state_file"
      printf '%s\n' "$pid" > "$pid_file"
      printf '%s\n' 'Banco iniciado.'
      gamb_php_db_format_profile "$profile" "$engine" "$label" "$origin" "$server_bin" "$defaults_file" "$port" "$datadir" "$admin_bin" "$basedir" "$log_error" "managed" "$pid"
      return 0
    fi

    gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
    printf '%s\n' 'Falha ao iniciar o banco.' >&2
    if [ -f "$log_file" ]; then
      printf 'Ultimas linhas de %s:\n' "$log_file" >&2
      gamb_php_db_tail_log "$log_file" >&2 || true
    fi
    if [ -n "$log_error" ] && [ -f "$log_error" ]; then
      printf 'Ultimas linhas de %s:\n' "$log_error" >&2
      gamb_php_db_tail_log "$log_error" >&2 || true
    fi
    return 1
  fi

  if ! gamb_php_db_start_process "$server_bin" "$defaults_file" "$log_file" "$stderr_log" >/dev/null 2>&1; then
    gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
    printf '%s\n' 'Falha ao iniciar o processo do banco.' >&2
    return 1
  fi
  printf '%s\n' "$row" > "$state_file"

  while [ "$attempt" -lt "$startup_timeout" ]; do
    listener_pid="$(gamb_php_db_listener_pid_for_port "$port" 2>/dev/null || true)"
    actual_pid="$(gamb_php_db_extract_server_pid_from_log "$log_file" 2>/dev/null || true)"
    if [ -z "$actual_pid" ] && [ -n "$log_error" ]; then
      actual_pid="$(gamb_php_db_extract_server_pid_from_log "$log_error" 2>/dev/null || true)"
    fi

    if [ -n "$actual_pid" ] && gamb_php_db_pid_is_alive "$actual_pid"; then
      printf '%s\n' "$actual_pid" > "$pid_file"
    fi

    if [ -n "$listener_pid" ] && gamb_php_db_pid_is_alive "$listener_pid"; then
      printf '%s\n' "$listener_pid" > "$pid_file"
      break
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  if [ -z "$listener_pid" ]; then
    gamb_php_db_stop_profile_row "$row" >/dev/null 2>&1 || true
    gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
    printf '%s\n' 'Falha ao iniciar o banco.' >&2
    if [ -f "$log_file" ]; then
      printf 'Ultimas linhas de %s:\n' "$log_file" >&2
      gamb_php_db_tail_log "$log_file" >&2 || true
    fi
    return 1
  fi

  IFS=$'\t' read -r state_kind pid <<EOF
$(gamb_php_db_running_state_for_profile "$profile" "$port")
EOF
  if [ "$state_kind" = "managed" ] || [ "$state_kind" = "external" ]; then
    printf '%s\n' 'Banco iniciado.'
    gamb_php_db_format_profile "$profile" "$engine" "$label" "$origin" "$server_bin" "$defaults_file" "$port" "$datadir" "$admin_bin" "$basedir" "$log_error" "$state_kind" "$pid"
    return 0
  fi

  gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
  printf '%s\n' 'Falha ao iniciar o banco.' >&2
  if [ -f "$log_file" ]; then
    printf 'Ultimas linhas de %s:\n' "$log_file" >&2
    gamb_php_db_tail_log "$log_file" >&2 || true
  fi
  return 1
}

gamb_php_db_managed_profiles() {
  local pid_file=""
  if [ ! -d "$gamb_php_db_pids_dir" ]; then
    return 0
  fi

  for pid_file in "$gamb_php_db_pids_dir"/*.pid; do
    [ -f "$pid_file" ] || continue
    basename "$pid_file" .pid
  done | sort
}

gamb_php_db_stop_profile_row() {
  local row="${1:-}"
  local profile=""
  local engine=""
  local label=""
  local origin=""
  local server_bin=""
  local defaults_file=""
  local port=""
  local datadir=""
  local admin_bin=""
  local basedir=""
  local log_error=""
  local version=""
  local pid=""

  [ -n "$row" ] || return 1
  IFS=$'\t' read -r profile engine label origin server_bin defaults_file port datadir admin_bin basedir log_error version <<EOF
$row
EOF
  [ -n "$profile" ] || return 1

  pid="$(gamb_php_db_managed_pid_for_profile "$profile" 2>/dev/null || true)"
  if [ -z "$pid" ]; then
    local external_pid=""
    external_pid="$(gamb_php_db_listener_pid_for_port "$port" 2>/dev/null || true)"
    if [ -n "$external_pid" ]; then
      printf 'Perfil %s esta rodando externamente e nao sera interrompido.\n' "$profile"
      return 1
    fi
    gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
    printf 'Perfil %s ja estava parado.\n' "$profile"
    return 0
  fi

  if [ -n "$admin_bin" ] && [ -f "$admin_bin" ] && [ -n "$port" ]; then
    "$admin_bin" "--host=127.0.0.1" "--port=$port" --protocol=tcp -u root shutdown >/dev/null 2>&1 || true
    sleep 2
  fi

  if gamb_php_db_pid_is_alive "$pid"; then
    if command -v taskkill.exe >/dev/null 2>&1; then
      MSYS2_ARG_CONV_EXCL='*' taskkill.exe /PID "$pid" /T >/dev/null 2>&1 || true
      sleep 2
      if gamb_php_db_pid_is_alive "$pid"; then
        MSYS2_ARG_CONV_EXCL='*' taskkill.exe /PID "$pid" /T /F >/dev/null 2>&1 || true
      fi
    else
      kill "$pid" >/dev/null 2>&1 || true
      sleep 2
      gamb_php_db_pid_is_alive "$pid" && kill -9 "$pid" >/dev/null 2>&1 || true
    fi
  fi

  if gamb_php_db_pid_is_alive "$pid"; then
    printf 'Falha ao parar o perfil %s.\n' "$profile" >&2
    return 1
  fi

  gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
  printf 'Perfil %s parado.\n' "$profile"
}

gamb_php_db_stop() {
  local target="${1:-all}"
  local profile=""
  local row=""
  local managed_count=0
  local exit_code=0

  gamb_php_db_ensure_dirs

  if [ -z "$target" ] || [ "$target" = "all" ]; then
    while IFS= read -r profile; do
      [ -n "$profile" ] || continue
      managed_count=$((managed_count + 1))
      row="$(gamb_php_db_state_row_for_profile "$profile" 2>/dev/null || true)"
      [ -n "$row" ] || row="$(gamb_php_db_select_any_profile "$profile" 2>/dev/null || true)"
      if [ -z "$row" ]; then
        gamb_php_db_clear_profile_state "$profile" >/dev/null 2>&1 || true
        continue
      fi
      gamb_php_db_stop_profile_row "$row" || exit_code=1
    done < <(gamb_php_db_managed_profiles)

    if [ "$managed_count" -eq 0 ]; then
      printf '%s\n' 'Nenhum banco gerenciado pelo modulo esta rodando.'
    fi
    return "$exit_code"
  fi

  row="$(gamb_php_db_select_any_profile "$target" 2>/dev/null || true)"
  [ -n "$row" ] || {
    printf 'Nenhum perfil corresponde a: %s\n' "$target" >&2
    return 1
  }

  gamb_php_db_stop_profile_row "$row"
}

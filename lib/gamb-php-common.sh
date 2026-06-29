#!/usr/bin/env bash

gamb_php_config_dir="${GAMB_PHP_CONFIG_DIR:-$HOME/.config/gamb-php}"
gamb_php_state_dir="${GAMB_PHP_STATE_DIR:-$HOME/.local/state/gamb-php}"
gamb_php_bin_dir="${GAMB_PHP_BIN_DIR:-$HOME/.local/bin}"
gamb_php_projects_file="${GAMB_PHP_PROJECTS_FILE:-$gamb_php_config_dir/projects.tsv}"
gamb_php_projects_meta_file="${GAMB_PHP_PROJECTS_META_FILE:-$gamb_php_config_dir/projects-meta.tsv}"
gamb_php_lib_install_dir="${GAMB_PHP_LIB_INSTALL_DIR:-$gamb_php_config_dir/lib}"
gamb_php_share_dir="${GAMB_PHP_SHARE_DIR:-$gamb_php_config_dir/share}"
gamb_php_dashboard_dir="${GAMB_PHP_DASHBOARD_DIR:-$gamb_php_share_dir/dashboard}"
gamb_php_assets_dir="${GAMB_PHP_ASSETS_DIR:-$gamb_php_share_dir/assets}"
gamb_php_pids_dir="$gamb_php_state_dir/pids"
gamb_php_logs_dir="$gamb_php_state_dir/logs"
gamb_php_routers_dir="$gamb_php_state_dir/routers"

gamb_php_ensure_dirs() {
  mkdir -p \
    "$gamb_php_bin_dir" \
    "$gamb_php_config_dir" \
    "$gamb_php_lib_install_dir" \
    "$gamb_php_dashboard_dir" \
    "$gamb_php_assets_dir" \
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

gamb_php_path_for_php_runtime() {
  local path="${1:-}"
  local php_bin="${2:-}"
  local php_family=""

  if [ -z "$path" ]; then
    printf '%s\n' ""
    return 0
  fi

  if [ -n "$php_bin" ]; then
    php_family="$("$php_bin" -r 'echo PHP_OS_FAMILY;' 2>/dev/null || true)"
    if [ "$php_family" = "Windows" ] && command -v cygpath >/dev/null 2>&1; then
      cygpath -m "$path" 2>/dev/null || printf '%s\n' "$path"
      return 0
    fi
  fi

  printf '%s\n' "$path"
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

gamb_php_read_meta_rows() {
  if [ ! -f "$gamb_php_projects_meta_file" ]; then
    return 0
  fi

  cat "$gamb_php_projects_meta_file"
}

gamb_php_touch_project_last_used() {
  local path="${1:-}"
  local tmp_file="${gamb_php_projects_meta_file}.tmp.$$"
  local now=""
  local row_path row_timestamp

  [ -n "$path" ] || return 1
  mkdir -p "$gamb_php_config_dir"
  now="$(date +%s 2>/dev/null || true)"
  [ -n "$now" ] || now="0"

  : > "$tmp_file"
  if [ -f "$gamb_php_projects_meta_file" ]; then
    while IFS=$'\t' read -r row_path row_timestamp; do
      [ -z "${row_path:-}" ] && continue
      if [ "$row_path" = "$path" ]; then
        continue
      fi
      printf '%s\t%s\n' "$row_path" "$row_timestamp" >> "$tmp_file"
    done < "$gamb_php_projects_meta_file"
  fi

  printf '%s\t%s\n' "$path" "$now" >> "$tmp_file"
  mv "$tmp_file" "$gamb_php_projects_meta_file"
}

gamb_php_remove_project_meta() {
  local path="${1:-}"
  local tmp_file="${gamb_php_projects_meta_file}.tmp.$$"
  local row_path row_timestamp

  [ -n "$path" ] || return 1
  [ -f "$gamb_php_projects_meta_file" ] || return 0

  : > "$tmp_file"
  while IFS=$'\t' read -r row_path row_timestamp; do
    [ -z "${row_path:-}" ] && continue
    if [ "$row_path" = "$path" ]; then
      continue
    fi
    printf '%s\t%s\n' "$row_path" "$row_timestamp" >> "$tmp_file"
  done < "$gamb_php_projects_meta_file"

  mv "$tmp_file" "$gamb_php_projects_meta_file"
}

gamb_php_find_registered_rows_for_cwd() {
  local cwd="${1:-$(gamb_php_current_dir)}"
  local best_path=""
  local slug path type host port docroot index

  [ -f "$gamb_php_projects_file" ] || return 1

  while IFS=$'\t' read -r slug path type host port docroot index; do
    [ -z "${slug:-}" ] && continue
    case "$cwd" in
      "$path"|"$path"/*)
        if [ ${#path} -gt ${#best_path} ]; then
          best_path="$path"
        fi
        ;;
    esac
  done < "$gamb_php_projects_file"

  [ -n "$best_path" ] || return 1

  while IFS=$'\t' read -r slug path type host port docroot index; do
    [ -z "${slug:-}" ] && continue
    if [ "$path" = "$best_path" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$slug" "$path" "$type" "$host" "$port" "$docroot" "$index"
    fi
  done < "$gamb_php_projects_file"
}

gamb_php_find_registered_row_for_cwd() {
  local cwd="${1:-$(gamb_php_current_dir)}"
  local rows=""
  local row=""

  rows="$(gamb_php_find_registered_rows_for_cwd "$cwd" 2>/dev/null || true)"
  [ -n "$rows" ] || return 1

  while IFS= read -r row; do
    [ -z "$row" ] && continue
    printf '%s\n' "$row"
    return 0
  done <<EOF
$rows
EOF

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

gamb_php_get_registry_row_by_path_port() {
  local path="${1:-}"
  local port="${2:-}"
  local slug reg_path type host reg_port docroot index

  [ -f "$gamb_php_projects_file" ] || return 1

  while IFS=$'\t' read -r slug reg_path type host reg_port docroot index; do
    [ -z "${slug:-}" ] && continue
    if [ "$reg_path" = "$path" ] && [ "$reg_port" = "$port" ]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$slug" "$reg_path" "$type" "$host" "$reg_port" "$docroot" "$index"
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
      if [ "$row_path" = "$path" ] && [ "$row_port" = "$port" ]; then
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
  gamb_php_remove_project_meta "$path" >/dev/null 2>&1 || true
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
  local root="$2"
  local docroot="$3"
  local index="$4"
  local php_bin="${5:-}"
  local base_path="${6:-}"
  local slug="${7:-}"
  local host="${8:-127.0.0.1}"
  local port="${9:-8000}"
  local runtime_root=""
  local runtime_docroot=""
  local runtime_index=""
  local runtime_base_path=""
  local runtime_dashboard_entry=""
  local runtime_assets_dir=""
  local runtime_config_dir=""
  local runtime_state_dir=""
  local runtime_bin_dir=""
  local runtime_project_url=""
  local runtime_dashboard_url=""
  local live_reload_enabled="true"

  runtime_root="$(gamb_php_path_for_php_runtime "$root" "$php_bin")"
  runtime_docroot="$(gamb_php_path_for_php_runtime "$docroot" "$php_bin")"
  runtime_index="$(gamb_php_path_for_php_runtime "$index" "$php_bin")"
  runtime_base_path="$(gamb_php_normalize_base_path "$base_path")"
  runtime_dashboard_entry="$(gamb_php_path_for_php_runtime "$gamb_php_dashboard_dir/index.php" "$php_bin")"
  runtime_assets_dir="$(gamb_php_path_for_php_runtime "$gamb_php_assets_dir" "$php_bin")"
  runtime_config_dir="$(gamb_php_path_for_php_runtime "$gamb_php_config_dir" "$php_bin")"
  runtime_state_dir="$(gamb_php_path_for_php_runtime "$gamb_php_state_dir" "$php_bin")"
  runtime_bin_dir="$(gamb_php_path_for_php_runtime "$gamb_php_bin_dir" "$php_bin")"
  runtime_project_url="$(gamb_php_command_url "$host" "$port" "$base_path")"
  runtime_dashboard_url="$(gamb_php_dashboard_url "$host" "$port" "$base_path")"

  if [ "${GAMB_PHP_NO_LIVE_RELOAD:-0}" = "1" ]; then
    live_reload_enabled="false"
  fi

  cat > "$router_file" <<EOF
<?php
\$uri = rawurldecode(parse_url(\$_SERVER["REQUEST_URI"] ?? "/", PHP_URL_PATH) ?? "/");
\$projectRoot = "${runtime_root}";
\$docroot = "${runtime_docroot}";
\$index = "${runtime_index}";
\$basePath = "${runtime_base_path}";
\$projectSlug = "${slug}";
\$projectHost = "${host}";
\$projectPort = "${port}";
\$dashboardEntry = "${runtime_dashboard_entry}";
\$dashboardAssetsDir = "${runtime_assets_dir}";
\$dashboardConfigDir = "${runtime_config_dir}";
\$dashboardStateDir = "${runtime_state_dir}";
\$dashboardBinDir = "${runtime_bin_dir}";
\$projectUrl = "${runtime_project_url}";
\$dashboardUrl = "${runtime_dashboard_url}";
\$liveReloadEnabled = ${live_reload_enabled};
\$reloadStatusPath = (\$basePath !== "" ? \$basePath : "") . "/__gamb_php__/reload";
\$reloadScriptPath = (\$basePath !== "" ? \$basePath : "") . "/__gamb_php__/reload.js";
\$dashboardBasePath = (\$basePath !== "" ? \$basePath : "") . "/__gamb_php__/hub";

function gambPhpResponseContentType(): string
{
    foreach (headers_list() as \$header) {
        if (stripos(\$header, "Content-Type:") === 0) {
            return trim(substr(\$header, 13));
        }
    }

    return "";
}

function gambPhpShouldInjectHtml(string \$output): bool
{
    \$status = http_response_code();
    if (\$status >= 300 && \$status < 400) {
        return false;
    }

    \$contentType = gambPhpResponseContentType();
    if (\$contentType !== "") {
        return stripos(\$contentType, "text/html") !== false;
    }

    \$trimmed = ltrim(\$output);
    if (\$trimmed === "") {
        return false;
    }

    return (bool) preg_match("/<(?:!DOCTYPE\\s+html|html\\b)/i", \$trimmed);
}

function gambPhpInjectReloadScript(string \$output, string \$scriptPath): string
{
    if (strpos(\$output, "data-gamb-php-reload=") !== false) {
        return \$output;
    }

    \$scriptTag = '<script src="' . htmlspecialchars(\$scriptPath, ENT_QUOTES, "UTF-8") . '" data-gamb-php-reload="1" defer></script>';
    if (stripos(\$output, "</body>") !== false) {
        return preg_replace("/<\\/body>/i", \$scriptTag . "</body>", \$output, 1) ?? (\$output . \$scriptTag);
    }

    return \$output . \$scriptTag;
}

function gambPhpDetectMimeType(string \$file): string
{
    \$extension = strtolower(pathinfo(\$file, PATHINFO_EXTENSION));
    \$mapped = match (\$extension) {
        "css" => "text/css; charset=UTF-8",
        "js", "mjs", "cjs" => "application/javascript; charset=UTF-8",
        "json", "map" => "application/json; charset=UTF-8",
        "svg" => "image/svg+xml",
        "png" => "image/png",
        "jpg", "jpeg" => "image/jpeg",
        "gif" => "image/gif",
        "webp" => "image/webp",
        "woff" => "font/woff",
        "woff2" => "font/woff2",
        "ttf" => "font/ttf",
        "otf" => "font/otf",
        "webm" => "video/webm",
        "mp4" => "video/mp4",
        "ico" => "image/x-icon",
        default => "",
    };

    if (\$mapped !== "") {
        return \$mapped;
    }

    if (function_exists("mime_content_type")) {
        \$mime = @mime_content_type(\$file);
        if (is_string(\$mime) && \$mime !== "") {
            return \$mime;
        }
    }

    return "application/octet-stream";
}

function gambPhpServeStaticFile(string \$file): void
{
    header("Content-Type: " . gambPhpDetectMimeType(\$file));
    header("Content-Length: " . (string) filesize(\$file));
    header("Cache-Control: no-store");
    readfile(\$file);
}

function gambPhpIsExcludedDir(string \$path): bool
{
    static \$excluded = [
        ".git" => true,
        ".idea" => true,
        ".vscode" => true,
        "node_modules" => true,
        "vendor" => true,
        "storage" => true,
        "cache" => true,
        "logs" => true,
        "tmp" => true,
        "temp" => true,
        "uploads" => true,
    ];

    return isset(\$excluded[strtolower(\$path)]);
}

function gambPhpShouldWatchFile(SplFileInfo \$file): bool
{
    \$name = strtolower(\$file->getFilename());
    if (\$name === ".env" || strpos(\$name, ".env.") === 0) {
        return true;
    }

    foreach ([
        ".php",
        ".phtml",
        ".html",
        ".htm",
        ".css",
        ".js",
        ".jsx",
        ".ts",
        ".tsx",
        ".mjs",
        ".cjs",
        ".vue",
        ".json",
        ".xml",
        ".yml",
        ".yaml",
        ".twig",
        ".svg",
        ".ini",
        ".txt",
        ".md",
    ] as \$suffix) {
        if (substr(\$name, -strlen(\$suffix)) === \$suffix) {
            return true;
        }
    }

    return false;
}

function gambPhpReloadSignature(string \$root): string
{
    if (!is_dir(\$root)) {
        return "0";
    }

    \$rootReal = realpath(\$root);
    if (\$rootReal === false) {
        return "0";
    }

    \$hash = hash_init("sha1");
    \$count = 0;
    \$latest = 0;

    \$directory = new RecursiveDirectoryIterator(\$rootReal, FilesystemIterator::SKIP_DOTS);
    \$filter = new RecursiveCallbackFilterIterator(\$directory, static function (SplFileInfo \$item) {
        if (\$item->isDir()) {
            return !gambPhpIsExcludedDir(\$item->getFilename());
        }

        return true;
    });
    \$iterator = new RecursiveIteratorIterator(\$filter, RecursiveIteratorIterator::LEAVES_ONLY);

    foreach (\$iterator as \$item) {
        if (!\$item->isFile() || !gambPhpShouldWatchFile(\$item)) {
            continue;
        }

        \$path = \$item->getPathname();
        \$mtime = \$item->getMTime();
        \$size = \$item->getSize();
        \$latest = max(\$latest, \$mtime);
        \$count++;
        hash_update(\$hash, substr(\$path, strlen(\$rootReal)) . "|" . \$mtime . "|" . \$size . "\\n");
    }

    return \$latest . "-" . \$count . "-" . substr(hash_final(\$hash), 0, 12);
}

function gambPhpServeReloadStatus(string \$root): void
{
    header("Content-Type: application/json; charset=UTF-8");
    header("Cache-Control: no-store, no-cache, must-revalidate");
    echo json_encode(["token" => gambPhpReloadSignature(\$root)], JSON_UNESCAPED_SLASHES);
}

function gambPhpServeReloadScript(string \$statusPath): void
{
    header("Content-Type: application/javascript; charset=UTF-8");
    header("Cache-Control: no-store, no-cache, must-revalidate");

    echo str_replace(
        "__STATUS_PATH__",
        json_encode(\$statusPath, JSON_UNESCAPED_SLASHES),
        <<<'JS'
(function () {
  if (window.top !== window.self) return;
  if (window.__gambPhpReloadInit) return;
  window.__gambPhpReloadInit = true;

  var statusUrl = __STATUS_PATH__;
  var currentToken = null;

  function schedulePoll() {
    window.setTimeout(poll, 1200);
  }

  function poll() {
    fetch(statusUrl, {
      cache: "no-store",
      headers: { "X-Gamb-PHP-Reload": "1" }
    })
      .then(function (response) {
        if (!response.ok) throw new Error("reload");
        return response.json();
      })
      .then(function (payload) {
        if (!payload || typeof payload.token !== "string") {
          schedulePoll();
          return;
        }

        if (currentToken === null) {
          currentToken = payload.token;
          schedulePoll();
          return;
        }

        if (payload.token !== currentToken) {
          currentToken = payload.token;
          window.location.reload();
          return;
        }

        schedulePoll();
      })
      .catch(function () {
        schedulePoll();
      });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", schedulePoll, { once: true });
  } else {
    schedulePoll();
  }
})();
JS
    );
}

function gambPhpExecutePhpFile(string \$targetFile, string \$uri, string \$docroot): void
{
    \$oldCwd = getcwd();
    \$oldScriptFilename = \$_SERVER["SCRIPT_FILENAME"] ?? null;
    \$oldScriptName = \$_SERVER["SCRIPT_NAME"] ?? null;
    \$oldPhpSelf = \$_SERVER["PHP_SELF"] ?? null;
    \$oldDocumentRoot = \$_SERVER["DOCUMENT_ROOT"] ?? null;

    \$_SERVER["SCRIPT_FILENAME"] = \$targetFile;
    \$_SERVER["SCRIPT_NAME"] = \$uri;
    \$_SERVER["PHP_SELF"] = \$uri;
    \$_SERVER["DOCUMENT_ROOT"] = \$docroot;

    \$targetDir = dirname(\$targetFile);
    if (\$targetDir !== "" && is_dir(\$targetDir)) {
        @chdir(\$targetDir);
    }

    try {
        require \$targetFile;
    } finally {
        if (\$oldScriptFilename === null) {
            unset(\$_SERVER["SCRIPT_FILENAME"]);
        } else {
            \$_SERVER["SCRIPT_FILENAME"] = \$oldScriptFilename;
        }

        if (\$oldScriptName === null) {
            unset(\$_SERVER["SCRIPT_NAME"]);
        } else {
            \$_SERVER["SCRIPT_NAME"] = \$oldScriptName;
        }

        if (\$oldPhpSelf === null) {
            unset(\$_SERVER["PHP_SELF"]);
        } else {
            \$_SERVER["PHP_SELF"] = \$oldPhpSelf;
        }

        if (\$oldDocumentRoot === null) {
            unset(\$_SERVER["DOCUMENT_ROOT"]);
        } else {
            \$_SERVER["DOCUMENT_ROOT"] = \$oldDocumentRoot;
        }

        if (is_string(\$oldCwd) && \$oldCwd !== "") {
            @chdir(\$oldCwd);
        }
    }
}

function gambPhpServeDashboard(
    string \$dashboardEntry,
    string \$dashboardBasePath,
    string \$uri,
    string \$projectRoot,
    string \$projectSlug,
    string \$projectHost,
    string \$projectPort,
    string \$projectUrl,
    string \$dashboardUrl,
    string \$assetsDir,
    string \$configDir,
    string \$stateDir,
    string \$binDir
): bool {
    if (\$dashboardEntry === "" || !is_file(\$dashboardEntry)) {
        return false;
    }

    if (\$uri !== \$dashboardBasePath && strpos(\$uri, \$dashboardBasePath . "/") !== 0) {
        return false;
    }

    \$GLOBALS["gambPhpDashboardContext"] = [
        "dashboardBasePath" => \$dashboardBasePath,
        "requestUri" => \$uri,
        "projectRoot" => \$projectRoot,
        "projectSlug" => \$projectSlug,
        "projectHost" => \$projectHost,
        "projectPort" => \$projectPort,
        "projectUrl" => \$projectUrl,
        "dashboardUrl" => \$dashboardUrl,
        "assetsDir" => \$assetsDir,
        "configDir" => \$configDir,
        "stateDir" => \$stateDir,
        "binDir" => \$binDir,
    ];

    require \$dashboardEntry;
    return true;
}

if (\$liveReloadEnabled && \$uri === \$reloadStatusPath) {
    gambPhpServeReloadStatus(\$projectRoot);
    return true;
}

if (\$liveReloadEnabled && \$uri === \$reloadScriptPath) {
    gambPhpServeReloadScript(\$reloadStatusPath);
    return true;
}

if (gambPhpServeDashboard(
    \$dashboardEntry,
    \$dashboardBasePath,
    \$uri,
    \$projectRoot,
    \$projectSlug,
    \$projectHost,
    \$projectPort,
    \$projectUrl,
    \$dashboardUrl,
    \$dashboardAssetsDir,
    \$dashboardConfigDir,
    \$dashboardStateDir,
    \$dashboardBinDir
)) {
    return true;
}

\$effectiveUri = \$uri;
if (\$basePath !== "") {
    if (\$uri === "/" || \$uri === "") {
        header("Location: " . \$basePath);
        return true;
    }

    if (\$uri === \$basePath) {
        \$effectiveUri = "/";
    } elseif (strpos(\$uri, \$basePath . "/") === 0) {
        \$effectiveUri = substr(\$uri, strlen(\$basePath));
        if (\$effectiveUri === false || \$effectiveUri === "") {
            \$effectiveUri = "/";
        }
    } else {
        http_response_code(404);
        echo "Not Found";
        return true;
    }
}

\$docrootReal = realpath(\$docroot);
\$requestPath = (\$docrootReal ?: \$docroot) . DIRECTORY_SEPARATOR . ltrim(str_replace("\\\\", "/", \$effectiveUri), "/");
\$file = realpath(\$requestPath);
\$entryFile = \$index;

if (\$file !== false && \$docrootReal !== false && strpos(\$file, \$docrootReal) === 0 && is_file(\$file)) {
    if (strtolower(pathinfo(\$file, PATHINFO_EXTENSION)) !== "php") {
        if (\$basePath === "") {
            return false;
        }

        gambPhpServeStaticFile(\$file);
        return true;
    }

    \$entryFile = \$file;
}

ob_start();
gambPhpExecutePhpFile(\$entryFile, \$uri, \$docroot);
\$output = ob_get_clean();

if (\$liveReloadEnabled && gambPhpShouldInjectHtml(\$output)) {
    \$output = gambPhpInjectReloadScript(\$output, \$reloadScriptPath);
}

echo \$output;
return true;
EOF
}

gamb_php_command_url() {
  local host="$1"
  local port="$2"
  local base_path="${3:-}"
  base_path="$(gamb_php_normalize_base_path "$base_path")"
  printf 'http://%s:%s%s\n' "$(gamb_php_display_host "$host")" "$port" "$base_path"
}

gamb_php_dashboard_url() {
  local host="$1"
  local port="$2"
  local base_path="${3:-}"
  local normalized=""
  normalized="$(gamb_php_normalize_base_path "$base_path")"
  printf '%s/__gamb_php__/hub\n' "$(gamb_php_command_url "$host" "$port" "$normalized")"
}

gamb_php_open_browser() {
  local url="${1:-}"

  [ -n "$url" ] || return 1
  [ "${GAMB_PHP_NO_BROWSER:-0}" = "1" ] && return 0

  if command -v explorer.exe >/dev/null 2>&1; then
    explorer.exe "$url" >/dev/null 2>&1 &
    return 0
  fi

  if command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$url" >/dev/null 2>&1 &
    return 0
  fi

  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '$url'" >/dev/null 2>&1 &
    return 0
  fi

  return 1
}

gamb_php_display_host() {
  local host="${1:-}"

  case "$host" in
    127.0.0.1|::1|localhost)
      printf '%s\n' 'localhost'
      ;;
    *)
      printf '%s\n' "$host"
      ;;
  esac
}

gamb_php_slug_for_instance() {
  local base_slug="${1:-project}"
  local port="${2:-8000}"

  if [ "$port" = "8000" ]; then
    printf '%s\n' "$base_slug"
    return 0
  fi

  printf '%s-%s\n' "$base_slug" "$port"
}

gamb_php_normalize_base_path() {
  local base_path="${1:-}"

  if [ -z "$base_path" ]; then
    printf '%s\n' ""
    return 0
  fi

  case "$base_path" in
    http://*|https://*)
      base_path="$(printf '%s' "$base_path" | sed -E 's#^[A-Za-z]+://[^/]+##')"
      ;;
  esac

  base_path="${base_path%%\?*}"
  base_path="${base_path%%#*}"

  if [ -z "$base_path" ]; then
    printf '%s\n' ""
    return 0
  fi

  case "$base_path" in
    /*) ;;
    *) base_path="/$base_path" ;;
  esac

  base_path="${base_path%/}"
  if [ "$base_path" = "/" ]; then
    base_path=""
  fi

  printf '%s\n' "$base_path"
}

gamb_php_extract_define_value() {
  local file_path="${1:-}"
  local define_name="${2:-}"

  [ -f "$file_path" ] || return 1

  sed -En "s/^[[:space:]]*define\\([[:space:]]*['\\\"]${define_name}['\\\"][[:space:]]*,[[:space:]]*['\\\"]([^'\\\"]*)['\\\"].*/\\1/p" "$file_path" | head -n 1
}

gamb_php_detect_base_path() {
  local root="${1:-}"
  local config_file=""
  local value=""
  local key=""

  [ -n "$root" ] || {
    printf '%s\n' ""
    return 0
  }

  config_file="$root/config/local.php"
  if [ ! -f "$config_file" ]; then
    printf '%s\n' ""
    return 0
  fi

  for key in SITE_URL ADMIN_URL PORTAL_URL INTRANET_URL; do
    value="$(gamb_php_extract_define_value "$config_file" "$key" || true)"
    if [ -n "$value" ]; then
      gamb_php_normalize_base_path "$value"
      return 0
    fi
  done

  printf '%s\n' ""
}

gamb_php_open_browser_deferred() {
  local url="${1:-}"
  local delay="${2:-1}"

  [ -n "$url" ] || return 1

  (
    sleep "$delay"
    gamb_php_open_browser "$url"
  ) >/dev/null 2>&1 &
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
  local base_path="${11:-}"
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
    gamb_php_write_router "$router_file" "$root" "$docroot" "$index" "$php_bin" "$base_path" "$slug" "$host" "$port"
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
  local base_path="${9:-}"

  if [ "$type" = "laravel" ]; then
    cd "$root"
    exec "$php_bin" artisan serve --host="$host" --port="$port"
  fi

  gamb_php_write_router "$router_file" "$root" "$docroot" "$index" "$php_bin" "$base_path" "$(gamb_php_slug_for_instance "$(gamb_php_slug_from_path "$root")" "$port")" "$host" "$port"
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
  local base_path
  base_path="$(gamb_php_detect_base_path "$path")"
  url="$(gamb_php_command_url "$host" "$port" "$base_path")"

  printf 'Slug: %s\n' "$slug"
  printf 'Caminho: %s\n' "$path"
  printf 'Tipo: %s\n' "$type"
  printf 'Host: %s\n' "$(gamb_php_display_host "$host")"
  printf 'Porta: %s\n' "$port"
  printf 'URL: %s\n' "$url"
  printf 'Painel: %s\n' "$(gamb_php_dashboard_url "$host" "$port" "$base_path")"
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
  local rows=""
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
  local existing_row=""
  local base_slug=""
  local url=""
  local dashboard_url=""
  local base_path=""

  if ! php_bin="$(gamb_php_detect_php)"; then
    if [ "$quiet" -eq 0 ]; then
      printf '%s\n' 'PHP não encontrado.'
      printf '%s\n' 'Configure o PHP no PATH ou defina:'
      printf '%s\n' 'export GAMB_PHP_BIN="/d/tools/php/php.exe"'
    fi
    return 1
  fi

  rows="$(gamb_php_find_registered_rows_for_cwd "$cwd" 2>/dev/null || true)"

  if [ -n "$rows" ]; then
    row="$(gamb_php_find_registered_row_for_cwd "$cwd")"
    IFS=$'\t' read -r slug root type host port docroot index <<<"$row"
    base_slug="$(gamb_php_slug_from_path "$root")"

    if [ -n "$requested_port" ]; then
      existing_row="$(gamb_php_get_registry_row_by_path_port "$root" "$requested_port" 2>/dev/null || true)"
      if [ -n "$existing_row" ]; then
        IFS=$'\t' read -r slug root type host port docroot index <<<"$existing_row"
        if pid="$(gamb_php_running_state_for_row "$slug" 2>/dev/null)" && [ -n "$pid" ]; then
          base_path="$(gamb_php_detect_base_path "$root")"
          url="$(gamb_php_command_url "$host" "$port" "$base_path")"
          dashboard_url="$(gamb_php_dashboard_url "$host" "$port" "$base_path")"
          gamb_php_touch_project_last_used "$root" >/dev/null 2>&1 || true
          if [ "$quiet" -eq 0 ]; then
            printf 'Projeto jÃ¡ estÃ¡ rodando em %s\n' "$url"
            printf 'Painel: %s\n' "$dashboard_url"
            gamb_php_open_browser "$dashboard_url" || true
          fi
          return 0
        fi
      fi

      port="$requested_port"
    else
      while IFS= read -r row; do
        [ -z "$row" ] && continue
        IFS=$'\t' read -r slug root type host port docroot index <<<"$row"
        if pid="$(gamb_php_running_state_for_row "$slug" 2>/dev/null)" && [ -n "$pid" ]; then
          base_path="$(gamb_php_detect_base_path "$root")"
          url="$(gamb_php_command_url "$host" "$port" "$base_path")"
          dashboard_url="$(gamb_php_dashboard_url "$host" "$port" "$base_path")"
          gamb_php_touch_project_last_used "$root" >/dev/null 2>&1 || true
          if [ "$quiet" -eq 0 ]; then
            printf 'Projeto jÃ¡ estÃ¡ rodando em %s\n' "$url"
            printf 'Painel: %s\n' "$dashboard_url"
            gamb_php_open_browser "$dashboard_url" || true
          fi
          return 0
        fi
      done <<EOF
$rows
EOF

      row="$(gamb_php_find_registered_row_for_cwd "$cwd")"
      IFS=$'\t' read -r slug root type host port docroot index <<<"$row"
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
    base_slug="$(gamb_php_slug_from_path "$root")"
    slug="$(gamb_php_slug_for_instance "$base_slug" "$port")"
  fi

  base_slug="${base_slug:-$(gamb_php_slug_from_path "$root")}"
  slug="${slug:-$(gamb_php_slug_for_instance "$base_slug" "$port")}"
  host="${host:-127.0.0.1}"
  base_path="$(gamb_php_detect_base_path "$root")"

  chosen_port="$port"
  if ! gamb_php_port_available "$php_bin" "$host" "$chosen_port"; then
    start_port="${requested_port:-8000}"
    chosen_port="$(gamb_php_choose_port "$php_bin" "$host" "$start_port")"
  fi

  port="$chosen_port"
  existing_row="$(gamb_php_get_registry_row_by_path_port "$root" "$port" 2>/dev/null || true)"
  if [ -n "$existing_row" ]; then
    IFS=$'\t' read -r slug root type host port docroot index <<<"$existing_row"
  else
    slug="$(gamb_php_slug_for_instance "$base_slug" "$port")"
  fi

  pid_file="$(gamb_php_pid_file_for_row "$slug")"
  log_file="$(gamb_php_log_file_for_row "$slug")"
  router_file="$(gamb_php_router_file_for_row "$slug")"
  url="$(gamb_php_command_url "$host" "$port" "$base_path")"
  dashboard_url="$(gamb_php_dashboard_url "$host" "$port" "$base_path")"
  gamb_php_registry_upsert_row "$slug" "$root" "$type" "$host" "$port" "$docroot" "$index"
  gamb_php_touch_project_last_used "$root" >/dev/null 2>&1 || true

  if [ "$foreground" -eq 1 ]; then
    if [ "$quiet" -eq 0 ]; then
      printf 'Projeto registrado em %s\n' "$root"
      printf 'URL: %s\n' "$url"
      printf 'Painel: %s\n' "$dashboard_url"
      gamb_php_open_browser_deferred "$dashboard_url" 1 || true
    fi
    gamb_php_start_foreground_server "$php_bin" "$type" "$host" "$port" "$root" "$docroot" "$index" "$router_file" "$base_path"
  fi

  pid="$(gamb_php_start_background_server "$php_bin" "$type" "$host" "$port" "$root" "$docroot" "$index" "$slug" "$log_file" "$router_file" "$base_path")"
  printf '%s\n' "$pid" > "$pid_file"

  if [ "$quiet" -eq 0 ]; then
    printf 'Projeto registrado em %s\n' "$root"
    printf 'URL: %s\n' "$url"
    printf 'Painel: %s\n' "$dashboard_url"
    printf 'PID: %s\n' "$pid"
    gamb_php_open_browser_deferred "$dashboard_url" 1 || true
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

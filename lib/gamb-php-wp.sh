#!/usr/bin/env bash

# Utilitarios WordPress sem download automatico e sem sobrescrever destinos.

gamb_php_wp_require_root() {
  local root="${1:-}" type_row="" type=""
  [ -n "$root" ] || { printf '%s\n' 'Informe a raiz do WordPress.' >&2; return 1; }
  root="$(gamb_php_norm_path "$root")"
  type_row="$(gamb_php_detect_project_type "$root" 2>/dev/null || true)"
  IFS=$'\t' read -r type _rest <<EOF
$type_row
EOF
  if [ "$type" != "wordpress" ]; then
    printf 'A pasta nao parece ser uma raiz WordPress: %s\n' "$root" >&2
    return 1
  fi
  printf '%s\n' "$root"
}

gamb_php_wp_config_value() {
  gamb_php_extract_define_value "$1/wp-config.php" "$2" 2>/dev/null || true
}

gamb_php_wp_config_report() {
  local root="$1"
  local password=""
  printf 'WordPress: %s\n' "$root"
  printf 'Banco host: %s\n' "$(gamb_php_wp_config_value "$root" DB_HOST)"
  printf 'Banco nome: %s\n' "$(gamb_php_wp_config_value "$root" DB_NAME)"
  printf 'Banco usuario: %s\n' "$(gamb_php_wp_config_value "$root" DB_USER)"
  password="$(gamb_php_wp_config_value "$root" DB_PASSWORD)"
  [ -n "$password" ] && printf 'Senha: configurada (nao exibida)\n' || printf 'Senha: nao identificada\n'
  printf 'URL configurada: %s\n' "$(gamb_php_wp_config_value "$root" WP_HOME)"
  printf 'Prefixo: %s\n' "$(gamb_php_wp_config_value "$root" table_prefix)"
}

gamb_php_wp_random_salt() {
  if command -v php >/dev/null 2>&1; then
    php -r 'echo bin2hex(random_bytes(32));'
  else
    openssl rand -hex 32 2>/dev/null || return 1
  fi
}

gamb_php_wp_write_config() {
  local destination="$1" db_name="$2" db_user="$3" db_password="$4" db_host="$5" db_port="$6" prefix="$7"
  local salt="" salts="" key=""
  for key in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
    salt="$(gamb_php_wp_random_salt)" || return 1
    salts="${salts}define('${key}', '${salt}');\n"
  done
  cat > "$destination/wp-config.php" <<EOF
<?php
define('DB_NAME', '$(printf '%s' "$db_name" | sed "s/'/\\\\'/g")');
define('DB_USER', '$(printf '%s' "$db_user" | sed "s/'/\\\\'/g")');
define('DB_PASSWORD', '$(printf '%s' "$db_password" | sed "s/'/\\\\'/g")');
define('DB_HOST', '$(printf '%s' "$db_host:$db_port" | sed "s/'/\\\\'/g")');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
define('\$table_prefix', '$(printf '%s' "$prefix" | sed "s/'/\\\\'/g")');
$(printf '%b' "$salts")
define('WP_DEBUG', false);
if (!defined('ABSPATH')) { define('ABSPATH', __DIR__ . '/'); }
require_once ABSPATH . 'wp-settings.php';
EOF
}

gamb_php_wp_copy_source() {
  local source="$1" destination="$2"
  mkdir -p "$destination"
  cp -a "$source"/. "$destination"/
}

gamb_php_wp_destination_is_safe() {
  local destination="$1"
  [ ! -e "$destination" ] && return 0
  [ -d "$destination" ] || return 1
  [ -z "$(find "$destination" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]
}

gamb_php_wp_dump_binary() {
  local row="$1" profile="" engine="" label="" origin="" server_bin="" defaults_file="" port="" datadir="" admin_bin="" basedir="" log_error="" version="" candidate=""
  IFS=$'\t' read -r profile engine label origin server_bin defaults_file port datadir admin_bin basedir log_error version <<EOF
$row
EOF
  for candidate in "$(dirname "$server_bin")/mysqldump.exe" "$(dirname "$server_bin")/mariadb-dump.exe" "$(dirname "$server_bin")/mysqldump" "$(dirname "$server_bin")/mariadb-dump" mysqldump mariadb-dump; do
    if [ -x "$candidate" ] || command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

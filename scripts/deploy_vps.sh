#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${DEPLOY_ENV_FILE:-$SCRIPT_DIR/deploy.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing deploy config: $ENV_FILE"
  echo "Run: cp scripts/deploy.env.example scripts/deploy.env"
  echo "Then edit scripts/deploy.env and run this script again."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

API_DOMAIN="${API_DOMAIN:?API_DOMAIN is required}"
WEB_DOMAIN="${WEB_DOMAIN:?WEB_DOMAIN is required}"
WEB_ALIASES="${WEB_ALIASES:-}"
APP_ROOT="${APP_ROOT:-/var/www/portal-si}"
BACKEND_DIR="${BACKEND_DIR:-$APP_ROOT/api-portalsi}"
FRONTEND_DIR="${FRONTEND_DIR:-$APP_ROOT/frontend}"
APP_ENV="${APP_ENV:-production}"
APP_DEBUG="${APP_DEBUG:-false}"
FILESYSTEM_DISK="${FILESYSTEM_DISK:-public}"
CORS_ALLOWED_ORIGINS="${CORS_ALLOWED_ORIGINS:-https://$WEB_DOMAIN}"
DB_DATABASE="${DB_DATABASE:-portalsi}"
DB_USERNAME="${DB_USERNAME:-portal_user}"
DB_PASSWORD="${DB_PASSWORD:?DB_PASSWORD is required}"
INSTALL_SYSTEM_PACKAGES="${INSTALL_SYSTEM_PACKAGES:-1}"
ENABLE_SSL="${ENABLE_SSL:-0}"
SSL_EMAIL="${SSL_EMAIL:-admin@$WEB_DOMAIN}"
BUILD_FRONTEND_ON_VPS="${BUILD_FRONTEND_ON_VPS:-0}"
ENABLE_QUEUE_WORKER="${ENABLE_QUEUE_WORKER:-1}"

PHP_VERSION="${PHP_VERSION:-8.2}"
PHP_FPM_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"

log() {
  printf '\n\033[1;32m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\n\033[1;33mWARN:\033[0m %s\n' "$*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Command not found: $1"
    exit 1
  }
}

run_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

write_laravel_env() {
  local env_path="$BACKEND_DIR/.env"
  local app_key=""

  if [[ -f "$env_path" ]]; then
    cp "$env_path" "$env_path.backup.$(date +%Y%m%d%H%M%S)"
    app_key="$(grep -E '^APP_KEY=' "$env_path" | head -n1 | cut -d= -f2- || true)"
  fi

  cat > "$env_path" <<EOF
APP_NAME="Portal SI"
APP_ENV=$APP_ENV
APP_KEY=$app_key
APP_DEBUG=$APP_DEBUG
APP_URL=https://$API_DOMAIN

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=$DB_DATABASE
DB_USERNAME=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=$FILESYSTEM_DISK
QUEUE_CONNECTION=database
SESSION_DRIVER=file
SESSION_LIFETIME=120

SANCTUM_STATEFUL_DOMAINS=$WEB_DOMAIN,$WEB_ALIASES
SESSION_DOMAIN=
CORS_ALLOWED_ORIGINS=$CORS_ALLOWED_ORIGINS

MAIL_MAILER=log
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@$WEB_DOMAIN"
MAIL_FROM_NAME="Portal SI"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_URL=
AWS_ENDPOINT=
AWS_USE_PATH_STYLE_ENDPOINT=false
EOF

  if [[ -z "$app_key" ]]; then
    (cd "$BACKEND_DIR" && php artisan key:generate --force)
  fi
}

install_system_packages() {
  if [[ "$INSTALL_SYSTEM_PACKAGES" != "1" ]]; then
    log "Skipping apt install"
    return
  fi

  log "Installing system packages"
  run_sudo apt-get update
  run_sudo apt-get install -y \
    nginx mysql-server unzip git curl certbot python3-certbot-nginx supervisor \
    "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-cli" "php${PHP_VERSION}-mysql" \
    "php${PHP_VERSION}-mbstring" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-curl" \
    "php${PHP_VERSION}-zip" "php${PHP_VERSION}-bcmath" "php${PHP_VERSION}-gd"

  if ! command -v composer >/dev/null 2>&1; then
    log "Installing Composer"
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
    run_sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
  fi
}

prepare_dirs() {
  log "Preparing directories"
  run_sudo mkdir -p "$APP_ROOT" "$FRONTEND_DIR"
  run_sudo chown -R "$USER":"$USER" "$APP_ROOT"

  if [[ ! -d "$BACKEND_DIR" ]]; then
    echo "Backend directory not found: $BACKEND_DIR"
    echo "Upload or clone this project to $APP_ROOT first."
    exit 1
  fi
}

setup_database() {
  log "Creating database/user if needed"
  local sql
  sql=$(cat <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USERNAME'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
ALTER USER '$DB_USERNAME'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_DATABASE\`.* TO '$DB_USERNAME'@'localhost';
FLUSH PRIVILEGES;
SQL
)

  if run_sudo mysql -e "$sql"; then
    return
  fi

  warn "Could not create database automatically. Create it manually, then rerun."
  exit 1
}

deploy_backend() {
  log "Deploying backend"
  cd "$BACKEND_DIR"

  composer install --no-dev --optimize-autoloader --no-interaction
  write_laravel_env

  php artisan migrate --force
  php artisan storage:link || true
  php artisan optimize:clear
  php artisan config:cache
  php artisan route:cache || true
  php artisan view:cache

  run_sudo chown -R www-data:www-data "$BACKEND_DIR/storage" "$BACKEND_DIR/bootstrap/cache" "$BACKEND_DIR/public/storage"
  run_sudo chmod -R 775 "$BACKEND_DIR/storage" "$BACKEND_DIR/bootstrap/cache"
}

deploy_frontend() {
  log "Deploying frontend"
  cd "$PROJECT_DIR"

  if [[ "$BUILD_FRONTEND_ON_VPS" == "1" ]]; then
    need_cmd flutter
    flutter build web --release --dart-define "API_BASE_URL=https://$API_DOMAIN"
    rm -rf "$FRONTEND_DIR"/*
    cp -R "$PROJECT_DIR/build/web/." "$FRONTEND_DIR/"
  elif [[ -d "$PROJECT_DIR/build/web" ]]; then
    rm -rf "$FRONTEND_DIR"/*
    cp -R "$PROJECT_DIR/build/web/." "$FRONTEND_DIR/"
  elif [[ "$(find "$FRONTEND_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)" -eq 0 ]]; then
    warn "No Flutter build found. Either:"
    echo "  1. Set BUILD_FRONTEND_ON_VPS=1 and install Flutter on VPS, or"
    echo "  2. Run locally: flutter build web --release --dart-define API_BASE_URL=https://$API_DOMAIN"
    echo "     then upload build/web to $FRONTEND_DIR"
  fi

  run_sudo chown -R www-data:www-data "$FRONTEND_DIR"
}

write_nginx_configs() {
  log "Writing Nginx configs"
  local api_conf="/etc/nginx/sites-available/$API_DOMAIN"
  local web_conf="/etc/nginx/sites-available/$WEB_DOMAIN"

  run_sudo tee "$api_conf" >/dev/null <<EOF
server {
    listen 80;
    server_name $API_DOMAIN;
    root $BACKEND_DIR/public;

    index index.php index.html;
    client_max_body_size 512M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /storage/ {
        try_files \$uri =404;
        access_log off;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_FPM_SOCK;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

  run_sudo tee "$web_conf" >/dev/null <<EOF
server {
    listen 80;
    server_name $WEB_DOMAIN $WEB_ALIASES;
    root $FRONTEND_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|svg|webp|ico|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        try_files \$uri =404;
    }
}
EOF

  run_sudo ln -sf "$api_conf" "/etc/nginx/sites-enabled/$API_DOMAIN"
  run_sudo ln -sf "$web_conf" "/etc/nginx/sites-enabled/$WEB_DOMAIN"
  run_sudo rm -f /etc/nginx/sites-enabled/default
  run_sudo nginx -t
  run_sudo systemctl reload nginx
}

setup_ssl() {
  if [[ "$ENABLE_SSL" != "1" ]]; then
    warn "SSL skipped. Set ENABLE_SSL=1 after DNS points to this VPS."
    return
  fi

  log "Requesting SSL certificates"
  run_sudo certbot --nginx --non-interactive --agree-tos -m "$SSL_EMAIL" -d "$API_DOMAIN"

  local domains=(-d "$WEB_DOMAIN")
  for alias in $WEB_ALIASES; do
    domains+=(-d "$alias")
  done
  run_sudo certbot --nginx --non-interactive --agree-tos -m "$SSL_EMAIL" "${domains[@]}"
}

setup_queue_worker() {
  if [[ "$ENABLE_QUEUE_WORKER" != "1" ]]; then
    log "Skipping queue worker"
    return
  fi

  log "Configuring supervisor queue worker"
  run_sudo tee /etc/supervisor/conf.d/portal-worker.conf >/dev/null <<EOF
[program:portal-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $BACKEND_DIR/artisan queue:work --sleep=3 --tries=3 --timeout=120
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=$BACKEND_DIR/storage/logs/worker.log
EOF

  run_sudo supervisorctl reread
  run_sudo supervisorctl update
  run_sudo supervisorctl restart portal-worker:* || run_sudo supervisorctl start portal-worker:*
}

main() {
  log "Deploy config"
  echo "API:      https://$API_DOMAIN"
  echo "Frontend: https://$WEB_DOMAIN"
  echo "Backend: $BACKEND_DIR"
  echo "Frontend dir: $FRONTEND_DIR"

  install_system_packages
  prepare_dirs
  setup_database
  deploy_backend
  deploy_frontend
  write_nginx_configs
  setup_ssl
  setup_queue_worker

  log "Done"
  echo "Open: https://$WEB_DOMAIN"
  echo "API:  https://$API_DOMAIN"
}

main "$@"

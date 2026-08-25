#!/bin/sh
set -e

CROWDSEC_BOUNCER_CONFIG="${BOUNCER_CONFIG:-/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf}"
NGINX_CONF="/usr/local/openresty/nginx/conf/nginx.conf"

params='
ALWAYS_SEND_TO_APPSEC
API_KEY
API_URL
APPSEC_CONNECT_TIMEOUT
APPSEC_FAILURE_ACTION
APPSEC_PROCESS_TIMEOUT
APPSEC_SEND_TIMEOUT
APPSEC_URL
BAN_TEMPLATE_PATH
BOUNCING_ON_TYPE
CACHE_EXPIRATION
CAPTCHA_EXPIRATION
CAPTCHA_PROVIDER
CAPTCHA_TEMPLATE_PATH
EXCLUDE_LOCATION
FALLBACK_REMEDIATION
MODE
REDIRECT_LOCATION
REQUEST_TIMEOUT
RET_CODE
SECRET_KEY
SITE_KEY
SSL_VERIFY
UPDATE_FREQUENCY
'

for var in $params; do
    eval "value=\$$var"
    if [ -n "$value" ]; then
        sed -i "s,${var}.*,${var}=${value}," "$CROWDSEC_BOUNCER_CONFIG"
    fi
done

: "${SERVER_TOKENS:=on}"
: "${WORKER_CONNECTIONS:=1024}"

case "$WORKER_CONNECTIONS" in
  ''|*[!0-9]*|0)
    echo "[docker_start] Invalid WORKER_CONNECTIONS=$WORKER_CONNECTIONS. Use a positive integer."
    exit 1
    ;;

  *)
    echo "[docker_start] Setting worker_connections to $WORKER_CONNECTIONS"

    if grep -qE '^[[:space:]]*worker_connections[[:space:]]+' "$NGINX_CONF"; then
      sed -i "s|^[[:space:]]*worker_connections[[:space:]]\+.*;|    worker_connections ${WORKER_CONNECTIONS};|" "$NGINX_CONF"

    elif grep -qE '^[[:space:]]*#[[:space:]]*worker_connections[[:space:]]+' "$NGINX_CONF"; then
      sed -i "s|^[[:space:]]*#[[:space:]]*worker_connections[[:space:]]\+.*;|    worker_connections ${WORKER_CONNECTIONS};|" "$NGINX_CONF"

    else
      sed -i "/^[[:space:]]*events[[:space:]]*{/a\\    worker_connections ${WORKER_CONNECTIONS};" "$NGINX_CONF"
    fi
    ;;
esac

case "$(echo "$SERVER_TOKENS" | tr '[:upper:]' '[:lower:]')" in
  off|false|0|no)
    echo "[docker_start] Disabling server_tokens"

    if grep -qE '^[[:space:]]*server_tokens[[:space:]]+' "$NGINX_CONF"; then
      sed -i 's|^[[:space:]]*server_tokens[[:space:]]\+.*;|    server_tokens off;|' "$NGINX_CONF"

    elif grep -qE '^[[:space:]]*#[[:space:]]*server_tokens[[:space:]]+' "$NGINX_CONF"; then
      sed -i 's|^[[:space:]]*#[[:space:]]*server_tokens[[:space:]]\+.*;|    server_tokens off;|' "$NGINX_CONF"

    else
      sed -i '/^[[:space:]]*http[[:space:]]*{/a\    server_tokens off;' "$NGINX_CONF"
    fi
    ;;

  on|true|1|yes)
    echo "[docker_start] Leaving server_tokens enabled"

    # Comment out any active server_tokens directive so the OpenResty default applies
    sed -i 's|^[[:space:]]*server_tokens[[:space:]]\+\(.*;\)|    # server_tokens \1|' "$NGINX_CONF"
    ;;

  *)
    echo "[docker_start] Invalid SERVER_TOKENS=$SERVER_TOKENS. Use on/off."
    exit 1
    ;;
esac

lower=$(echo "$IS_LUALIB_IMAGE" | tr '[:upper:]' '[:lower:]')
if [ "$lower" != "true" ]; then
    exec /usr/local/openresty/bin/openresty -g "daemon off;"
fi

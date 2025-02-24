#!/bin/bash

#set -x
CROWDSEC_BOUNCER_CONFIG="${BOUNCER_CONFIG:-/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf}"

params=(
  API_URL
  API_KEY
  CACHE_EXPIRATION
  BOUNCING_ON_TYPE
  FALLBACK_REMEDIATION
  REQUEST_TIMEOUT
  UPDATE_FREQUENCY
  MODE
  EXCLUDE_LOCATION
  BAN_TEMPLATE_PATH
  REDIRECT_LOCATION
  RET_CODE
  SECRET_KEY
  SITE_KEY
  CAPTCHA_TEMPLATE_PATH
  CAPTCHA_EXPIRATION
  CAPTCHA_PROVIDER
  APPSEC_URL
  APPSEC_FAILURE_ACTION
  APPSEC_CONNECT_TIMEOUT
  APPSEC_SEND_TIMEOUT
  APPSEC_PROCESS_TIMEOUT
  ALWAYS_SEND_TO_APPSEC
  SSL_VERIFY
)

for var in "${params[@]}"; do
  value="${!var}"
  if [[ -n "$value" ]]; then
    sed -i "s,${var}.*,${var}=${value}," "$CROWDSEC_BOUNCER_CONFIG"
  fi
done


if [[ "${IS_LUALIB_IMAGE,,}" != "true" ]]; then
    exec /usr/local/openresty/bin/openresty -g "daemon off;"
fi

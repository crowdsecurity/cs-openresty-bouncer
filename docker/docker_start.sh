#!/bin/sh
set -e
echo "[crowdsec] Starting crowdsec bouncer init"

CROWDSEC_BOUNCER_CONFIG="/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf"

# Use provided config file if specified
[ -n "$BOUNCER_CONFIG" ] && CROWDSEC_BOUNCER_CONFIG="$BOUNCER_CONFIG"

echo "[crowdsec] Setting config in $CROWDSEC_BOUNCER_CONFIG"
# Update configuration values only if they are not empty
[ -n "$API_URL" ] && sed -i "s,API_URL.*,API_URL=$${API_URL}," "$$CROWDSEC_BOUNCER_CONFIG"
[ -n "$API_KEY" ] && sed -i "s,API_KEY.*,API_KEY=$${API_KEY}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$CACHE_EXPIRATION" ] && sed -i "s,CACHE_EXPIRATION.*,CACHE_EXPIRATION=${CACHE_EXPIRATION}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$BOUNCING_ON_TYPE" ] && sed -i "s,BOUNCING_ON_TYPE.*,BOUNCING_ON_TYPE=${BOUNCING_ON_TYPE}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$FALLBACK_REMEDIATION" ] && sed -i "s,FALLBACK_REMEDIATION.*,FALLBACK_REMEDIATION=${FALLBACK_REMEDIATION}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$REQUEST_TIMEOUT" ] && sed -i "s,REQUEST_TIMEOUT.*,REQUEST_TIMEOUT=${REQUEST_TIMEOUT}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$UPDATE_FREQUENCY" ] && sed -i "s,UPDATE_FREQUENCY.*,UPDATE_FREQUENCY=${UPDATE_FREQUENCY}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$MODE" ] && sed -i "s,MODE.*,MODE=${MODE}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$EXCLUDE_LOCATION" ] && sed -i "s,EXCLUDE_LOCATION.*,EXCLUDE_LOCATION=$${EXCLUDE_LOCATION}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$BAN_TEMPLATE_PATH" ] && sed -i "s,BAN_TEMPLATE_PATH.*,BAN_TEMPLATE_PATH=$${BAN_TEMPLATE_PATH}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$REDIRECT_LOCATION" ] && sed -i "s,REDIRECT_LOCATION.*,REDIRECT_LOCATION=$${REDIRECT_LOCATION}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$RET_CODE" ] && sed -i "s,RET_CODE.*,RET_CODE=$${RET_CODE}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$SECRET_KEY" ] && sed -i "s,SECRET_KEY.*,SECRET_KEY=$${SECRET_KEY}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$SITE_KEY" ] && sed -i "s,SITE_KEY.*,SITE_KEY=$${SITE_KEY}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$CAPTCHA_TEMPLATE_PATH" ] && sed -i "s,CAPTCHA_TEMPLATE_PATH.*,CAPTCHA_TEMPLATE_PATH=$${CAPTCHA_TEMPLATE_PATH}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$CAPTCHA_EXPIRATION" ] && sed -i "s,CAPTCHA_EXPIRATION.*,CAPTCHA_EXPIRATION=$${CAPTCHA_EXPIRATION}," "$CROWDSEC_BOUNCER_CONFIG"
[ -n "$CAPTCHA_PROVIDER" ] && sed -i "s,CAPTCHA_PROVIDER.*,CAPTCHA_PROVIDER=$${CAPTCHA_PROVIDER}," "$CROWDSEC_BOUNCER_CONFIG"

# Convert IS_LUALIB_IMAGE to lowercase and check if it's true
if [ "$(echo "$IS_LUALIB_IMAGE" | tr '[:upper:]' '[:lower:]')" != "true" ]; then
  /usr/local/openresty/bin/openresty -g "daemon off;"
fi
[ -d "/lua_plugins" ] && mkdir -p /lua_plugins/crowdsec/
[ -d "/lua_plugins/crowdsec" ] && cp -R /crowdsec/* /lua_plugins/crowdsec/
echo "[crowdsec] Init completed"

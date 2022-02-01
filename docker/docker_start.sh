#!/bin/bash
#set -x
CROWDSEC_BOUNCER_CONFIG="/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf"

if [ "$BOUNCER_CONFIG" != "" ]; then
    CROWDSEC_BOUNCER_CONFIG="$BOUNCER_CONFIG"
fi
if [ "$API_URL" != "" ]; then
    sed -i "s,API_URL.*,API_URL=$API_URL," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$API_KEY" != "" ]; then
    sed -i "s,API_KEY.*,API_KEY=$API_KEY," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$CACHE_EXPIRATION" != "" ]; then
    sed -i "s,CACHE_EXPIRATION.*,CACHE_EXPIRATION=$CACHE_EXPIRATION," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$BOUNCING_ON_TYPE" != "" ]; then
    sed -i "s,BOUNCING_ON_TYPE.*,BOUNCING_ON_TYPE=$BOUNCING_ON_TYPE," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$FALLBACK_REMEDIATION" != "" ]; then
    sed -i "s,FALLBACK_REMEDIATION.*,FALLBACK_REMEDIATION=$FALLBACK_REMEDIATION," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$REQUEST_TIMEOUT" != "" ]; then
    sed -i "s,REQUEST_TIMEOUT.*,REQUEST_TIMEOUT=$REQUEST_TIMEOUT," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$UPDATE_FREQUENCY" != "" ]; then
    sed -i "s,UPDATE_FREQUENCY.*,UPDATE_FREQUENCY=$UPDATE_FREQUENCY," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$MODE" != "" ]; then
    sed -i "s,MODE.*,MODE=$MODE," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$EXCLUDE_LOCATION" != "" ]; then
    sed -i "s,EXCLUDE_LOCATION.*,EXCLUDE_LOCATION=$EXCLUDE_LOCATION," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$BAN_TEMPLATE_PATH" != "" ]; then
    sed -i "s,BAN_TEMPLATE_PATH.*,BAN_TEMPLATE_PATH=$BAN_TEMPLATE_PATH," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$REDIRECT_LOCATION" != "" ]; then
    sed -i "s,REDIRECT_LOCATION.*,REDIRECT_LOCATION=$REDIRECT_LOCATION," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$RET_CODE" != "" ]; then
    sed -i "s,RET_CODE.*,RET_CODE=$RET_CODE," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$SECRET_KEY" != "" ]; then
    sed -i "s,SECRET_KEY.*,SECRET_KEY=$SECRET_KEY," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$SITE_KEY" != "" ]; then
    sed -i "s,SITE_KEY.*,SITE_KEY=$SITE_KEY," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$CAPTCHA_TEMPLATE_PATH" != "" ]; then
    sed -i "s,CAPTCHA_TEMPLATE_PATH.*,CAPTCHA_TEMPLATE_PATH=$CAPTCHA_TEMPLATE_PATH," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$CAPTCHA_EXPIRATION" != "" ]; then
    sed -i "s,CAPTCHA_EXPIRATION.*,CAPTCHA_EXPIRATION=$CAPTCHA_EXPIRATION," $CROWDSEC_BOUNCER_CONFIG
fi

if [ "${IS_LUALIB_IMAGE,,}" != "true" ]; then
    exec /usr/local/openresty/bin/openresty -g "daemon off;"
fi
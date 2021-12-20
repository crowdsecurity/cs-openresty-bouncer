#!/bin/bash
CROWDSEC_BOUNCER_CONFIG="/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf"

if [ "$API_URL" != "" ]; then
    sed -i "s,API_URL.*,API_URL=$API_URL," $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$API_KEY" != "" ]; then
    sed -i "s/API_KEY.*/API_KEY=$API_KEY/" $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$CACHE_EXPIRATION" != "" ]; then
    sed -i "s/CACHE_EXPIRATION.*/CACHE_EXPIRATION=$CACHE_EXPIRATION/" $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$CACHE_SIZE" != "" ]; then
    sed -i "s/CACHE_SIZE.*/CACHE_SIZE=$CACHE_SIZE/" $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$BOUNCING_ON_TYPE" != "" ]; then
    sed -i "s/BOUNCING_ON_TYPE.*/BOUNCING_ON_TYPE=$BOUNCING_ON_TYPE/" $CROWDSEC_BOUNCER_CONFIG
fi
if [ "$REQUEST_TIMEOUT" != "" ]; then
    sed -i "s/REQUEST_TIMEOUT.*/REQUEST_TIMEOUT=$REQUEST_TIMEOUT/" $CROWDSEC_BOUNCER_CONFIG
fi

exec /usr/local/openresty/bin/openresty -g "daemon off;"
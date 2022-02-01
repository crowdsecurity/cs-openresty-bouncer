ARG BUILD_ENV=git
FROM openresty/openresty:alpine-fat as with_deps
RUN luarocks install lua-resty-http

FROM with_deps as git
ARG BUILD_ENV=git
RUN if [ "$BUILD_ENV" == "git" ]; then apk add --no-cache git; fi
RUN if [ "$BUILD_ENV" == "git" ]; then git clone https://github.com/crowdsecurity/lua-cs-bouncer.git ; fi

FROM with_deps as local
COPY ./lua-cs-bouncer/ lua-cs-bouncer

FROM ${BUILD_ENV}
RUN mkdir -p /etc/crowdsec/bouncers/ /var/lib/crowdsec/lua/templates/
RUN cp -R lua-cs-bouncer/lib/* /usr/local/openresty/lualib/
RUN cp -R lua-cs-bouncer/templates/* /var/lib/crowdsec/lua/templates/
RUN cp lua-cs-bouncer/config_example.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
RUN rm -rf ./lua-cs-bouncer/
COPY ./openresty /etc/nginx/conf.d
COPY ./docker/docker_start.sh /

ENTRYPOINT /bin/bash docker_start.sh
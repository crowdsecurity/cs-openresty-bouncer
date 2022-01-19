ARG BUILD_ENV=git
FROM openresty/openresty:alpine-fat as with_deps
RUN luarocks install lua-resty-http
RUN luarocks install lua-resty-ipmatcher

FROM with_deps as git
ARG BUILD_ENV=git
RUN if [ "$BUILD_ENV" == "git" ]; then apk add --no-cache git; fi
RUN if [ "$BUILD_ENV" == "git" ]; then git clone https://github.com/crowdsecurity/lua-cs-bouncer.git ; fi

FROM with_deps as local
COPY ./lua-cs-bouncer/ lua-cs-bouncer

FROM ${BUILD_ENV}
RUN mkdir -p /usr/local/openresty/lualib/plugins/crowdsec/ /etc/crowdsec/bouncers/
RUN cp lua-cs-bouncer/nginx/*.lua /usr/local/openresty/lualib/plugins/crowdsec/
RUN cp lua-cs-bouncer/nginx/template.conf /etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf
RUN rm -rf ./lua-cs-bouncer/
COPY ./openresty /etc/nginx/conf.d
COPY ./docker/docker_start.sh /

ENTRYPOINT /bin/bash docker_start.sh
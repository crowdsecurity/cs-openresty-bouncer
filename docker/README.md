# OpenResty with CrowdSec Bouncer

CrowdSec OpenResty - an OpenResty with lua bouncer to use with Crowdsec.

## Getting Started

Before starting using docker image, you need to generate an API key from Crowdsec local API using cscli ([how to](https://docs.crowdsec.net/docs/user_guides/bouncers_configuration/)). And also provide the Crowdsec LAPI URL.

The container is built from [the OpenResty official image](https://hub.docker.com/r/openresty/openresty).

#### Run

```shell
docker run -d -p 8080:80 \
    -e API_URL=<CROWDSEC_LAPI_URL> \
    -e API_KEY=<CROWDSEC_LAPI_KEY> \
    --name openresty crowdsecurity/crowdsec-openresty
```

#### Example

We generate our API key and use it in environment variable
```shell
$ sudo cscli bouncers add myOpenRestyBouncer
Api key for 'myOpenRestyBouncer':

   abcdefghijklmnopqrstuvwxyz

Please keep this key since you will not be able to retrieve it!
```

```shell
docker run -d -p 8080:80 \
    -e API_URL=http://172.17.0.1:8080 \
    -e API_KEY=abcdefghijklmnopqrstuvwxyz \
    --name openresty crowdsecurity/crowdsec-openresty
```

Or you can even mount you own bouncer config file to the target path `/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf`

```shell
$ cat myConfigFile.conf
API_URL=http://172.17.0.1:8080
API_KEY=abcdefghijklmnopqrstuvwxyz
CACHE_EXPIRATION=1
BOUNCING_ON_TYPE=ban
REQUEST_TIMEOUT=0.2
UPDATE_FREQUENCY=10
MODE=stream
```

Now run the openresty by mounting your own config file.

```shell
docker run -d -p 8080:80 \
    -v ~/myConfigFile.conf:/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf \
    --name openresty crowdsecurity/crowdsec-openresty
```

Or you can pass the whole bouncer config through the docker compose enviroment

```code
... in docker-compose.yml
    ...
    environment:
        BOUNCER_CONFIG: |
            API_KEY=${CROWDSEC_BOUNCER_OPENRESTY_APIKEY}
            API_URL=http://crowdsec:8080
            CAPTCHA_PROVIDER=${CROWDSEC_BOUNCER_OPENRESTY_CAPTCHA_PROVIDER}
            SECRET_KEY=${CROWDSEC_BOUNCER_OPENRESTY_SECRET_KEY}
            SITE_KEY=${CROWDSEC_BOUNCER_OPENRESTY_SITE_KEY}
            FALLBACK_REMEDIATION=ban
            MODE=stream
            BOUNCING_ON_TYPE=all
            CAPTCHA_TEMPLATE_PATH=/var/lib/crowdsec/lua/templates/captcha.html
            BAN_TEMPLATE_PATH=/var/lib/crowdsec/lua/templates/ban.html
            ALWAYS_SEND_TO_APPSEC=true
            SSL_VERIFY=false
            APPSEC_URL=http://crowdsec:7422
    ...
```

### Configuration

The bouncer uses [lua_shared_dict](https://github.com/openresty/lua-nginx-module#lua_shared_dict) to share cache between all workers.
If you want to increase the cache size you need to change this value `lua_shared_dict crowdsec_cache 50m;` in the config file `/etc/nginx/conf.d/crowdsec_openresty.conf`.

For others parameters, you can use environment variables below or mount your own config file at `/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf`

### Environment Variables

* `API_URL`          - Crowdsec local API URL : `-e API_URL="http://172.17.0.1:8080"`
* `API_KEY`          - Disable local API (default: `false`) : `-e API_KEY="abcdefghijklmnopqrstuvwxyz"`
* `CACHE_EXPIRATION` - [For 'live' mode only] decisions cache time (in seconds) (default: `1`) : `-e CACHE_EXPIRATION="1"`
* `CACHE_SIZE`       - The maximum number of decisions in cache (default: `1000`) : `-e CACHE_SIZE="1000"`
* `BOUNCING_ON_TYPE` - The decisions type the bouncer should remediate on (default: `ban`) : `-e BOUNCING_ON_TYPE="ban"`
* `REQUEST_TIMEOUT`  - Request timeout (in seconds) for LAPI request (default: `0.2`) : `-e REQUEST_TIMEOUT="0.2"`
* `UPDATE_FREQUENCY` - [For 'stream' mode only] pull frequency (in seconds) from LAPI (default: `10`) : `-e UPDATE_FREQUENCY="10"`
* `MODE`             - Bouncer mode : streaming (`stream`) or rupture (`live`) mode (default: `stream`) : `-e MODE="stream"`
* `CAPTCHA_PROVIDER` - The selected captcha provider for your `SITE_KEY` and `SECRET_KEY`. Valid providers are recaptcha, hcaptcha or turnstile. For backwards compatability the default is recaptcha if not provided.
* `SITE_KEY`         - The site key for the selected captcha provider.
* `SECRET_KEY`       - The secret key for the selected captcha provider.

### Volumes

* `/etc/crowdsec/` - Directory where all crowdsec configurations are located

#### Useful File Locations

* `/usr/local/openresty/lualib/plugins/crowdsec` - Crowdsec lua library path
  
* `/etc/nginx/conf.d` - Nginx configuration to load the crowdsec bouncer lua library and configuration.

## Find Us

* [cs-openresty-bouncer GitHub](https://github.com/crowdsecurity/cs-openresty-bouncer)
* [Crowdsec GitHub](https://github.com/crowdsecurity/crowdsec)

## Contributing

Please read [contributing](https://docs.crowdsec.net/Crowdsec/v1/contributing/) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/crowdsecurity/cs-openresty-bouncer/blob/main/LICENSE) file for details.

# CrowdSec OpenResty Bouncer

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

### Environment Variables

* `API_URL`          - Crowdsec local API URL : `-e API_URL="http://172.17.0.1:8080"`
* `API_KEY`          - Disable local API (default: `false`) : `-e API_KEY="abcdefghijklmnopqrstuvwxyz"`
* `CACHE_EXPIRATION` - Decisions cache time (in seconds) (default: `1`) : `-e CACHE_EXPIRATION="1"`
* `CACHE_SIZE`       - The maximum number of decisions in cache (default: `1000`) : `-e CACHE_SIZE="1000"`
* `BOUNCING_ON_TYPE` - The decisions type the bouncer should remediate on (default: `ban`) : `-e BOUNCING_ON_TYPE="ban"`
* `REQUEST_TIMEOUT`  - Request timeout (in seconds) for LAPI request (default: `0.2`) : `-e REQUEST_TIMEOUT="0.2"`

### Volumes

* `/etc/crowdsec/` - Directory where all crowdsec configurations are located

#### Useful File Locations

* `/usr/local/openresty/lualib/crowdsec` - Crowdsec lua library path
  
* `/etc/nginx/conf.d` - Nginx configuration to load the crowdsec bouncer lua library and configuration.

## Find Us

* [cs-openresty-bouncer GitHub](https://github.com/crowdsecurity/cs-openresty-bouncer)
* [Crowdsec GitHub](https://github.com/crowdsecurity/crowdsec)

## Contributing

Please read [contributing](https://docs.crowdsec.net/Crowdsec/v1/contributing/) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/crowdsecurity/cs-openresty-bouncer/blob/main/LICENSE) file for details.
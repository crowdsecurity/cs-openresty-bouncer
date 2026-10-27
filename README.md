<p align="center">
<img src="https://github.com/crowdsecurity/cs-openresty-bouncer/raw/main/docs/assets/crowdsec_openresty.png" alt="CrowdSec" title="CrowdSec" width="280" height="300" />
</p>
<p align="center">
<img src="https://img.shields.io/badge/build-pass-green">
<img src="https://img.shields.io/badge/tests-pass-green">
</p>
<p align="center">
&#x1F4DA; <a href="#installation/">Documentation</a>
&#x1F4A0; <a href="https://hub.crowdsec.net">Hub</a>
&#128172; <a href="https://discourse.crowdsec.net">Discourse </a>
</p>



# CrowdSec OpenResty Bouncer

A lua bouncer for OpenResty.

## How does it work ?

This bouncer leverages OpenResty lua's API, namely `access_by_lua_file`.

New/unknown IP are checked against crowdsec API, and if request should be blocked, a **403** is returned to the user, and put in cache.

# Installation

Please follow the [official documentation](https://doc.crowdsec.net/docs/bouncers/openresty).

# Vendored dependencies

Pure-Lua dependencies (currently `lua-resty-http`) are vendored under `vendor/`, pinned by tag and commit in `vendor/vendor.conf`, and installed with the bouncer in `/usr/local/openresty/lualib/plugins/crowdsec/`, not in OpenResty's shared `lualib/`. `lua-cjson` is bundled with OpenResty, so `opm` is no longer needed.

```sh
./scripts/vendor.sh list                          # pinned versions
./scripts/vendor.sh outdated                      # newer upstream tags
./scripts/vendor.sh update lua-resty-http [tag]   # bump (default: latest tag)
./scripts/vendor.sh verify                        # vendor/ matches upstream
./scripts/vendor.sh advisories                    # upstream security advisories (needs gh)
```

The `vendored-dependencies` workflow runs weekly, opens a PR for each outdated dependency and reports upstream security advisories.

local cs = require "plugins.crowdsec.crowdsec"
local ngx = ngx

local _M = {}
local ok, err = cs.init("/etc/nginx/lua/plugins/crowdsec/crowdsec-bouncer.conf", "crowdsec-openresty-bouncer/v0.1.11")
if ok == nil then
    ngx.log(ngx.ERR, "[Crowdsec] " .. err)
    error()
end
ngx.log(ngx.ALERT, "[Crowdsec] Initialisation done")

function _M.rewrite()
	cs.Allow(ngx.var.remote_addr)
end

return _M

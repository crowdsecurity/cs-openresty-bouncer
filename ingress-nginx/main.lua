local cs = require "plugins.crowdsec.crowdsec"
local ngx = ngx

local _M = {}

function _M.init_worker()
	local ok, err = cs.init("/etc/nginx/lua/plugins/crowdsec/crowdsec-bouncer.conf", "crowdsec-openresty-bouncer/v0.0.1")
	if ok == nil then
		ngx.log(ngx.ERR, "[Crowdsec] " .. err)
		error()
	end
	ngx.log(ngx.NOTICE, "[Crowdsec] Initialisation done")
end

function _M.rewrite()
    local remote_addr = ngx.var.remote_addr
    local is_allowed, err = cs.allowIp(remote_addr)
    if err ~= nil then
        ngx.log(ngx.ERR, "[Crowdsec] bouncer error " .. err)
    end
    if is_allowed == nil then
        ngx.log(ngx.ERR, "[Crowdsec] " .. err)
    end
    if not is_allowed then
        ngx.log(ngx.ALERT, "[Crowdsec] denied '" .. ngx.var.remote_addr .. "'")
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

return _M
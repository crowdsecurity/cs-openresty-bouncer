local cs = require "plugins.crowdsec.crowdsec"
local ngx = ngx

local _M = {}
local ok, err = cs.init("/etc/nginx/lua/plugins/crowdsec/crowdsec-bouncer.conf", "crowdsec-openresty-bouncer/v1.1.0")
if ok == nil then
    ngx.log(ngx.ERR, "[Crowdsec] " .. err)
    error()
end
ngx.log(ngx.ALERT, "[Crowdsec] Initialisation done")

function _M.init_worker()
    -- This function is called once per worker
    -- It can be used to initialize the worker
    -- For example, to load the configuration file
    local mode = cs.get_mode()
    if string.lower(mode) == "stream" then
        ngx.log(ngx.INFO, "Initializing stream mode for worker " .. tostring(ngx.worker.id()))
        cs.SetupStream()
    end
    cs.debug_metrics()

    ngx.log(ngx.INFO, "Crowdsec bouncer initialized in " .. mode .. " mode for worker " .. tostring(ngx.worker.id()))
    if ngx.worker.id() == 0 then
        cs.SetupMetrics()
    end
end


function _M.rewrite()
	cs.Allow(ngx.var.remote_addr)
end

return _M

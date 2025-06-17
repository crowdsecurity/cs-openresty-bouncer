local cs = require "plugins.crowdsec.crowdsec"
local ngx = ngx
local dict = ngx.shared.crowdsec_init or ngx.shared.plugin_locks  -- define in nginx conf
local init_key = "crowdsec_init_done"

local _M = {}
local ok, err = cs.init("/etc/nginx/lua/plugins/crowdsec/crowdsec-bouncer.conf", "crowdsec-openresty-bouncer/v1.1.0")
if ok == nil then
    ngx.log(ngx.ERR, "[Crowdsec] " .. err)
    error()
end

ensure_initialized()
ngx.log(ngx.ALERT, "[Crowdsec] Initialisation done")

function _M.rewrite()
	cs.Allow(ngx.var.remote_addr)
end

local function ensure_initialized()
    local ok, err = dict:get(init_key)
    if ok then
        return
    end

    -- try to claim the init
    local success, err = dict:add(init_key, true)
    if success then
        -- this worker does the init
        cs = require "crowdsec"
        local mode = cs.get_mode()
        if string.lower(mode) == "stream" then
           ngx.log(ngx.INFO, "Initializing stream mode for worker " .. tostring(ngx.worker.id()))
           cs.SetupStream()
        end

        if ngx.worker.id() == 0 then
           ngx.log(ngx.INFO, "Initializing metrics for worker " .. tostring(ngx.worker.id()))
           cs.SetupMetrics()
        end
    end
end

return _M

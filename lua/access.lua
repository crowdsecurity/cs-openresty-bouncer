ok, err = require "crowdsec".allowIp(ngx.var.remote_addr)
if err ~= nil then 
    ngx.log(ngx.ERR, "[Crowdsec] bouncer error: " .. err)
end
if not ok then
    ngx.log(ngx.ALERT, "[Crowdsec] denied '" .. ngx.var.remote_addr .. "'")
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

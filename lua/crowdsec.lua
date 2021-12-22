package.path = package.path .. ";./?.lua"

local config = require "plugins.crowdsec.config"
local lrucache = require "resty.lrucache"
local http = require "resty.http"
local cjson = require "cjson"
cjson.decode_array_with_array_mt(true)


-- contain runtime = {}
local runtime = {}


function ipToInt( str )
	local num = 0
	if str and type(str)=="string" then
		local o1,o2,o3,o4 = str:match("(%d+)%.(%d+)%.(%d+)%.(%d+)" )
		num = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
	end
    return num
end


local csmod = {}

-- init function
function csmod.init(configFile, userAgent)
  local conf, err = config.loadConfig(configFile)
  if conf == nil then
    return nil, err
  end
  runtime.conf = conf
  runtime.userAgent = userAgent
  local c, err = lrucache.new(conf["CACHE_SIZE"])
  if not c then
    error("failed to create the cache: " .. (err or "unknown"))
  end
  runtime.cache = c
  return true, nil
end


function csmod.allowIp(ip)
  if runtime.conf == nil then
    return true, "Configuration is bad, cannot run properly"
  end
  local data = runtime.cache:get(ip)

  if data ~= nil then -- we have it in cache
    ngx.log(ngx.DEBUG, "'" .. ip .. "' is in cache")
    return data, nil
  end

  -- not in cache
  local link = runtime.conf["API_URL"] .. "/v1/decisions?ip=" .. ip
  local httpc = http.new()
  httpc:set_timeout(runtime.conf['REQUEST_TIMEOUT'])
  local res, err = httpc:request_uri(link, {
    method = "GET",
    headers = {
      ['Connection'] = 'close',
      ['X-Api-Key'] = runtime.conf["API_KEY"],
      ['User-Agent'] = runtime.userAgent
    },
  })
  if not res then
    return true, "request failed: ".. err
  end

  local status = res.status
  local body = res.body
  if status~=200 then
    return true, "Http error " .. status .. " while talking to LAPI (" .. link .. ")" 
  end
  if body == "null" then -- no result from API, no decision for this IP
    -- set ip in cache and DON'T block it
    runtime.cache:set(ip, true,runtime.conf["CACHE_EXPIRATION"])
    return true, nil
  end
  local decision = cjson.decode(body)[1]

  if runtime.conf["BOUNCING_ON_TYPE"] == decision.type or runtime.conf["BOUNCING_ON_TYPE"] == "all" then
    -- set ip in cache and block it
    runtime.cache:set(ip, false,runtime.conf["CACHE_EXPIRATION"])
    return false, nil
  else
    return true, nil
  end
end


-- Use it if you are able to close at shuttime
function csmod.close()
end

return csmod

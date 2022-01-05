package.path = package.path .. ";./?.lua"

local config = require "plugins.crowdsec.config"
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
  runtime.cache = ngx.shared.crowdsec

  -- if stream mode, add callback to stream_query and start timer
  if runtime.conf["MODE"] == "stream" then
    runtime.cache:set("startup", true)
    runtime.cache:set("first_run", true)
  end

  return true, nil
end

function http_request(link)
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
  return res, err
end

function parse_duration(duration)
  local match, err = ngx.re.match(duration, "((?<hours>[0-9]+)h)?((?<minutes>[0-9]+)m)?(?<seconds>[0-9]+)")
  local ttl = 0
  if not match then
    if err then
      return ttl, err
    end
  end
  if match["hours"] ~= nil then
    local hours = tonumber(match["hours"])
    ttl = ttl + (hours * 3600)
  end
  if match["minutes"] ~= nil then
    local minutes = tonumber(match["minutes"])
    ttl = ttl + (minutes * 60)
  end
  if match["seconds"] ~= nil then
    local seconds = tonumber(match["seconds"])
    ttl = ttl + seconds
  end
  return ttl, nil
end

function stream_query()
  -- As this function is running inside coroutine (with ngx.timer.every), 
  -- we need to raise error instead of returning them
  ngx.log(ngx.DEBUG, "Stream Query from worker : " .. tostring(ngx.worker.id()) .. " with startup "..tostring(runtime.cache:get("startup")))
  local link = runtime.conf["API_URL"] .. "/v1/decisions/stream?startup=" .. tostring(runtime.cache:get("startup"))
  local res, err = http_request(link)
  if not res then
    error("request failed: ".. err)
  end

  local status = res.status
  local body = res.body
  if status~=200 then
    error("Http error " .. status .. " with message (" .. tostring(body) .. ")")
  end

  local decisions = cjson.decode(body)
  -- process deleted decisions
  if type(decisions.deleted) == "table" then
    for i, decision in pairs(decisions.deleted) do
      runtime.cache:delete(decision.value)
      ngx.log(ngx.DEBUG, "Deleting '" .. decision.value .. "'")
    end
  end

  -- process new decisions
  if type(decisions.new) == "table" then
    for i, decision in pairs(decisions.new) do
      if runtime.conf["BOUNCING_ON_TYPE"] == decision.type or runtime.conf["BOUNCING_ON_TYPE"] == "all" then
        local ttl, err = parse_duration(decision.duration)
        if err ~= nil then
          ngx.log(ngx.ERR, "[Crowdsec] failed to parse ban duration '" .. decision.duration .. "' : " .. err)
        end
        local succ, err, forcible = runtime.cache:set(decision.value, false, ttl)
        if not succ then
          ngx.log(ngx.ERR, "failed to add ".. decision.value .." : "..err)
        end
        if forcible then
          ngx.log(ngx.ERR, "Lua shared dict (crowdsec cache) is full, please increase dict size in config")
        end
        ngx.log(ngx.DEBUG, "Adding '" .. decision.value .. "' in cache for '" .. ttl .. "' seconds")
      end
    end
  end

  -- not startup anymore after first callback
  runtime.cache:set("startup", false)
  return nil
end

function live_query(ip)
  local link = runtime.conf["API_URL"] .. "/v1/decisions?ip=" .. ip
  local res, err = http_request(link)
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


function csmod.allowIp(ip)
  if runtime.conf == nil then
    return true, "Configuration is bad, cannot run properly"
  end

  -- if it stream mode and startup start timer
  if runtime.cache:get("first_run") == true then 
    local ok, err = ngx.timer.every(runtime.conf["UPDATE_FREQUENCY"], stream_query)
    if not ok then
      runtime.cache:set("first_run", true)
      return true, "Failed to create the timer: " .. (err or "unknown")
    end
    runtime.cache:set("first_run", false)
    ngx.log(ngx.DEBUG, "Timer launched")
  end

  local data = runtime.cache:get(ip)
  if data ~= nil then -- we have it in cache
    ngx.log(ngx.DEBUG, "'" .. ip .. "' is in cache")
    return data, nil
  end

  -- if live mode, query lapi
  if runtime.conf["MODE"] == "live" then
    local ok, err = live_query(ip)
    return ok, err
  end
  return true, nil
end


-- Use it if you are able to close at shuttime
function csmod.close()
end

return csmod

local status = require "status"
local summary = require "summary"
local json = require "json"
local pretty_json = require "resty.pretty.json"
local remote_logging = require "remote_logging"

status.log()
summary.log()

local function getval(v, def)
    if v == nil then
        return def
    end
    return v
end

--[[local function parse(map)
    local s = ""
    for k, v in pairs(map) do
        ngx.log(ngx.NOTICE, k, ": ", v)
        s = s .. string.format("%s: %s\n", k ,v)
    end
end]]

local function get_log()

    local data = {}

    data["request_host"] = ngx.var.host
    data["request_uri"] = ngx.var.uri

    data["request_raw_headers"] = ngx.req.raw_header()
    for k, v in pairs(ngx.req.get_headers()) do
        data["request_header_" .. string.lower(k):gsub("-", "_")] = v
    end

    data["request_time"] = ngx.req.start_time()
    data["request_method"] = ngx.req.get_method()
    --data["request_get_args"] = ngx.req.get_uri_args()
    data["request_query_args_full"] = ngx.var.request_uri

    data["request_query_args"] = ngx.req.get_uri_args()

    --req["post_args"] = ngx.req.get_post_args()
    data["request_body"] = ""
    data["request_body"] = ngx.var.request_body

    data["response_raw_headers"] = ""
    for k, v in pairs(ngx.resp.get_headers()) do
        data["response_raw_headers"] = data["response_raw_headers"] .. string.format("%s: %s\n", string.lower(k) ,v)
        data["response_header_" .. string.lower(k):gsub("-", "_")] = v
    end

    data["response_status"] = ngx.var.status

    --data["response_duration"] = getval(ngx.var.upstream_response_time, 0)
    --data["response_time_ms"] = (ngx.now() - ngx.req.start_time()) * 1000
    --data["response_body"] = getval(ngx.var.response_body,"")

    return data
end


local function send_log(premature, msg)
    --ngx.log(ngx.NOTICE, s)
    remote_logging.log(msg)
end

local log = get_log()
ngx.log(ngx.NOTICE, "\n", pretty_json.stringify(log, nil, 4), "\n")

local ok, err = ngx.timer.at(0, send_log, json.encode(log))

if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end
-- -*- coding: utf-8 -*-
-- -- @Date    : 2022-03-14 15:03
-- -- @Author  : Quoc-Bao Nguyen (baonq5@vng.com.vn)
-- -- @Link    :
-- -- @Disc    : Send access log to remote TCP raw socket

local _M = {}

local REMOTE_SERVER = "172.25.148.88"
local REMOTE_PORT = 5555

--local REMOTE_SERVER = "127.0.0.1"
--local REMOTE_PORT = 12201

local logger = require "resty.logger.socket"
-- local json = require("json")

function _M.init()

    if not logger.initted() then
        local ok, err = logger.init{
            host = REMOTE_SERVER,
            port = REMOTE_PORT,

            -- If the buffered messages' size plus the current message size reaches (>=) this limit (in bytes),
            -- the buffered log messages will be written to log server. Default to 4096 (4KB).
            flush_limit = 4096,

            -- If the buffered messages' size plus the current message size is larger than this limit (in bytes),
            -- the current log message will be dropped because of limited buffer size. Default drop_limit is 1048576 (1MB).
            drop_limit = 1048576,

            -- Periodic flush interval (in seconds). Set to nil to turn off this feature.
            periodic_flush = 10
        }

        if not ok then
            ngx.log(ngx.ERR, "failed to initialize the logger: ",err)
            return
        end

        logger.log("Remote logger started\n")
        logger.flush()
        ngx.log(ngx.NOTICE, "logger inited")

    end

end



function _M.log(msg)

    if not logger.initted() then
        _M.init()
    end

    local bytes, err = logger.log(msg .. '\n')
    --logger.flush()

    if err then
        ngx.log(ngx.ERR, "failed to log message: ", err)
        return
    end

    ngx.log(ngx.NOTICE, string.format("Sent %d bytes to %s:%d", bytes, REMOTE_SERVER, REMOTE_PORT))

end

return _M

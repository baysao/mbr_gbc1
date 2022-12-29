-- Copyright (C) 2013 LazyZhu (lazyzhu.com)
-- Copyright (C) 2013 IdeaWu (ideawu.com)
-- Copyright (C) 2012 Yichun Zhang (agentzh)

local sub = string.sub
--local tcp = ngx.socket.tcp
local _tcp, _null, _TIME_MULTIPLY
_TIME_MULTIPLY = 1000
if ngx and ngx.socket then
    _null = ngx.null
    _tcp = ngx.socket.tcp
else
    local socket = require("socket")
    _tcp = socket.tcp
    _null = function()
        return nil
    end
end

local insert = table.insert
local concat = table.concat
local len = string.len
--local null = ngx.null
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local tonumber = tonumber
local error = error
local gmatch = string.gmatch
local remove = table.remove

local Ssdb = cc.class("Ssdb")

_VERSION = "0.02"
Ssdb.VERSION = _VERSION
Ssdb.null = _null

local DEFAULT_HOST = "localhost"
local DEFAULT_PORT = 8888

function Ssdb:ctor()
    self._config = {}
end

local commands = {
    "set",
    "get",
    "del",
    "scan",
    "rscan",
    "keys",
    "incr",
    "decr",
    "exists",
    "multi_set",
    "multi_get",
    "multi_del",
    "multi_exists",
    "hset",
    "hget",
    "hdel",
    "hscan",
    "hrscan",
    "hkeys",
    "hincr",
    "hdecr",
    "hexists",
    "hsize",
    "hlist",
    --[[ "multi_hset", ]] "multi_hget",
    "multi_hdel",
    "multi_hexists",
    "multi_hsize",
    "zset",
    "zget",
    "zdel",
    "zscan",
    "zrscan",
    "zkeys",
    "zincr",
    "zdecr",
    "zexists",
    "zsize",
    "zlist",
    --[[ "multi_zset", ]] "multi_zget",
    "multi_zdel",
    "multi_zexists",
    "multi_zsize"
}

--function connect(self, ...)
function Ssdb:connect(host, port)
   local sock, err, ok
   host = host or DEFAULT_HOST

    sock, err = _tcp()
    if not sock then
        return nil, err
    end
    ok, err = sock:connect(host, port)
    if not ok then
        return nil, err
    end
    
    self.sock = sock
    self._config = {host = host, port = port or DEFAULT_PORT}
    return 1
end

function Ssdb:set_timeout(timeout)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout * _TIME_MULTIPLY)
end

function Ssdb:set_keepalive(...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    self.sock = nil
    if not ngx then
        return sock:close()
    else
        return sock:setkeepalive(...)
    end
end

function Ssdb:get_reused_times()
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    if sock.getreusedtimes then
        return sock:getreusedtimes()
    else
        return 0
    end
end

function Ssdb:close()
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    self.sock = nil
    return sock:close()
end

local function _read_reply(sock)
    local val = {}

    while true do
        -- read block size
        local line, err, partial = sock:receive()
        if not line or len(line) == 0 then
            -- packet end
            break
        end
        local d_len = tonumber(line)

        -- read block data
        local data, err, partial = sock:receive(d_len)
        insert(val, data)

        -- ignore the trailing lf/crlf after block data
        local line, err, partial = sock:receive()
    end

    local v_num = tonumber(#val)

    if v_num == 1 then
        return val
    else
        remove(val, 1)
        return val
    end
end

local function _gen_req(args)
    local req = {}

    for i = 1, #args do
        local arg = args[i]

        if arg then
            insert(req, len(arg))
            insert(req, "\n")
            insert(req, arg)
            insert(req, "\n")
        else
            return nil, err
        end
    end
    insert(req, "\n")

    -- it is faster to do string concatenation on the Lua land
    -- print("request: ", table.concat(req, ""))

    return concat(req, "")
end

local function _do_cmd(self, ...)
    local args = {...}

    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local req = _gen_req(args)

    local reqs = self._reqs
    if reqs then
        insert(reqs, req)
        return
    end

    local bytes, err = sock:send(req)
    if not bytes then
        return nil, err
    end

    return _read_reply(sock)
end



function Ssdb:multi_hset(hashname, ...)
    local args = {...}
    if #args == 1 then
        local t = args[1]
        local array = {}
        for k, v in pairs(t) do
            insert(array, k)
            insert(array, v)
        end
        -- print("key", hashname)
        return _do_cmd(self, "multi_hset", hashname, unpack(array))
    end

    -- backwards compatibility
    return _do_cmd(self, "multi_hset", hashname, ...)
end

function Ssdb:multi_zset( keyname, ...)
    local args = {...}
    if #args == 1 then
        local t = args[1]
        local array = {}
        for k, v in pairs(t) do
            insert(array, k)
            insert(array, v)
        end
        -- print("key", keyname)
        return _do_cmd(self, "multi_zset", keyname, unpack(array))
    end

    -- backwards compatibility
    return _do_cmd(self, "multi_zset", keyname, ...)
end

function Ssdb:init_pipeline()
    self._reqs = {}
end

function Ssdb:cancel_pipeline()
    self._reqs = nil
end

function Ssdb:commit_pipeline()
    local reqs = self._reqs
    if not reqs then
        return nil, "no pipeline"
    end

    self._reqs = nil

    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local bytes, err = sock:send(reqs)
    if not bytes then
        return nil, err
    end

    local vals = {}
    for i = 1, #reqs do
        local res, err = _read_reply(sock)
        if res then
            insert(vals, res)
        elseif res == nil then
            return nil, err
        else
            insert(vals, err)
        end
    end

    return vals
end

function Ssdb:array_to_hash(t)
    local h = {}
    for i = 1, #t, 2 do
        h[t[i]] = t[i + 1]
    end
    return h
end

for i = 1, #commands do
    local cmd = commands[i]

    Ssdb[cmd] = function(self, ...)
        return _do_cmd(self, cmd, ...)
    end
end

return Ssdb

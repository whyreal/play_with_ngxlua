local string = string
local table = table

local ngx = require "ngx"
module(...)

local DEFAULT_SEPARATOR = ':'

local function handle_error(e) --{{{1
    ngx.status = e.status
    ngx.say(e.msg)
    ngx.exit(ngx.OK)
end

local function gen_error(code, msg) --{{{1
    return {status = code, msg = msg}
end

local function parse_url_args(base, separator) --{{{1
    separator = separator and separator or DEFAULT_SEPARATOR
    uri = ngx.var.uri

    if string.match(uri, separator) then
        return nil, gen_error(400, "Url can't contain ':'")
    end

    local uri_args = {}
    string.gsub( -- strip and split the uri
        string.sub(uri, string.len(base) + 1), '[^/' .. separator .. ']+',
            function(w)

            table.insert(uri_args, w)
        end)
end

local function get_request_body() --{{{1
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if not data then
        return nil, gen_error(500, "post data size is zero or bigger than nginx client_body_buffer_size")
    end

    if string.len(data) == 0 then
        return nil, gen_error(400, "empty body")
    end
end

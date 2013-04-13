local utils = require "utility"
local ngx = require "ngx"
module(...)

local function rewrite_supervisor(form, to, dict_name, key, error_page) --{{{1
    local dict = ngx.shared[dict_name]
    local status = _status(dict, key)

    if status == false then
        return
    end

    local uri = ngx.re.sub(ngx.var.uri, form, to, "o")
    ngx.req.set_uri(uri)
end

local function location_supervisor(key, dict_name) --{{{1
    local dict = ngx.shared[dict_name]
    local status = _status(dict, key)

    if status == false then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

local function status(base, dict) --{{{1
    uri_args, err = utils.parse_url_args(base)
    err and utils.handle_error(err)

    key = uri_args[1]
    key or utils.handle_error(utils.gen_error(400, 'no key'))

    local method = ngx.req.get_method()
    if method == 'GET' then
        _status(dict, key)
    end

    if method == 'POST' then
        data, err = utils.get_request_body()
        err and utils.handle_error(err)

        _status(dict, key, data)
    end
end

local function _status(dict, key, value) --{{{1
    value and dict:set(key, value) or dict:get(key)
end

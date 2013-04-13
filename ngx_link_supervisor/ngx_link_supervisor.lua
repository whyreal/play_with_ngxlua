local utils = require "utility"
local ngx = require "ngx"
module(...)

-- Constent {{{1
DEFAULT_DICT = "ngx_link_supervisor_db"

local function _status(dict, key, value) --{{{1
    if value then
        dict:set(key, value)
    end

    return dict:get(key)
end

function rewrite(form, to, key, jump, dict_name) --{{{1
    if not jump then jump = false end
    if not dict_name then dict_name = DEFAULT_DICT end

    local dict = ngx.shared[dict_name]
    local status = _status(dict, key)

    if status == '0' then
        return
    end

    local uri = ngx.re.sub(ngx.var.uri, form, to, "o")
    ngx.req.set_uri(uri, jump)
end

function deny(key, dict_name) --{{{1
    if not dict_name then dict_name = DEFAULT_DICT end

    local dict = ngx.shared[dict_name]
    local status = _status(dict, key)

    if status == '0' then
        return
    end

    ngx.exit(ngx.HTTP_FORBIDDEN)
end

function status(base, dict_name) --{{{1
    if not dict_name then dict_name = DEFAULT_DICT end

    local ret
    local dict = ngx.shared[dict_name]

    uri_args, err = utils.parse_url_args(base)
    if err then utils.handle_error(err) end

    local key = uri_args[1]
    if not key then
        utils.handle_error(utils.gen_error(400, 'no key'))
    end

    local method = ngx.req.get_method()
    if method == 'GET' then
        ret, err = _status(dict, key)
        if err then utils.handle_error(err) end
    end

    if method == 'POST' then
        data, err = utils.get_request_body()
        if err then utils.handle_error(err) end

        ret, err = _status(dict, key, data)
        if err then utils.handle_error(err) end

    end

    ngx.say(ret)
end

local ngx = require "ngx"
local string = string
local table = table
local pairs = pairs
local ipairs = ipairs
local config = require (... .. "_config")

module(...)

local default_view = 'default'
local SEPARATOR = ':'

local function gen_error(code, msg)
    return {status = code, msg = msg}
end

local function handle_error(e)
    ngx.status = e.status
    ngx.say(e.msg)
    ngx.exit(ngx.OK)
end

local function search_view(ip)
    for k, v in pairs(config.views) do
        if string.match(ip, "^" .. k) then
            return v
        end
    end
end

local function joint_key(opt)
    opt.key = table.concat({opt.namespace, opt.resource, opt.view}, SEPARATOR)
    opt.default_key = table.concat({
        opt.namespace, opt.resource, default_view
    }, SEPARATOR)
end

local handlers = {}
handlers.GET = function (dict, options)
    if options.view == 'listing' then
        return handlers.listing(dict, options)
    end

    if not options.view then options.view = default_view end
    joint_key(options)

    local res = dict:get(options.key)

    if not res then res = dict:get(options.default_key) end
    if not res then res = "" end

    return res
end

handlers.POST = function (dict, options)
    if not options.view then return nil, gen_error(400, "no view") end
    joint_key(options)

    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if not data then
        return nil, gen_error(500, "post data size is zero or bigger than nginx client_body_buffer_size")
    end
    if string.len(data) == 0 then
        return nil, gen_error(400, "empty body")
    end

    dict:set(options.key, data)
    -- default view should not be empty
    dict:add(options.default_key, data)
    return ""
end

handlers.DELETE = function (dict, options)
    if not options.view then return nil, gen_error(400, "no view") end
    joint_key(options)

    if options.view == default_view then
        for _, k in ipairs(dict:get_keys(0)) do
            if string.match(k, options.resource) and
                    k ~= options.default_key then
                return nil, gen_error(400, "view data should be deleted first before delete the default")
            end
        end
    end

    dict:delete(options.key)
    return ""
end

handlers.listing = function (dict, options)
    local path
    for _, k in ipairs(dict:get_keys(0)) do
        if string.match(k, options.resource) then
            path = string.gsub(k, SEPARATOR, '/')
            ngx.say(path)
        end
    end
    return ""
end

function parse_uri(prefix, uri, dynamic)
    dynamic = dynamic or false

    if string.match(uri, SEPARATOR) then
        return nil, gen_error(400, "Url can't contain ':'")
    end

    local _ = {}
    string.gsub( -- strip and split the uri
        string.sub(uri, string.len(prefix) + 1), '[^/' .. SEPARATOR .. ']+', function(w)
            table.insert(_, w)
        end)
    local res = {
        namespace = _[1],
        resource = _[2],
        view = _[3],
    }

    if not res.namespace then
        return nil, gen_error(400, "no namespace")
    end

    if not res.resource then
        return nil, gen_error(400, "no resource")
    end

    if not res.view and dynamic then
        res.view = search_view(ngx.var.remote_addr)
    end

    return res
end

function handle(uri_prefix, dict_name)
    local opt, err
    local method = ngx.req.get_method()
    if method == 'GET' then
        opt, err = parse_uri(uri_prefix, ngx.var.uri, true)
    else
        opt, err = parse_uri(uri_prefix, ngx.var.uri)
    end
    if not opt then
        handle_error(err)
    end

    local result, err = handlers[method](ngx.shared[dict_name], opt)
    if result then
        ngx.say(result)
        ngx.exit(ngx.OK)
    else
        handle_error(err)
    end
end

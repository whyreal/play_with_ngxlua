-- 可以用module(..., package.seeall)，但是副作用忒大。
local string = string
local table = table
local pairs = pairs
local ipairs = ipairs

local utils = require "utility"
local ngx = require "ngx"
local config = require (... .. "_config")

module(...)

local DEFAULT_VIEW = 'default'

local function search_view(ip) --{{{1
    for k, v in pairs(config.views) do
        if string.match(ip, "^" .. k) then
            return v
        end
    end
end

local function joint_key(opt) --{{{1
    opt.key = table.concat({
        opt.namespace, opt.resource, opt.view
    }, KEY_SEPARATOR)

    opt.default_key = table.concat({
        opt.namespace, opt.resource, DEFAULT_VIEW
    }, KEY_SEPARATOR)
end

local handlers = {} --{{{1

handlers.GET = function (dict, options) --{{{2
    if options.view == 'listing' then
        return handlers.listing(dict, options)
    end

    if not options.view then options.view = DEFAULT_VIEW end
    joint_key(options)

    local res = dict:get(options.key)

    if not res then res = dict:get(options.default_key) end
    if not res then res = "" end

    return res
end

handlers.POST = function (dict, options) --{{{2
    if not options.view then return nil, utils.gen_error(400, "no view") end
    joint_key(options)

    data, err = utils.get_request_body()
    err and utils.handle_error(err)

    dict:set(options.key, data)
    -- default view should not be empty
    dict:add(options.default_key, data)
    return ""
end

handlers.DELETE = function (dict, options) --{{{2
    if not options.view then return nil, utils.gen_error(400, "no view") end
    joint_key(options)

    if options.view == DEFAULT_VIEW then
        -- check whether the view has other view beside the default!
        for _, k in ipairs(dict:get_keys(0)) do
            if string.match(k, options.resource) and
                    k ~= options.default_key then

                return nil, utils.gen_error(400, "view data should be deleted first before delete the default")
            end
        end
    end

    dict:delete(options.key)
    return ""
end

handlers.listing = function (dict, options) --{{{2
    local path
    for _, k in ipairs(dict:get_keys(0)) do
        if string.match(k, options.resource) then
            path = string.gsub(k, KEY_SEPARATOR, '/')
            ngx.say(path)
        end
    end
    return ""
end

function extract_opt(base, dynamic) --{{{1
    dynamic = dynamic or false

    uri_args, err = utils.parse_url_args(base)
    err and utils.handle_error(err)

    local res = {
        namespace = uri_args[1],
        resource = uri_args[2],
        view = uri_args[3],
    }

    if not res.namespace then
        return nil, utils.gen_error(400, "no namespace")
    end

    if not res.resource then
        return nil, utils.gen_error(400, "no resource")
    end

    if not res.view and dynamic then
        res.view = search_view(ngx.var.remote_addr)
    end

    return res
end

function handle(uri_prefix, dict_name) --{{{1
    local method = ngx.req.get_method()

    -- parse uri
    if method == 'GET' then
        local opt, err = extract_opt(uri_prefix, true)
    else
        local opt, err = extract_opt(uri_prefix)
    end
    err and utils.handle_error(err)

    -- handle request
    local result, err = handlers[method](ngx.shared[dict_name], opt)
    err and utils.handle_error(err)

    ngx.say(result)
    ngx.exit(ngx.OK)
end

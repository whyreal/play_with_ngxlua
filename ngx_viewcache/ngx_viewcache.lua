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
local DEFAULT_DICT = 'ngx_viewcache_db'
local KEY_SEPARATOR = ':'

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

    local ret = dict:get(options.key)

    if not ret then ret = dict:get(options.default_key) end
    if not ret then ret = "" end

    ngx.say(ret)
end

handlers.POST = function (dict, options) --{{{2
    if not options.view then return nil, utils.gen_error(400, "no view") end
    joint_key(options)

    data, err = utils.get_request_body()
    if err then
        utils.handle_error(err)
    end

    dict:set(options.key, data)
    -- default view should not be empty
    dict:add(options.default_key, data)
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
end

handlers.listing = function (dict, options) --{{{2
    local path
    for _, k in ipairs(dict:get_keys(0)) do
        if string.match(k, options.resource) then
            path = string.gsub(k, KEY_SEPARATOR, '/')
            ngx.say(path)
        end
    end
end

function extract_opt(base, dynamic) --{{{1
    dynamic = dynamic or false

    uri_args, err = utils.parse_url_args(base)
    if err then
        utils.handle_error(err)
    end

    local ret = {
        namespace = uri_args[1],
        resource = uri_args[2],
        view = uri_args[3],
    }

    if not ret.namespace then
        return nil, utils.gen_error(400, "no namespace")
    end

    if not ret.resource then
        return nil, utils.gen_error(400, "no resource")
    end

    if not ret.view and dynamic then
        ret.view = search_view(ngx.var.remote_addr)
    end

    return ret
end

function handle(uri_prefix, dict_name) --{{{1
    if not dict_name then dict_name = DEFAULT_DICT end
    local method = ngx.req.get_method()

    -- parse uri
    local opt, err
    if method == 'GET' then
        opt, err = extract_opt(uri_prefix, true)
    else
        opt, err = extract_opt(uri_prefix)
    end
    if err then
        utils.handle_error(err)
    end

    -- handle request
    local result, err = handlers[method](ngx.shared[dict_name], opt)
    if err then
        utils.handle_error(err)
    end

    ngx.exit(ngx.OK)
end

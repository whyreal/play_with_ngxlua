[[提供一个开关来控制rewrite行为：是正常rewrite还是跳转到其他页面。可以用来动态的控制后端http接口是否可用。]]

# API

## Status
    >check or update supervisor status, 0 for excute, 1 for ignore, default 0.

request

    GET /base_uri/"${supervisor_name}" HTTP/1.1

response

    HTTP/1.1 200 OK

    1

request

    POST /base_uri/"${supervisor_name}" HTTP/1.1

    0

response

    HTTP/1.1 200 OK

    0

# Nginx config

    lua_shared_dict ngx_link_supervisor_db 10m;

    #lua_code_cache off;
    lua_package_path '/usr/local/nginx/play_with_ngxlua/ngx_link_supervisor/?.lua;/usr/local/nginx/play_with_ngxlua/ngx_viewcache/?.lua;/usr/local/nginx/play_with_ngxlua/?.lua;;';
    init_by_lua 'require "ngx_link_supervisor"';

    location ^~ /ngx_link_supervisor_status { # check supervisor status
        content_by_lua 'ngx_link_supervisor.status("/ngx_link_supervisor_status")';
    }

    location = /ngx_link_supervisor_test {
        access_by_lua 'ngx_link_supervisor.deny("access1")';
        rewrite_by_lua 'ngx_link_supervisor.rewrite("/(.*)", "/$1_rewrited", "rewrite1", true)';
        content_by_lua 'ngx.say("hello from location supervisor")';
    }

    location ^~ /ngx_link_supervisor_test_rewrited {
        content_by_lua 'ngx.say("rewrited by ngx_lua");';
    }


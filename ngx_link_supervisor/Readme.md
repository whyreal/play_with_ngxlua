[[提供一个开关来控制rewrite行为：是正常rewrite还是跳转到其他页面。可以用来动态的控制后端http接口是否可用。]]

# HTTP API

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

# Config API
## ngx_link_supervisor.rewrite

    rewrite_by_lua 'ngx_link_supervisor.rewrite("${from}", "${to}", "${flag}", ${jump})';

Example:

    rewrite_by_lua 'ngx_link_supervisor.rewrite("/(.*)_test", "/$1_rewrited", "rewrite1", true)';
    
    > The key 'rewrite1' will be checked, if it is 0, this rewrite directive will be ignore.

# ngx_link_supervisor.deny

    access_by_lua 'ngx_link_supervisor.deny("${flag}")';

Example:

    access_by_lua 'ngx_link_supervisor.deny("access1")';
    
    > The key 'access1' will be checked, if it is 0, this access directive will be ignore.


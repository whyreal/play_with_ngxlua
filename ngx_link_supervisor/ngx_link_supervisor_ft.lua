local utils = require "utility"

module(...)

function ft()
    utils._assert('/ngx_link_supervisor_test', 'rewrited by ngx_lua\n')
    utils._assert('/ngx_link_supervisor_status/rewrite1', '0\n', '0')

    --[[ ngx.location.capture wouldn't do access check, so deny() can't be tested
    utils._assert('/ngx_link_supervisor_test', '')
    utils._assert('/ngx_link_supervisor_status/access1', '0\n',  '0')
    ]]--
    utils._assert('/ngx_link_supervisor_test', 'hello from location supervisor\n')
end

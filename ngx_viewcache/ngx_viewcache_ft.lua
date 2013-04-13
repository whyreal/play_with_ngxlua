local ngx = require "ngx"
local utils = require "utility"
local assert = assert
module(...)

function ft()
    local base = '/ngx_viewcache'
    utils._assert(base .. '', "no namespace\n")
    utils._assert(base .. '/example.com', 'no resource\n')
    utils._assert(base .. '/example.com/mysql', '\n')

    utils._assert(base .. '/example.com/mysql', 'no view\n', 'default mysql')
    utils._assert(base .. '/example.com/mysql/view1', '', 'default mysql')
    utils._assert(base .. '/example.com/mysql', 'default mysql\n')
    utils._assert(base .. '/example.com/mysql/default', 'default mysql\n')
    utils._assert(base .. '/example.com/mysql/view1', 'default mysql\n')

    utils._assert(base .. '/example.com/mysql/view1', '', 'view1 mysql')
    utils._assert(base .. '/example.com/mysql/view1', 'view1 mysql\n')
    utils._assert(base .. '/example.com/mysql/default', 'default mysql\n')
    utils._assert(base .. '/example.com/mysql', 'view1 mysql\n')

    utils._assert(base .. '/example.com/mysql', 'no view\n', ngx.HTTP_DELETE)
    utils._assert(base .. '/example.com/mysql/default', 'view data should be deleted first before delete the default\n', ngx.HTTP_DELETE)
    utils._assert(base .. '/example.com/mysql/listing', 'example.com/mysql/default\nexample.com/mysql/view1\n')

    utils._assert(base .. '/example.com/mysql/view1', '', ngx.HTTP_DELETE)
    utils._assert(base .. '/example.com/mysql/listing',  'example.com/mysql/default\n')
    utils._assert(base .. '/example.com/mysql/default', '', ngx.HTTP_DELETE)
    utils._assert(base .. '/example.com/mysql/listing', '') 
end

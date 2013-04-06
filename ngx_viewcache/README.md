ngx_viewcache是一个基于ngx_lua实现的／restful风格的／带view的k/v系统。
>初衷是作为naming service使用（虽然我不是很清楚名字服务的定义）

应该具备以下功能：

1. 可以使用资源名查询到对应的value，理论上可以返回任意文本
2. 可以根据来源ip对同一个资源给出不同的结果（类似于dns中的view）
3. 可以对特定view的特定资源进行赋值，修改，删除等操作

不提供：
1. 验证／数据隔离。所有api，所有数据都是公开的。

# API
**All "${view}" is optional. Default view: default**

## Listing
- 列出当前某个资源的所有key
### Signature
request

    GET /"${name space}"/"${resource}/listing" HTTP/1.1

response

    HTTP/1.1 200 OK

    "${key1}"
    "${key2}"
    ...

### example
request

    GET /example.com/db/listing HTTP/1.1

response

    HTTP/1.1 200 OK

    example.com/db/view1
    example.com/db/default

## GET

- 通常不需要指定view，api会根据来源ip判断view
- 如果请求中指定了view，则使用该view查询
- 如果指定的view中没有找到请求的资源则使用默认值，如果没有默认值则返回空

### Signature
request

    GET /"${name space}"/"${resource}" HTTP/1.1

response

    HTTP/1.1 200 OK

    "${value of the resource}"

### Example

* request from host belong view1

        GET /example.com/db HTTP/1.1

  response

        HTTP/1.1 200 OK

        1.1.1.1:3306

-----------------------
* request form host belong view2

        GET /example.com/db HTTP/1.1
    
  response

        HTTP/1.1 200 OK
    
        2.2.2.2:3306

## SET & UPDATE

### Signature
request
    
    POST /"${name space}"/"${resource}"/"${view}" HTTP/1.1
    
    "${new value}"

response

    HTTP/1.1 200 OK
    
    ""

### Example

request 

    POST /example.com/db/idc1 HTTP/1.1
    
    2.2.2.2:3306

response

    HTTP/1.1 200 OK

## DELETE
delete操作又一些限制条件：必须指定view，删除default前必须删除其他view的数据

### Signature
request
    
    DELETE /"${name space}"/"${resource}"/"${view}" HTTP/1.1

response

    HTTP/1.1 200 OK
    
    ""

### Example

request 

    DELETE /example.com/db/idc1 HTTP/1.1

response

    HTTP/1.1 200 OK

# Config nginx

    location ^~ /viewcache {
        content_by_lua '
            require "ngx_viewcache"
            ngx_viewcache.handle("/viewcache", "viewdb")';
    }

可以通过/viewcache/example.com/db/view 访问api。

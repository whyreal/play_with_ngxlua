基于ngx_lua实现一个restful风格的，带view的，简单的，k/v系统。
>初衷是作为naming service使用（虽然我不是很清楚名字服务的定义）

应该具备以下功能：

1. 可以使用资源名查询到对应ip/host/port（其实就是一个k/v查询）,理论上可以返回任意文本，比如json，xml。。。
2. 可以根据来源ip对同一个资源给出不同的结果（类似于dns中的view）
3. 提供简单的查询统计信息，如查询量
4. 可以对特定view的特定资源进行赋值，修改，删除等操作

暂不支持：

1. 验证／数据隔离。所有api，所有数据都是公开的。


# API
**All "${view}" is optional, default all.**

**Default view: __default**

## GET

- 通常不需要指定view，api会根据来源ip判断view
- 如果请求中指定了view，则使用该view查询
- 如果指定的view中没有找到请求的资源则使用默认值，如果没有默认值则返回错误

### Signature
request
    
    GET /"${name space}"/"${resource}" HTTP/1.1

response

    HTTP/1.1 200 OK
    
    "${value of the resource}"

### Example

* request from host belong view1

        GET /myproject/db HTTP/1.1

  response

        HTTP/1.1 200 OK
    
        1.1.1.1:3306

-----------------------
* request form host belong view2

        GET /myproject/db HTTP/1.1
    
  response

        HTTP/1.1 200 OK
    
        2.2.2.2:3306

## SET & UPDATE
如果不指定view则操作默认view

### Signature
request
    
    POST /"${name space}"/"${resource}"/"${view}" HTTP/1.1
    
    "${new value}"

response

    HTTP/1.1 200 OK
    
    ""

### Example

request 

    POST /myproject/db/idc1 HTTP/1.1
    
    2.2.2.2:3306

response

    HTTP/1.1 200 OK

## DELETE
如果不指定view，则删除该资源在包含默认view在内的所有view中的信息。

### Signature
request
    
    DELETE /"${name space}"/"${resource}"/"${view}" HTTP/1.1

response

    HTTP/1.1 200 OK
    
    ""

### Example

request 

    DELETE /myproject/db/idc1 HTTP/1.1

response

    HTTP/1.1 200 OK

## STATUS

### Signature
request
    
    GET /status HTTP/1.1

response

    HTTP/1.1 200 OK
    
    "${name space1}":"${resource1}":"${count}"
    "${name space1}":"${resource2}":"${count}"
    "${name space2}":"${resource}":"${count}"
    ……

### Example

request 

    GET /status HTTP/1.1

response

    HTTP/1.1 200 OK
    
    myproject:db:123
    myproject:mc:1230   

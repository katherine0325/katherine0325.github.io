# Hapi如何单独为某个路由进行身份验证
-----

通常，我们的路由长配置和使用长这样：

server.js

```
server.auth.scheme('normal', authScheme); // 如何进行身份验证的函数写在authScheme
server.auth.strategy('normal', 'normal');
server.auth.default('normal');
```
一般来说，当对我们的某个路由进行请求的时候，需要先经过身份验证，以上就是身份验证的方式和函数

但是，如果我需要新增一个路由，我希望这个路由用另一个方式验证怎么办呢

首先，新增一个验证函数并注册它

server.js

```
server.auth.scheme('normal', coreAuthScheme);
// 新增一个验证函数
server.auth.scheme('special', specialAuthScheme);
server.auth.strategy('normal', 'normal');
// 注册
server.auth.strategy('special', 'special');
server.auth.default('normal');
```
在路由使用的时候添加一个auth参数

```
{
    method: 'GET',
    path: '/special',
    config: {
      handler: Controller.get,
      // 增加这一行，使得这个路由地址需要特别的走 special 这个身份验证
      auth: 'special',
    },
}
```

END


# 如何使用Okta验证登陆
-----

## 一、注册一个okta账号
由于我们只是开发调试，所以在okta dev网页中注册即可：[https://developer.okta.com/signup/](https://developer.okta.com/signup/)

注册登陆后，选择 applications，然后新建一个应用

![图片](https://uploader.shimo.im/f/s4pCALdiWQ411y3p.png!thumbnail)

如果你的应用是React，可以选择 Single Page App (SPA)

![图片](https://uploader.shimo.im/f/OSII1QWtINMaZ8S8.png!thumbnail)

Name：你的app的名字

Base URIs: 你所关联的应用的地址

Login redirect URIs: 登陆后转到的页面

点击 DONE 完成

![图片](https://uploader.shimo.im/f/8UMIIp3lAeozzG3w.png!thumbnail)

然后我们会得到一个 client id，这个需要记住，待会儿会用到

还有当前页面的地址，删除admin字样也会用到：[https://dev-779700.okta.com](https://dev-779700-admin.okta.com/admin/app/oidc_client/instance/0oa15g6iaiZdY3lis357/#tab-general)




## 二、服务端添加代码
```
import * as OktaJwtVerifier from '@okta/jwt-verifier';
const oktaJwtVerifier = new OktaJwtVerifier({
  clientId: `${config.clientId}`,
  issuer: `${config.issuer}/oauth2`,
  assertClaims: {
    aud: `${config.clientId}`,
  },
});
const token = ctx.request.header.authorization;
if (!token) {
  throw unauthorized(('token not found'));
}
const jwtPayload: string | object = await oktaJwtVerifier.verifyAccessToken(
  token,
);
if (typeof jwtPayload === 'string') {
  throw new Error('Jwt cannot be parsed');
}
const email: string = get(jwtPayload, 'claims.email');
if (isEmpty(email)) {
  throw new Error('Jwt cannot be parsed');
}
```
ps: 这里的config.clientId和config.issuer就是刚才我们注册的时候记录下来的client id和地址



## 三、客户端添加代码
```
import { ImplicitCallback, Security } from '@okta/okta-react';
const App = () => (
  <BrowserRouter>
    <Security
        issuer = {oktaIssuer}
        client_id={oktaClientId}
        redirect_uri={`${window.location.origin}/auth`}
      >
      {authRoute('/', MainPage)}
      <Route exact path='/auth' component={ImplicitCallback} />
    </Security>
  </BrowserRouter>
);


ReactDOM.render(<App />, document.getElementById('root'));
```

## END

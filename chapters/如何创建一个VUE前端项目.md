## 概述

我们以一个创建一个技术博客网站为例，说明如何创建一个简单的VUE前端项目

代码地址：[https://github.com/katherine0325/tec-blog](https://github.com/katherine0325/tec-blog)

最终效果：[https://katherinelo.gitee.io/tec-blog](https://katherinelo.gitee.io/tec-blog/#/)

最终效果截图：

![图片](https://uploader.shimo.im/f/cVJ65wVPArNNcmq7.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

![图片](https://uploader.shimo.im/f/oQwmVilPa2dzHgA0.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)



## 使用vue-cli脚手架创建项目

首先安装vue脚手架

```plain
npm install -g vue-cli
```
使用脚手架创建项目

```shell
# 由于这个项目我们希望创建的是webpack的vue项目，所以init后面跟webpack
# 项目名称我们定位 tec-blog
vue init webpack tec-blog
```
执行命令后会出现一系列的问题，全部直接回车或者选择Y就可以了。
然后我们会得到一个文件夹，文件夹内是由脚手架已经生成好的一个vue项目的基本框架

![图片](https://uploader.shimo.im/f/dYrcGVXOm59D90Zo.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

启动项目

```plain
npm start
```
在浏览器打开[http://localhost:8080](http://localhost:8080)可以看到脚手架给我们生成的基础项目

![图片](https://uploader.shimo.im/f/yPxL9zXkFSqJAdV9.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)



## 创建页面以及添加路由

我们打开src文件夹，这里是我们编程的主目录，原本是这样的

![图片](https://uploader.shimo.im/f/SVJPkgcBqZIgZQPA.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

首先我们创建一个pages文件夹，然后再里面创建一个home文件夹，文件夹里面再创建三个文件：Home.vue/home.css/home.js

这三个文件分别放置代码结构层html，css和逻辑层js

Home.vue

```plain
<template>
  <div>
    <h1>{{title}}</h1>
  </div>
</template>
<script src="./home.js"></script>
<style scoped src="./home.css"></style>
```
home.css

```css
h1 {
    color: #41B883;
}
```
home.js

```javascript
export default {
  name: 'Home',
  components: {
  },
  data () {
    return {
      title: 'Home page'
    }
  },
  mounted () {
  },
  methods: {
  }
}
```
然后我们把Home页面接入路由

router/index.js

```javascript
import Vue from 'vue'
import Router from 'vue-router'
Vue.use(Router)
export default new Router({
  routes: [
    {
      path: '/',
      name: 'Home',
      component: () => import('@/pages/home/Home.vue')
    }
  ]
})
```
>这里有一点需要注意的是，为什么我们不模仿原有的例子，在顶部通过 import Home from '@/pages/home/Home.vue' 直接引入home页面，然后放在路由的component里面。而是使用了如上写法呢
>这是因为webpack打包会自动将所有依赖的JS代码打入一个文件，如果工程特别大，依赖的内容特别多的话，就会导致该文件特别的大，而大文件加载会导致性能不是特别的好。这个时候我们希望将重量级路由内容单独生成一个或者多个js文件，而不是全部放在一个文件当中，然后路由访问时再去加载对应的代码块。
>所以我们会使用如上写法将不同的页面按需加载以实现上述目的。

我们刷新网页 localhost:8080（或者它其实已经自动刷新了）

![图片](https://uploader.shimo.im/f/mMvvpRXo1vdFHW7c.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

可以看到，除了原有全局的vue logo之前，页面内部就只剩下我们刚才添加的home page页面了


## 全局UI

我们修改一下app.vue，使得技术博客的全局UI更为没关

src/app.vue

```plain
<template>
  <div id="app">
    <div class="header">
      <div class="dark">
        <h1>Katherine的技术博客</h1>
      </div>
    </div>
    <div class="section">
      <div class="main">
        <router-view/>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'App'
}
</script>
<style>
* {
  margin: 0;
  padding: 0;
}
.header {
  height: 300px;
  background-image: linear-gradient(135deg,#79f1a4,#0e5cad);
  text-align: center;
  display: flex;
  align-items: flex-end;
}
.header .dark {
  margin: 0 auto;
  width: 800px;
  height: 150px;
  background-color: rgba(8,105,132,.52);
  border-top-left-radius: 4px;
  border-top-right-radius: 4px;
}
.header .dark h1 {
  line-height: 120px;
  display: block;
  font-size: 2.4em;
  -webkit-margin-before: 0.67em;
  -webkit-margin-after: 0.67em;
  -webkit-margin-start: 0px;
  -webkit-margin-end: 0px;
  font-weight: bold;
  color: #a9e4f5;
}
.section {
  background-color: #f7f8fa;
  padding-bottom: 60px;
}
.section .main {
  margin: 0 auto;
  width: 800px;
  background: #fff;
  box-shadow: 0 1px 2px 0 rgba(0,0,0,.05);
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 4px;
}
</style>
```
浏览器：

![图片](https://uploader.shimo.im/f/BAVjGv86VDRrO5os.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)


vue组件的创建与使用

首页我们打算现实文章列表，所以在初始化数据栏先列一条伪数据，方便创建UI组件的时候显示

@/pages/home/home.js

```javascript
export default {
  name: 'Home',
  components: {
  },
  data () {
    return {
      title: 'Home page',
      list: [
        {
          title: '文章标题一',
          created_at: '2020-04'
        },
        {
          title: '文章标题二',
          created_at: '2020-03'
        }
      ]
    }
  },
  mounted () {
  },
  methods: {
  }
}
```
然后在components里创建ArticleLine.vue组件

@/components/ArticleLine.vue

```plain
<template>
  <div class="article-line">
    <div class="number">{{number}}</div>
    <div class="title">{{title}}</div>
    <div class="date">{{date}}</div>
  </div>
</template>
<script>
export default {
  name: 'ArticleLine',
  props: ['number', 'title', 'date'],
  data () {
    return {
    }
  }
}
</script>
<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.article-line {
  padding: 30px 15px;
  border-bottom: 1px solid #f5f5f5;
  display: grid;
  grid-template-columns: 50px auto 100px;
  align-items: center;
}
.number {
  flex-basis: 80px;
  text-align: center;
  -ms-flex-negative: 0;
  flex-shrink: 0;
  font-weight: 700;
  color: rgba(11, 96, 119, 0.52);
  font-size: 17px;
}
.title {
  font-family: inherit;
  font-weight: 500;
  line-height: 1.2;
  color: #444;
  font-size: 16px;
}
.date {
  font-size: 13px;
  font-weight: 500;
  color: #87878a;
  line-height: 1.2;
}
</style>
```
在home中引用该组件

@/pages/home/home.js

```javascript
// 引入组件
import ArticleLine from '@/components/ArticleLine'
export default {
  name: 'Home',
  components: {
    // 放置在components当中
    ArticleLine
  },
  data () {
    return {
      list: [
        {
          title: '文章标题一',
          created_at: '2020-04'
        },
        {
          title: '文章标题二',
          created_at: '2020-03'
        }
      ]
    }
  },
  mounted () {
  },
  methods: {
  }
}
```
@/pages/home/Home.vue
```plain
<template>
  <div>
    <article-line  v-for="(item, index) in list" :key="item.id" :number="index + 1" :title="item.title" :date="item.created_at"></article-line>
  </div>
</template>
<script src="./home.js"></script>
<style scoped src="./home.css"></style>
```
>这里组件ArticleLine是驼峰写法，在Home.vue文件中使用的时候可以使用-写法
>v-for 是一个数组循环功能，使得组件根据数据数据一次展开
>:key 为for方法中标记组件唯一key
>:number :title :date 对应刚才我们为组件创建的属性
>与此同时，我们把刚才为了标记页面的title 字样 home page给删除了

![图片](https://uploader.shimo.im/f/Vx3Ks8zNXsy3TyOg.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

## 加载API数据

这里提供一个我原有的技术博客的api

```plain
https://api.github.com/repos/katherine0325/katherine0325.github.io/issues
```
![图片](https://uploader.shimo.im/f/tqhw6ZiT084AeaOx.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

那同样的，我们在src目录下创建一个api目录，然后创建get-article-list.js文件

@/pages/api/get-article-list.js

```javascript
// axios是一个方便用于进行http请求的npm包，项目中没有这个包，可以使用 npm install axios --save 安装
import Axios from 'axios'
export const getArticleList = async () => {
  const result = await Axios.get('https://api.github.com/repos/katherine0325/katherine0325.github.io/issues')
  return result.data
}
```
然后在api目录下创建index.js文件，将所有的api集中开放导出

@/api/index.js

```javascript
import { getArticleList } from './get-article-list'
export {
  getArticleList
}
```
@/pages/home/home.js

```javascript
import ArticleLine from '@/components/ArticleLine'
// 将 getArticleList 方法引入
import { getArticleList } from '@/api'
export default {
  name: 'Home',
  components: {
    ArticleLine
  },
  data () {
    return {
      // 将list原有的伪数据全部清空，留下一个空数组
      list: []
    }
  },
  // mounted是vue渲染完成后执行js的一个生命周期，所有的初始化获取数据，都可以在这里进行
  mounted () {
    // 使用init方法获取数据（这个方法将在methods中写具体）
    this.init()
  },
  methods: {
    // 初始化方法
    async init () {
      // 获取文章列表数据
      const list = await getArticleList()
      // 将数据赋值给data的list
      this.list = list
    }
  }
}
```
再次查看网页

![图片](https://uploader.shimo.im/f/ZpJbopyB6XWHN5Fm.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)




## 新增文章详情页

api

```plain
https://api.github.com/repos/katherine0325/katherine0325.github.io/issues/32
```
![图片](https://uploader.shimo.im/f/bVUmeLjCTSadGgsM.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

新增article页面

@/pages/article/Article.vue

```plain
<template>
  <div>
    <h2>{{title}}</h2>
    <!-- v-html是将html格式的字符串渲染到vue的方法 -->
    <div class="html" v-html="articleHtml"></div>
  </div>
</template>
<script src="./article.js"></script>
<style scoped src="./article.css"></style>
```
@/pages/article/article.css

```plain
h2 {
  text-align: center;
  line-height: 4;
}
.html {
  padding: 24px;
  padding-top: 0;
}
/* 这里的>>>是因为v-html中的标签无法简单的写它的css，只有加上>>>深度才能实现 */
.html >>> img {
  width: 100%;
}
```
@/pages/article/article.js

```javascript
// marked包用于将markdown格式的字符串转换为html格式，项目中原本没有这个包，可以使用 `npm install marked --save` 安装
import marked from 'marked'
// 获取文章详情api
import { getArticle } from '@/api'
export default {
  name: 'Article',
  data () {
    return {
      // 文章标题
      title: '',
      // 文章详情
      articleHtml: '<div></div>'
    }
  },
  mounted () {
    // 初始化
    this.init()
  },
  methods: {
    async init () {
      // 根据api我们可以知道，文章详情需要通过文章编号获取，文章编号需要从列表页点击文章标题，通过url传送过来。这里我们将这个query的key name定位 article_number，获取方式是 this.$router.query
      const result = await getArticle(this.$route.query.article_number)
      // 获取到文章详情后 result.body 是一串markdown格式的字符串，通过marked包将其转换文html格式，并赋值给data的articleHtml
      this.articleHtml = marked(result.body)
      // 将title赋值给title
      this.title = result.title
    }
  }
}
```
@/api/get-article.js

```javascript
import Axios from 'axios'
export const getArticle = async (articleNumber) => {
  const result = await Axios.get(`https://api.github.com/repos/katherine0325/katherine0325.github.io/issues/${articleNumber}`)
  return result.data
}
```
@/api/index.js

```javascript
import { getArticleList } from './get-article-list'
import { getArticle } from './get-article'
export {
  getArticleList,
  getArticle
}
```
添加到路由

@/router/index.js

```javascript
import Vue from 'vue'
import Router from 'vue-router'
Vue.use(Router)
export default new Router({
  routes: [
    {
      path: '/',
      name: 'Home',
      component: () => import('@/pages/home/Home.vue')
    },
    {
      path: '/article',
      name: 'Article',
      component: () => import('@/pages/article/Article.vue')
    }
  ]
})
```
修改home页面，使得从home页面跳转到artile页面，以及home页面相关变更的css

@/pages/home/Home.vue

```plain
<template>
  <div>
    <!-- router-link 是一个应用内跳转功能组件，:to后面使用json格式，path为页面地址，query为页面参数（这里包含之前我们说到的参数key name定为article_number） -->
    <!-- 然后也将 v-for 和 :key 搬到这一层来了，使得每个文章标题对应一个跳转 -->
    <router-link :to="{path: '/article', query: {article_number: item.number}}" v-for="(item, index) in list" :key="item.id">
      <!-- 由于api的事件参数的格式内容精确到了时分秒过长，我们只需要日期就够了，于是这里修改了一下取它前几位的日期即可(.slice(0, 10)) -->
      <article-line :number="index + 1" :title="item.title" :date="item.created_at.slice(0, 10)"></article-line>
    </router-link>
  </div>
</template>
<script src="./home.js"></script>
<style scoped src="./home.css"></style>
```
@/pages/home/home.css

```css
a {
  text-decoration: none;
  color: #444;
}
```
查看页面，点击文章标题进入文章详情页

![图片](https://uploader.shimo.im/f/LpBvnPmRnBRVzs8F.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)

![图片](https://uploader.shimo.im/f/Gx3J6jnPcd3wV2xS.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)



## 使用antd-vue创建loading全局方法

antd-vue是一个ui框架，它能够在项目内部直接使用库里的组件。具体使用方法详见：[https://www.antdv.com/docs/vue/introduce-cn/](https://www.antdv.com/docs/vue/introduce-cn/)

安装antd-vue

```plain
npm install ant-design-vue --save
```
在main.js中添加antd-vue的使用

@/main.js

```javascript
import Vue from 'vue'
import App from './App'
import router from './router'
// 引入antd
import Antd from 'ant-design-vue'
// 引入antd的css
import 'ant-design-vue/dist/antd.css'
Vue.config.productionTip = false
// 使用vue use antd
Vue.use(Antd)
/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  components: { App },
  template: '<App/>'
})
```
创建一个lib文件夹，目录下创建一个lading.js文件

```javascript
// 创建一个Loading class
export class Loading {
  // 静态方法show，用于在全局范围内，加载数据的过程中现实加载中字样
  // 通过antd-vue组件使用方法网站上可以知道，需要全局使用loading可以直接写 this.$message.loading('string', 0)，这里的show方法已经脱离页面js文件指引的this，所以需要使用event传入进来
  static show (event) {
    this.loading = event.$message.loading('加载中...', 0)
  }
  // 静态方法hide，用于将全局loading组件清除
  // 根据通过antd-vue网站，清除方式为 setTimeout(loading, 0)
  // 这里我们在show方法的时候，将loading赋值给了this.loading，那么我们在hide方法中就将它清除
  static hide () {
    setTimeout(this.loading, 0)
  }
}
```
在home init中使用

@/pages/home/home.js

```javascript
import ArticleLine from '@/components/ArticleLine'
import { getArticleList } from '@/api'
// 引入loading
import { Loading } from '@/lib/loading'
export default {
  name: 'Home',
  components: {
    ArticleLine
  },
  data () {
    return {
      list: []
    }
  },
  mounted () {
    this.init()
  },
  methods: {
    async init () {
      // Loading.show方法显示loading，传入参数this
      Loading.show(this)
      const list = await getArticleList()
      this.list = list
      // 数据请求完成后，Loading.hide方法清除loading
      Loading.hide()
    }
  }
}
```
同样的方式，在article init中使用

@/pages/article/article.js

```javascript
import marked from 'marked'
import { getArticle } from '@/api'
import { Loading } from '@/lib/loading'
export default {
  name: 'Article',
  data () {
    return {
      title: '',
      articleHtml: '<div></div>'
    }
  },
  mounted () {
    this.init()
  },
  methods: {
    async init () {
      Loading.show(this)
      const result = await getArticle(this.$route.query.article_number)
      this.articleHtml = marked(result.body)
      this.title = result.title
      Loading.hide()
    }
  }
}
```
查看效果

![图片](https://uploader.shimo.im/f/Se1ALB1r5Kf8cdab.png!thumbnail?fileGuid=9PDrdWJJJPckGGpg)


## END

全部完成



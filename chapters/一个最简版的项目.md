# 一个最简版的项目
-----

# 概述

REACT + WEBPACK + NODE + MONGO技术，实现前后端分离。使得在相关技术的学习过程中，可以利用其快速上手完成尝试，而不需要看到一个新的知识点，想要实现还要重新组织一次基础项目。


# 系统设计

### 系统整体设计与构思
![image](https://user-images.githubusercontent.com/23134442/34914867-657990de-f956-11e7-8a1a-449c88c5f89a.png)
文件结构：
![image](https://user-images.githubusercontent.com/23134442/34914909-1f5856a2-f957-11e7-83aa-a8327fee725d.png)


系统入口文件server，通过
```javascript
app.get('/', function(req, res) {
    res.sendFile(path.join(__dirname, 'index.html'));
})
```
将页面文件index.html发送到前端。

index.html引入js文件 www/js，该文件由前端入口文件main.js通过webpack打包，main.js内含前端路由，并可以在次引入布局文件layouts，路由引入页面routes，页面中可以引入可复用的组件components，前端页面由flux框架组合而成。flux框架分为结构、actions、store组成。

最基础结构文件
app/routes/aaa/Aaa.js
```javascript
import React, { Component } from 'react'

import AaaActions from './AaaActions'
import AaaStore from './AaaStore'

class Aaa extends Component {
    constructor(props) {
        super(props);
        this.state = AaaStore.getState();
        this.onChange = this.onChange.bind(this);
    }
    componentDidMount() {
        AaaStore.listen(this.onChange);
    }
    componentWillUnmount() {
        AaaStore.unlisten(this.onChange);
    }
    onChange(state) {
        this.setState(state);
    }
    render() {
        return (
            <div>
                <p>这是一个例子</p>
                {this.state.name}
            </div>
        )
    }
}

export default Aaa
```

最基础actions文件
为该页面新增action文件，发送ajax请求等可以在action里做:
app/routes/aaa/AaaActions.js
```javascript
import alt from '../../alt';

class AaaActions
{
    constructor() {
        this.generateActions(
        );
    }
}

export default alt.createActions(AaaActions);
```

最基础store文件
为该页面增加store文件，页面使用的参数都在store文件中初始化及集中管理
app/routes/aaa/AaaStore.js
```javascript
import alt from '../../alt'
import AaaActions from './AaaActions'

class AaaStore {
    constructor() {
      this.bindActions(AaaActions);
      this.name = 'katherine';
    }
}

export default alt.createStore(AaaStore);
```

前段发送的http请求，通过server.js的路由到controllers文件或api文件
```javascript
/**
 * 系统自有后端 sapi
 */
app.all('/sapi/:controller/:measure', function(req, res, next) {
    var file = require(`./server/controllers/${req.params.controller}`);
    file = new file();
    return file[req.params.measure](req, res, next);
});

/**
 * API接口
 */
app.post('/api/:filename/:measure', function(req, res, next) {
    if(fs.existsSync(`./server/API/${req.params.filename}.js`)) {
        var file = require(`./server/API/${req.params.filename}`);
        file = new file();
        return file['post' + _.capitalize(req.params.measure)](req, res, next);
    }

    return res.status(500).send('url is incorrect')
})
```

到达控制层后，控制层可以通过引用lib/common.js文件使用各种公用的方法，其中比较重要的是连接数据库，数据表的方法。
```javascript
// 连接数据库和表
this.modelLoader = function(connectionName, dbName) {
    if(!connectionName || connectionName == '') {
        return
    }

    let db = 'mainBase'
    if(dbName) {
        db = dbName;
    }
    mongoose.connect(`mongodb://localhost/${db}`);

    var schema = require(`../schemas/${connectionName}.js`);
    var model = mongoose.model(connectionName, schema);

    return model;
}
```

使用：
```javascript
var common = require('common');
var logM = common.helper.modelLoader('log');
logM.find({}, function(err, result) {
	// TODO……
})
```


 
### 模块设定与模块功能

一、conrollers
	本模块用于存放对应前端路由对应的控制层接口
	基础文件结构为：
```javascript
var common = require('../lib/common')

class Aaa {
    fetchMenu(req, res, next) {
		var logM = common.helper.modelLoader('log');
		logM.find({}, function(err, result) {
			return res.status(200).send('hello world');
		})
   	}

	nextFuction(req, res, next) {
		// TODO……
	}
}

module.exports = Aaa
```
如url地址为：/sapi/log/create，则请求会走到server/controllers/log.js下的create(req, res, next) {}方法。

二、lib
公共模块：common
    分为两部分，一部分将安装的npm包或封装的方法模块，通过common文件转出，使得任何一个文件只要引用common就能够时候所有的npm包或封装的方法模块，而不需要额外再require，特别是对于一些或封装的方法模块，能够在一个文件集中管理，使得后来者维护系统时可以使用已有的方法而不需要找不到或者重复封装。
	另一个是helper下的方法，一些常用的方法函数的封装，比如说modelLoader方法就是使用数据库是非常常用的一个方法。

三、schemas
	本模块用于定于数据表的数据结构
	例如：logs表
```javascript
var mongoose = require('mongoose')

var LogSchema = new mongoose.Schema({
    sUserName : String,
    sMethod : String,
    sIp : String,
    sUrl : String,
    sSystem: {type: String, enum: ["MSO", "CRM", "DS"]},
    sPart: String,
    sLevel: {type: String, enum: ["error", "warn", "info"]},
    sMark: String,
    sCreateTime : String,
    sSystemTime: String,
    oOption : Object
})

module.exports = LogSchema
```


五、configure
	本模块用于收集需要定义的配置，方便修改相关配置时方便查找及修改。


### 一、新增一个页面

app/routes/aaa/Aaa.js
```javascript
import React, { Component } from 'react'

import AaaActions from './AaaActions'
import AaaStore from './AaaStore'

class Aaa extends Component {
    constructor(props) {
        super(props);
        this.state = AaaStore.getState();
        this.onChange = this.onChange.bind(this);
    }
    componentDidMount() {
        AaaStore.listen(this.onChange);
    }
    componentWillUnmount() {
        AaaStore.unlisten(this.onChange);
    }
    onChange(state) {
        this.setState(state);
    }
    render() {
        return (
            <div>
                <p>这是一个例子</p>
                {this.state.name}
            </div>
        )
    }
}

export default Aaa
```

为该页面新增action文件，发送ajax请求等可以在action里做:
app/routes/aaa/AaaActions.js
```javascript
import alt from '../../alt';

class AaaActions
{
    constructor() {
        this.generateActions(
        );
    }
}

export default alt.createActions(AaaActions);
```

为该页面增加store文件，页面使用的参数都在store文件中初始化及集中管理
app/routes/aaa/AaaStore.js
```javascript
import alt from '../../alt'
import AaaActions from './AaaActions'

class AaaStore {
    constructor() {
      this.bindActions(AaaActions);
      this.name = 'katherine';
    }
}

export default alt.createStore(AaaStore);
```


当页面中需要使用到纯函数（不含ajax请求或者setTimeout等不定向函数）时，则：
app/routes/aaa/Aaa.js
```javascript
componentDidMount() {
        AaaStore.listen(this.onChange);

        AaaActions.changeName('lucy');
    }

app/routes/aaa/AaaActions.js
import alt from '../../alt';

class AaaActions
{
    constructor() {
        this.generateActions(
            'changeName'
        );
    }
}

export default alt.createActions(AaaActions);
```

app/routes/aaa/AaaStore.js（注意：只能传一个参数，如果要传一个以上的参数，请使用json)
```javascript
import alt from '../../alt'
import AaaActions from './AaaActions'

class AaaStore {
    constructor() {
      this.bindActions(AaaActions);
      this.name = 'katherine';
    }

    onChangeName(name) {
        this.name = name;
    }
}

export default alt.createStore(AaaStore);
```

当页面中使用到ajax之类的函数时
app/routes/aaa/Aaa.js
```javascript
    componentDidMount() {
        AaaStore.listen(this.onChange);

        AaaActions.changeName('lucy');

        AaaActions.sendAjax();
    }
```

app/routes/aaa/AaaActions.js（在action中发ajax请求，然后再将结果发送到store)
```javascript
import alt from '../../alt';

class AaaActions
{
    constructor() {
        this.generateActions(
            'changeName',
            'ajaxToStore'
        );
    }

    sendAjax() {
        $.ajax({
            method: 'GET',
            url: 'api/aaa/list'
        }).done(data => {
            this.actions.ajaxToStore(data)
        })
    }
}

export default alt.createActions(AaaActions);
```

app/routes/aaa/AaaStore.js（在再store中提供页面使用）
```javascript
import alt from '../../alt'
import AaaActions from './AaaActions'

class AaaStore {
    constructor() {
      this.bindActions(AaaActions);
      this.name = 'katherine';
      this.data = {};
    }

    onChangeName(name) {
        this.name = name;
    }

    onAjaxToStore(data) {
        this.data = data;
    }
}

export default alt.createStore(AaaStore);
```

刚才发送的那个ajax的url
url: '/api/aaa/list'

接收它的后端文件，url的第二项对应为controllers下的文件名，第三项对应为文件下的方法名。如果是直接对应请求的方法，方法名的参数应为(req, res, next)
server/controllers/aaa.js
```javascript
var common = require('../lib/common')
var co = require('co')

class Aaa {
    list(req, res, next) {
        return res.status(200).send(result)        
    }
}

module.exports = Aaa
```

方法中查询数据库时，可是使用封装好的查询数据库的方法
common.helper.modelLoader('crm_error', 'log')
第一个参数为数据库表名，第二个参数为数据库名。如果库名省略，则连接到默认（log）库
```javascript
var common = require('../lib/common')
var co = require('co')

class Aaa {
    list(req, res, next) {
        var aaaM = common.helper.modelLoader('crm_error', 'log');

        aaaM.find({}, function(err, result) {
            return res.status(200).send(result)
        })
    }
}

module.exports = Aaa
```
	
地址：
启动： npm start	


# ENDING


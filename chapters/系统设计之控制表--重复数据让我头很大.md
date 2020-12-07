# 系统设计之控制表----重复数据让我头很大
-----

写再前面的话：做系统的时候，我们常常会把一些批量的操作做成后台任务，这也就是说，

【1】如果我们在做一些批量且耗时较长的任务时（如上传录音，上传的过程中处理数据库数据），常常挡不住用户在点击完之后，忘记自己点击过或者不看进度条，或者刷新页面等方式强行再次执行这个任务。导致大量重复的数据。即便在单条数据上作状态标记也挡不住有些批量任务在你追我赶的过程中有部分数据发生毫秒级别的重复。
【2】另一种情况是，某次可能是修改字段等情况，需要后台跑脚本批量地修改数据库数据。然而，执行到一半的时候由于各种原因（代码不合理或代码不合理导致的内存爆掉）失败了。然而我的脚本有多个步骤，我不知道哪个步骤被执行了，哪个步骤中间卡了，非常想要知道阿……

## 这个时候，控制表就要闪亮登场了。

首先，正在执行的任务作标记，再次需要执行该任务的时候先查询任务状态，未执行完毕之前不允许再次执行。
其次，当某些后台任务执行到一半失败的时候，查看控制表就可以知道卡在哪个步骤，再次执行的时候自动跳过已执行过的步骤。

### 我这边以node为例，举一个控制表。
```
/**
 * 文件描述： 控制表
 * 
 * 控制表数据结构：
 * {
    process_name: String,  名称
    stat_date: String,  进程运行数据的日期
    partion_id: String,  分区名称
    status: Integer,  状态 0 成功运行 8 正在运行 9 准备运行
    first_time: Integer,  第一次运行时间（毫秒数 可通过 new Date(毫秒数) 将其转换为可读的时间）
    start_time: Integer,  开始时间（毫秒数 可通过 new Date(毫秒数) 将其转换为可读的时间）
    expire_time: Integer, 过期时间 例：'2017-11-12 00:00'
    run_seconds: Integer,  运行时间（毫秒）
    error_msg: String,  错误信息
    end_time: Integer,  结束时间（毫秒数 可通过 new Date(毫秒数) 将其转换为可读的时间）
    step_id Integer,  运行步骤
    query: Object  其他携带数据
 * }
 * 
 * 
 * 错误码：
 * 0: 成功
 * 2: 步骤已完成，请跳过
 * 8: 运行中
 * 451: 其他非异常错误
 */
```
```javascript
var common = require('./common');  //这里是封装好的操作数据库的函数，大家也可以自行应用成熟的包，例如mongoose或mongoskin

function ControlTable(connectionName) {
    this.M = common.helper.modelLoader(connectionName);
}
```
```
/**
 * 功能：初始化控制表
 * 描述：查询控制表数据，如果status: 8则表示正在运行中，其余则初始化更新数据(如果不存在则新建一条数据)
 * 入参：{process_name[必填]: String, partion_id: String, expire_time: String 例： '2017-11-21 13:20'}
 * 出参result：{code: 0, msg: "xxx", data: {status: 9}}
 * 出参err：{msg: "控制表报错", func: "start", query: data}
 * 数据操作： 当前表字段：process_name, stat_date, partion_id, status, first_time, start_time
 */
```
```javascript
ControlTable.prototype.start = function(data, callback) {
    var _this = this,
        nowTime = new Date()
        dateReg = /^[1-9]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])\s+(20|21|22|23|[0-1]\d):[0-5]\d:[0-5]\d$/;

    if(!data || !data.process_name) {
        return callabck({msg: "参数不正确", query: data});
    }

    if(data && data.expire_time && !dateReg.test(data.expire_time)) {
        return callback({msg: "参数不正确（日期格式不正确）", query: data})
    }

    common.co(function*() {
        var findData = yield _this.M.QfindOne({process_name: data.process_name}, {}, 'mscrm');
        if(findData && findData.status && findData.status == 8 && findData.expire_time && findData.expire_time > nowTime.getTime()) {
            return callback(null, {code: 8, msg: "程序正在运行中……", data: { status: findData.status }});
        } else {
            yield _this.M.Qupdate({process_name: data.process_name}, {
                process_name: data.process_name,
                stat_date: common.moment().format("YYYY-MM-DD"),
                partion_id: data.partion_id || '',
                status: 9,
                first_time: nowTime.getTime(),
                start_time: nowTime.getTime(),
                expire_time: data.expire_time? new Date(data.expire_time).getTime(): 16725225600000  //2500-01-01
            }, 'mscrm', false, true);

            return callback(null, {code: 0, msg: "开始运行", data: { status: 9 }});
        }
    }).catch(e => {
        return callback({msg: "控制表报错", func: "start", query: data});
    })
}
```
```
/**
 * 功能： 控制表步骤跟进
 * 描述： 更新数据里的步骤值step_id，如果表里的step_id的值比传入的大或相等，则返回2，建议跳过该步骤
 * 入参： {process_name[必填]: String, step_id[必填]: Number, query: String}
 * 出参result：{code: 0, msg: "xxx"}
 * 出参err：{msg: "xxx", func: 'xxx', query: {}}
 * 数据操作： 当前表字段：step_id, query
 */
```
```javascript
ControlTable.prototype.step = function(data, callback) {
    var _this = this;

    if(!data || !data.process_name || !data.step_id) {
        return callabck({msg: "参数不正确", query: data});
    }

    if(!/^[1-9]\d*$/.test(data.step_id)) {
        return callback({msg: "参数不正确(step_id不是正整数)", query: data})
    }

    common.co(function*() {
        var findData = yield _this.M.QfindOne({process_name: data.process_name}, {}, 'mscrm');

        if(findData && findData.status == 9 || findData.status == 8) {
            if(findData.step_id && findData.step_id >= data.step_id) {
                return callback(null, {code: 2, msg: "该步骤已完成，请跳过"})
            } else {
                yield _this.M.Qupdate({_id: findData._id}, {$set: {
                    status: 8,
                    step_id: data.step_id,
                    query: data.query || ''
                }}, 'mscrm');

                return callback(null, {code: 0, msg: `更新步骤${data.step_id}`});                
            }
        } else {
            return callback(null, {code: 451, msg: '控制表未初始化'});
        }
    }).catch(e => {
        return callback({msg: "控制表报错", func: 'step', query: data});
    })
}
```

```
/**
 * 功能：控制表成功结束
 * 描述：查找控制表，如果有则更新结束，没有则返回未初始化
 * 入参：{process_name[必填]: String, query: Object}
 * 出参result：{code: 0, msg: "xxx"}
 * 出参err：{msg: "xxx", func: 'xxx', query: {}}
 * 数据操作： 当前表字段：status, run_seconds, end_time, query
 */
```
```javascript
ControlTable.prototype.finish = function(data, callback) {
    var _this = this,
        nowTime = new Date();

    if(!data || !data.process_name) {
        return callabck({msg: "参数不正确", query: data});
    }

    common.co(function*() {
        var findData = yield _this.M.QfindOne({process_name: data.process_name}, {}, 'mscrm');

        if(findData && findData.status == 8) {
            yield _this.M.Qupdate({_id: findData._id}, {$set: {
                status: 0,
                run_seconds: nowTime.getTime() - findData.first_time,
                end_time: nowTime.getTime(),
                query: data.query || ''
            }}, 'mscrm');

            return callback(null, {code: 0, msg: '成功结束'});
        } else {
            return callback(null, {code: 451, msg: "控制表未在运行中，无法结束"});
        }

    }).catch(e => {
        return callback({msg: "控制表报错", func: 'finish', query: data});
    })
}
```

```
/**
 * 功能：业务程序报错记录入控制表
 * 描述：更新当前表状态及错误信息 error_msg 如果更新为0条，则没有初始化，1条则正常记录错误
 * 入参：{process_name[必填]: String, error_msg: String, query: Object}
 * 出参result：{code: 0, msg: "xxx"}
 * 出参err：{msg: "xxx", func: 'xxx', query: {}}
 * 数据操作：当前表字段：status, error_msg, end_time, query
 */
```
```javascript
ControlTable.prototype.error = function(data) {
    var _this = this,
        nowTime = new Date();

    if(!data || !data.process_name) {
        return callabck({msg: "参数不正确", query: data});
    }

    common.co(function*() {
        var findData = yield _this.M.QfindOne({process_name: data.process_name}, {}, 'mscrm');

        if(findData && findData.status == 8) {
            yield _this.M.Qupdate({_id: findData._id}, {$set: {
                status: -1,
                error_msg: data.error_msg || '',
                end_time: nowTime.getTime(),
                query: data.query || ''
            }}, 'mscrm');

            return callback(null, {code: 0, msg: '记录错误'});
        } else {
            return callback(null, {code: 451, msg: '控制表未在运行中，无法记录错误'});
        }
    })
}
```

// promise形式的start函数
```javascript
ControlTable.prototype.Qstart = function(data) {
    return new Promise((resolve, reject) => {
        _this.start(data, function(err, result) {
            if(err) {
                reject(err);
            } else {
                resolve(result);
            }
        });
    });
}
```

// promise形式的step函数
```javascript
ControlTable.prototype.Qstep = function(data) {
    return new Promise((resolve, reject) => {
        _this.step(data, function(err, result) {
            if(err) {
                reject(err);
            } else {
                resolve(result);
            }
        });
    });
}
```

// promise形式的finish函数
```javascript
ControlTable.prototype.Qfinish = function(data) {
    return new Promise((resolve, reject) => {
        _this.finish(data, function(err, result) {
            if(err) {
                reject(err);
            } else {
                resolve(result);
            }
        });
    });
}
```

// promise形式的error函数
```javascript
ControlTable.prototype.Qerror = function(data) {
    return new Promise((resolve, reject) => {
        _this.error(data, function(err, result) {
            if(err) {
                reject(err);
            } else {
                resolve(result);
            }
        });
    });
}

module.exports = function(connectionName){
    return new ControlTable(connectionName);
};
```

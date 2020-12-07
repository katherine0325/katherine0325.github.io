# 大量数据mongo跨库搬运，NODE v8 内存又爆了怎么办----支持传参及中途数据处理
-----

当我们使用 NODE + MONGO做网页应用的时候，需要对数据进行不同表的搬运，且根据前端发起的请求，想要对搬运的数据做一定的处理。

这个时候我们就犯难了，明明只是mongo到mongo的一个数据搬运，可是几十万的搬进node里面，处理过后再存进mongo，node v8 内存急剧上升，按秒爆给你看，好不容易用个子进程加控制并发，勉勉强强可以应付至少这个批量动作不干扰到主进程的应用。可是总觉得成了一个岌岌可危的功能，随时可能要担心数据。

### 经过不懈的努力，我终于找到办法了 T——T
`英文如此之差的我竟然看懂了好几篇网页`

首先，使用存储过程进行跨库的获取和存入数据，就是写一个js脚本命名为carry.js，如下

```javascript
// 跨库搬运得情况下，连接第一个库
var db = connect('mongodb://127.0.0.1:27017/firstdb');
// 连接第二个库
var nextdb = connect('mongodb://127.0.0.1:27017/seconddb');
// 将符合要求的数据找出，赋值给一个变量
var datas = db.first_collection.find({}).toArray();
// 将数据生成进入目标表
nextdb.second_collection.insert(datas);
// 完成后打印成功
print("success")
```
执行一下
```shell
mongo 127.0.0.1:27017/firstdb ./carry.js
```
很快我们可以得到执行的结果
![image](https://user-images.githubusercontent.com/23134442/35512770-e1bf0822-053b-11e8-818b-0f9d224b0ed4.png)


我们去查一下数据表，看看是否搬运成功
![image](https://user-images.githubusercontent.com/23134442/35513466-269375da-053e-11e8-8451-79a0b8f44f30.png)



然后说过支持传参的嘛，现在我假设这次搬运到B表的数据是A表中name为‘zhang’的数据，可是这个name的值又是一个变量，需要从外部传进去。
```javascript
var db = connect('mongodb://127.0.0.1:27017/firstdb');
var nextdb = connect('mongodb://127.0.0.1:27017/seconddb');
var datas = db.first_collection.find({name: carry_name}).toArray();
nextdb.second_collection.insert(datas);
print("success")
```
可是看到，我们的脚本已经添加了carry_name这个参数，这样传进入
```shell
mongo 127.0.0.1:27017/firstdb --eval "var carry_name='zhang'" ./carry.js
```
    
再次执行
![image](https://user-images.githubusercontent.com/23134442/35513491-3ab5d7f6-053e-11e8-9ad2-2b4f8074b3fb.png)


最后通过NODE执行这句话
```javascript
var exec = require('child_process').exec;

function funName() {
    exec('mongo 127.0.0.1:27017/firstdb --eval "var carry_name='zhang'" ./carry.js', function(err, result) {
        console.log("finish");
    }
}
```

    tips：如果是参数过多的情况下，可以成立一个任务表，在node里先在任务表里生成一条数据，数据里包括所需要的参数，然后通过命令的方式将任务数据的_id以参数的形式传进去，然后在再存储过程文件中找任务数据中的值为变量。

好了，一个随时搞崩溃系统的批量数据搬运，就让强大的MONGO数据库去做吧，NODE就好好发挥自己的强项高并发I/O就不去参与了。

    参考文献：
    01.  https://stackoverflow.com/questions/22503984/command-line-argument-to-a-javascript-file-that-works-on-mongodb

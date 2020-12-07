# 阿里云部署 nodejs+mongoDB 傻瓜教程
-----

写在前面的话：把项目部署到阿里云上之前，我也在网上搜过很多教程，所有的教程几乎都是大概有点儿基础的人才能看得懂的，相类似我这样的，在本机上写完代码就完全不知道怎么办的人，看到教程直接就开始上yum...之类的代码，甚至都不知道要写到哪里去，所以在完成我自己的这个项目之后，写一个像这样子的傻瓜教程，希望很多初学者可以按着步骤能够找到下一个按键或者打字的地方在哪里……

**目录**

一、阿里云申请/购买服务器

二、下载及安装putty和Xftp

三、为云服务器安装环境

01. 连接云服务器

02. 安装node.js

03. 安装mongoDB

四、上传代码

五、启动应用

六、大功告成





**一、阿里云申请/购买服务器**

01. 进入阿里云官方网站，找到云服务器ECS。[阿里云云服务器](https://s.click.taobao.com/t?e=m%3D2%26s%3D96wpDHxz7LAcQipKwQzePCperVdZeJviEViQ0P1Vf2kguMN8XjClAij7T60t9JDvaL1nZhCeLd8rm0I6CXbmEZKi66OxKtbzfsJ7wj2rzaZBIdkTG9%2BpWRmIkXBqRClNTcEU%2BDykfuSM%2BhtH71aX6uIOTs4KMj3yjpOyWSRdiSZDEm2YKA6YIrbIzrZDfgWtwGXLU4WXsy8CZuZoOOkzXFxfvOyje0ynomfkDJRs%2BhU%3D "")


02. 重点看这里，由于是个人小网站，就没有必要买那么贵的啦，这个1核1G的就可以了。每年330块钱，折合每个月不超过30块。操作系统我选的是centOS 6.5。点击立即购买。
![aliyun](https://pic1.zhimg.com/v2-3c932d294b86cc2ec8facca279930a18_b.jpg "")


03. 点击立即购买之后进入到确认订单页， 会有一个设置密码。这个密码设置好之后要记住，待会儿要用到。设好密码之后点击去下单。
![image](https://user-images.githubusercontent.com/23134442/30779529-dcf7c542-a125-11e7-9cda-c0baac9a748e.png)



04. 好了，去付钱吧。



05. 买好云服务器之后，你在阿里云的首页，登陆之后可以直接点击右上角的控制台

![image](https://user-images.githubusercontent.com/23134442/30779532-e80e77aa-a125-11e7-9bff-1c13b07cfb09.png)



06. 在左边点击云服务器ECS
![image](https://user-images.githubusercontent.com/23134442/30779535-ef4871d8-a125-11e7-90a7-f95630de66fe.png)




07. 找到你刚才购买地区，运行中字样的图标。我买的是云服务器，有一个在运行中，就是这个，点击
运行中1
![image](https://user-images.githubusercontent.com/23134442/30779538-f679210a-a125-11e7-8953-20e4c700beff.png)




8. 这时候你就可以看到你买到的云服务器了，注意我用红框框出来的位置，这个IP地址就是你的公网IP，后面要用到。

![image](https://user-images.githubusercontent.com/23134442/30779539-fd19526e-a125-11e7-888d-63a66e55741a.png)



**二、下载及安装putty和Xftp**

putty 是用于连接你手头上这台电脑以及你刚才购买的阿里云服务器，没有这个软件，你都不知道上哪儿敲部署教程里面的那些个字母（没错，我就是白痴到竟然在这个步骤走了许多弯路）

Xftp 用于部署好之后把你本地写好的程序上传到云服务器

tips：putty直接下载就可以用了，Xftp下载好之后安装，一直下一步也可以了。

三、为云服务器安装环境

01. 连接云服务器

A.
双击putty
![image](https://user-images.githubusercontent.com/23134442/30779542-15fbc316-a126-11e7-8356-8fe4119d6b59.png)




B.
出现的这个页面填写红框内信息，host name那里填写刚才申请的阿里云的公网IP，port一般是22，选择SSH，only on clean exit。点击open

![image](https://user-images.githubusercontent.com/23134442/30779543-19d9f05c-a126-11e7-81ac-809efc7802ec.png)



C.
然后进入这个状态，

![image](https://user-images.githubusercontent.com/23134442/30779545-1e2ff2b4-a126-11e7-86e7-401ae294de41.png)



输入root，回车。这是它会让你输入密码（tips），回车。出现

![image](https://user-images.githubusercontent.com/23134442/30779546-25948772-a126-11e7-9e04-fd33a4fb5e46.png)



的时候，表示连接远程服务器成功了。

tips：注意linux系统，输入密码的时候不会出现任何字符包括空格或者*号，放心吧不是电脑坏了。当初我做的时候从来没有用过linux系统，一度怀疑我自己是不是又哪里操作错了，导致没反应

02. 把yum更新到最新版本：

yum -y update

03. 我们将使用最新源代码构建Node.js，要进行软件的安装，需要一组用来编译源代码的开发工具：

yum -y groupinstall "Development Tools"
04. 安装node.js

A.
开始安装Node.js，先进入/usr/src文件夹，这个文件夹通常用来存放软件源代码:

cd /usr/src 
B.从 Node.js的站点 中获取压缩档源代码, 我选择的版本为v6.9.1：

wget http://nodejs.org/dist/v6.9.1/node-v6.9.1.tar.gz 
tips：以上安装nodejs的地址所包含的版本号，你需要跟根据不本地配置使用的nodejs版本来决定，先找到自己的版本号，然后把以上地址的‘6.9.1’替换成你使用的版本号

C.
解压缩源文件，并且进入到压缩后的文件夹中:

tar zxf node-v6.9.1.tar.gz
cd node-v6.9.1
D.
执行配置脚本来进行编译预处理:

./configure 
E.
开始编译源代码

make
F.
当编译完成后，我们需要使之在系统范围内可用, 编译后的二进制文件将被放置到系统路径，默认情况下，Node二进制文件应该放在/user/local/bin/node文件夹下

make install 
G.
现在已经安装了Node.js, 可以开始部署应用程序, 首先要使用Node.js的模块管理器npm安装Express middleware 和forever（一个用来确保应用程序启动并且在需要时重启的非常有用的模块）：

npm -g install express forever 
H.
建立超级链接, 不然 sudo node 时会报 "command not
found"

sudo ln -s /usr/local/bin/node /usr/bin/node 
sudo ln -s /usr/local/lib/node /usr/lib/node 
sudo ln -s /usr/local/bin/npm /usr/bin/npm 
sudo ln -s /usr/local/bin/node-waf /usr/bin/node-waf 
sudo ln -s /usr/local/bin/forever /usr/bin/forever
05. 安装mongoDB（数据库）

A.
进入文件夹/usr/local,下载mongodb源代码：

cd /usr/local
wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.2.11.tgz
tips:同样，以上mongoDB安装的地址所涉及的版本号，也请根据你本地安装的版本进行更改

B.
解压安装包，重命名文件夹为mongodb

tar zxvf mongodb-linux-x86_64-3.2.11.tgz
mv mongodb-linux-x86_64-2.4.9mongodb
C.
在var文件夹里建立mongodb文件夹，并分别建立文件夹data用于存放数据，logs用于存放日志

mkdir /var/mongodb
mkdir /var/mongodb/data
mkdir /var/mongodb/logs
D.
打开rc.local文件，添加CentOS开机启动项：

chmod +x /etc/rc.d/rc.local
E.
将mongodb启动命令追加到本文件中，让mongodb开机自启动：

/usr/local/mongodb/bin/mongod --dbpath=/var/mongodb/data --logpath /var/mongodb/logs/log.log -fork
F.
启动mongodb

/usr/local/mongodb/bin/mongod --dbpath=/var/mongodb/data --logpath /var/mongodb/logs/log.log -fork
G.
看到如下信息说明已经安装完成并成功启动:

forked process:18394
tips：数字不一定是要这个数字，是什么数字不重要，出现类似这样的就可以了

F.tips：给mongodb加密码
	这一步可以说非常重要也可以说不重要，如果你只是想要尝试一下使用服务器看看自己的应用。其实可以不用加密码就可以用了（可以直接跳过F.tips这个步骤）。
	但是如果你的mongo没有加密码，那么你很有可能被扫库程序删光你的数据（网上流传的一中病毒概念的东西，会一次性删光你的数据，再留下联系方式需要你付款索回【不知道对不对，如果有知道的朋友请提示我】），当初我刚开始弄好mongo的时候，就是没有加密码，老是被清光，然后我又一次一次的把数据加回去。（当时看了一下加密码教程，觉得好麻烦啊，我又不是真的要经营网站，只是想看看效果，就没有加密码）

	首先我们进入mongo，添加帐号密码
		mongo
	进入数据库 admin
		use admin
	添加账号密码
		db.createUser({user: "test", pwd: "123", roles: ["root"]})
	返回 Successfully added user: { "user" : "test", "roles" : [ "root" ] }说明用户创建成功了。
	退出（按ctrl + c）
	接下来我们要打开mongo配置文件为需要验证用户才能登陆
	先关闭mongo服务
		sudo service mongod stop	

	修改配置文件。
		sudo vim /etc/mongod.conf

	长这样
 
![image](https://user-images.githubusercontent.com/23134442/33930779-f7a5683a-e028-11e7-9baf-eea10c6bcead.png)


	我们加上
	security:
		authorization: enabled

	后长这样
![image](https://user-images.githubusercontent.com/23134442/33930782-fe116214-e028-11e7-9071-6043a440a69e.png)

 

	启动mongo服务
	sudo service mongod start

	再次进入mongo（这次只是尝试能不能成功登陆）
	use admin
	db.auth("test","123")

	返回1表示登陆成功了。（同样的，你的程序连接数据库的时候应该要写好相应的用户名密码，不然程序连不上库哦）
	继续tips:程序连接数据库，我的程序使用的是mongoose，那么我用mongoose来举例，如果你们用的是其他的npm包，那就自己去查查资料了哦。
	mongodb://<mongo用户名>:<mongo密码>@$<ip地址>:<port端口号>/<数据库名>?authSource=admin
	比如说刚才我设置的用户名是test，密码是123，ip地址是192.168.2.2（刚才买的阿里云服务器的外网ip），端口号是27017（没有重新设置的mongo端口号都是27017），想要连接的数据库名是mybase。那么我应该写成  
	mongodb://test:123@192.168.2.2:27017/mybase?authSource=admin

	tips: 据说曾经有人设密码的时候密码里有"@"字符，这你就要想想你为什么要作死了[doge]


**四、上传代码**

这个时候云服务器的环境其实已经装好了，可以暂时告别一下putty了

01. 双击打开Xftp

![image](https://user-images.githubusercontent.com/23134442/30779552-3c50555e-a126-11e7-91a9-f60cbe5c17b1.png)



02. 点击新建

![image](https://user-images.githubusercontent.com/23134442/30779553-4057fab2-a126-11e7-9124-ff3355b21de6.png)



03. 出现一下窗口，名称自己取一个项目名称。主机，填写阿里云服务器的公网IP，协议选择SFTP，端口使用22，用户名root，密码为购买阿里云的时候要你记住的密码。最后点击确定。

![image](https://user-images.githubusercontent.com/23134442/30779560-58163646-a126-11e7-9afa-2e20ef372bba.png)




04. 你将进入你所创建的阿里云内的root文件夹，双击


去到上一层，

![image](https://user-images.githubusercontent.com/23134442/30779559-516f47d8-a126-11e7-8311-83f04de050e8.png)



找到home文件夹，双击进入。

05. 左边框的文件夹就是你本机电脑中的文件夹，在当中找到你在本机建立的项目的所有文件，点击右键，传输。那么你就可以在下面的框中看到传输的过程。这时候耐心等待传输完毕。

**五、启动应用**

代码已经上传完了，这时候我们回到putty

01. 进入存放代码的目录，存放在/home/app目录下,server.js为程序入口文件

cd /home/app
sudo forever start server.js
tips：以上home文件夹下的app文件夹为你项目所在的文件夹，server.js为你程序的入口文件，可以根据你的实际情况改变为你实际所写的名称。

如果出现：info: forever processes running successfully，那么恭喜你，你的项目已经部署成功了。

tips：检视运行中的应用:

sudo forever list 
如果需要关闭应用，命令如下：

sudo forever stop 0
**六、大功告成**

这时打开你的浏览器，输入你所购买的阿里云的公网IP 加上 你入口程序server.js中所listen的端口号（比如我阿里云的公网ip为1.1.1.1，listen的端口号为8000，那么我输入的网址就是http://1.1.1.1:8000）打开看看是不是你的网站

happy endding





本教程参考资料（侵删）：

01. 把Node.js项目部署到阿里云服务器（CentOs） - 推酷

02. 开机/etc/rc.local 不执行的问题

03. http://jingyan.baidu.com/article/19192ad820877be53e5707e3.html



其他：

01. 本教程买阿里云服务器的地址系推广地址。
02. 或者你也可以通过下面的微信或支付宝二维码打赏我1块钱。
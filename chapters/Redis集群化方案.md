# Redis集群化方案
-----

### Redis使用中遇到的瓶颈
    我们日常在对于redis的使用中，经常会遇到一些问题
    1、高可用问题，如何保证redis的持续高可用性。
    2、容量问题，单实例redis内存无法无限扩充，达到32G后就进入了64位世界，性能下降。
    3、并发性能问题，redis号称单实例10万并发，但也是有尽头的。

### Redis集群化的优势　　
    1、高可用，高并发，高性能

### Redis集群化的挑战
    1、低概率的漏key风险，redis集群从节点的备份为异步备份（为保持高性能）
    2、涉及多个key的操作通常是不被支持的。
	举例来说，当两个set映射到不同的redis实例上时，你就不能对这两个set执行交集操作。
    3、涉及多个key的redis事务不能使用。
    4、不能保证集群内的数据均衡。
    分区的粒度是key，如果某个key的值是巨大的set、list，无法进行拆分。
    5、增加或删除容量也比较复杂。
	redis集群需要支持在运行时增加、删除节点的透明数据平衡的能力。

### Redis集群的几种实现方式
__1、客户端分片（不打算采用）__
特性:

* 优点
    * 简单，性能高。
* 缺点
    * 业务逻辑与数据存储逻辑耦合
    * 可运维性差
    * 多业务各自使用redis，集群资源难以管理
    * 不支持动态增删节点


__2、基于代理的分片__
客户端发送请求到一个代理，代理解析客户端的数据，将请求转发至正确的节点，然后将结果回复给客户端。

开源方案：`codis`

特性:

* 透明接入
    * 业务程序不用关心后端Redis实例，切换成本低。
* Proxy 的逻辑和存储的逻辑是隔离的。
* 代理层多了一次转发，性能有所损耗。

__3、路由查询__
将请求发送到任意节点，接收到请求的节点会将查询请求发送到正确的节点上执行。
开源方案
`Redis-cluster`

### Redis集群化方案
经过筛选，将codis和redis-cluster列入CRM项目redis集群化的待选方案，望领导商讨决议。
__`Codis` VS `Redis`__

对比参数 | Codis | Redis-cluster
-- | -- | --
Redis版本 | 基于2.8分支开发 | >= 3.0
部署 | 较复杂。 | 简单
运维 | Dashboard,运维方便。 | 运维人员手动通过命令操作。
监控 | 可在Dashboard里监控当前redis-server节点情况，较为便捷。 | 需配合其他监控应用实现（RedisLive、RedisClusterManager、等……（未调研，使用前应调研评估）
组织架构 | Proxy-Based, 类中心化架构，集群管理层与存储层解耦。 | P2P模型，gossip协议负责集群内部通信。去中心化
伸缩性 | 支持动态伸缩。 | 支持动态伸缩
主节点失效处理 | 自动选主。 | 自动选主。
数据迁移 | 简单。支持透明迁移。 | 需要运维人员手动操作。支持透明迁移。
升级 | 基于redis 2.8分支开发，后续升级不能保证；Redis-server必须是此版本的codis，无法使用新版本redis的增强特性。 | Redis官方推出，后续升级可保证。
可靠性 | 经过线上服务验证，可靠性较高。 | 新推出，坑会比较多。遇到bug之后需要等官网升级。

本对比基于2016.09，参考时请考虑其时效性

## 一、Redis-Cluster

1.1、redis cluster的现状
 　　目前redis支持的cluster特性：
　　1):节点自动发现
　　2):slave->master 选举,集群容错
　　3):Hot resharding:在线分片
　　4):进群管理:cluster xxx
　　5):基于配置(nodes-port.conf)的集群管理
　　6):ASK 转向/MOVED 转向机制.
1.2、redis cluster 架构
　　1)redis-cluster架构图

　　架构细节:
　　(1)所有的redis节点彼此互联(PING-PONG机制),内部使用二进制协议优化传输速度和带宽.
　　(2)节点的fail是通过集群中超过半数的节点检测失效时才生效.
　　(3)客户端与redis节点直连,不需要中间proxy层.客户端不需要连接集群所有节点,连接集群中任何一个可用节点即可
　　(4)redis-cluster把所有的物理节点映射到[0-16383]slot上,cluster 负责维护node<->slot<->value
 
   2) redis-cluster选举:容错

　　(1)领着选举过程是集群中所有master参与,如果半数以上master节点与master节点通信超过(cluster-node-timeout),认为当前master节点挂掉.
　　(2):什么时候整个集群不可用(cluster_state:fail),当集群不可用时,所有对集群的操作做都不可用，收到((error) CLUSTERDOWN The cluster is down)错误
    　　a:如果集群任意master挂掉,且当前master没有slave.集群进入fail状态,也可以理解成进群的slot映射[0-16383]不完成时进入fail状态.
    　　b:如果进群超过半数以上master挂掉，无论是否有slave集群进入fail状态.

## 二、redis cluster安装
1、准备服务器，并在每台服务器安装好redis。（具体使用多少台机器应升级请教）

  2、创建redis节点
     假设2台服务器，分别为：192.168.1.237，192.168.1.238.每分服务器有3个节点。
  我先在192.168.1.237创建3个节点：
```shell
  cd /usr/local/
  mkdir redis_cluster  //创建集群目录
  mkdir 7000 7001 7002  //分别代表三个节点    其对应端口 7000 7001 7002
 //创建7000节点，拷贝到7000目录
 cp /usr/local/redis-3.2.1/redis.conf  ./redis_cluster/7000/   
 //拷贝到7001目录
 cp /usr/local/redis-3.2.1/redis.conf  ./redis_cluster/7001/   
 //拷贝到7002目录
 cp /usr/local/redis-3.2.1/redis.conf  ./redis_cluster/7002/
```

   分别对7001，7002、7003文件夹中的3个文件修改对应的配置
```shell
daemonize    yes                          //redis后台运行
pidfile  /var/run/redis_7000.pid          //pidfile文件对应7000,7002,7003
port  7000                                //端口7000,7002,7003
cluster-enabled  yes                      //开启集群  把注释#去掉
cluster-config-file  nodes_7000.conf      //集群的配置  配置文件首次启动自动生成 7000,7001,7002
cluster-node-timeout  5000                //请求超时  设置5秒够了
appendonly  yes                           //aof日志开启 
```
有需要就开启，它会每次写操作都记录一条日志

在192.168.1.238创建3个节点：对应的端口改为7003,7004,7005.配置对应的改一下就可以了。
   3、两台机启动各节点(两台服务器方式一样)
```shell
cd /usr/local
redis-server  redis_cluster/7000/redis.conf
redis-server  redis_cluster/7001/redis.conf
redis-server  redis_cluster/7002/redis.conf
redis-server  redis_cluster/7003/redis.conf
redis-server  redis_cluster/7004/redis.conf
redis-server  redis_cluster/7005/redis.conf
```

4、查看服务
```shell
    ps -ef | grep redis   #查看是否启动成功
    netstat -tnlp | grep redis #可以看到redis监听端口
```

三、创建集群
  准备好了搭建集群的redis节点，接下来要把这些节点都串连起来搭建集群。官方提供了一个工具：redis-trib.rb(/usr/local/redis-3.2.1/src/redis-trib.rb)，它是用ruby写的一个程序，所以需安装ruby.
```shell
yum -y install ruby ruby-devel rubygems rpm-build
```
再用 gem 这个命令来安装 redis接口    gem是ruby的一个工具包.
```shell
gem install redis  
```
两台Server都要安装。
运行redis-trib.rb
```shell
 /usr/local/redis-3.2.1/src/redis-trib.rb
   Usage: redis-trib <command> <options> <arguments ...>
   reshard        host:port
                  --to <arg>
                  --yes
                  --slots <arg>
                  --from <arg>
  check          host:port
  call            host:port command arg arg .. arg
  set-timeout    host:port milliseconds
  add-node        new_host:new_port existing_host:existing_port
                  --master-id <arg>
                  --slave
  del-node        host:port node_id
  fix            host:port
  import          host:port
                  --from <arg>
  help            (show this help)
  create          host1:port1 ... hostN:portN
                  --replicas <arg>
For check, fix, reshard, del-node, set-timeout you can specify the host and port of any working node in the cluster.
```

使用参数create 创建 (在192.168.1.237中来创建)
```shell
 /usr/local/redis-3.2.1/src/redis-trib.rb  create  --replicas  1  192.168.1.237:7000 192.168.1.237:7001  192.168.1.237:7003 192.168.1.238:7003  192.168.1.238:7004  192.168.1.238:7005
```
 --replicas  1  表示 自动为每一个master节点分配一个slave节点    上面有6个节点，程序会按照一定规则生成 3个master（主）3个slave(从)
 防火墙一定要开放监听的端口，否则会创建失败。
 运行中，提示Can I set the above configuration? (type 'yes' to accept): yes 
 接下来 提示  Waiting for the cluster to join..........  ，Sending Cluster Meet Message to join the Cluster.
    需要到Server2上做这样的操作。
    在192.168.1.238, redis-cli -c -p 700*  分别进入redis各节点的客户端命令窗口， 依次输入 cluster meet 192.168.1.238 7000……
    回到Server1，已经创建完毕了。
    查看一下 /usr/local/redis/src/redis-trib.rb check 192.168.1.237:7000
    到这里集群已经初步搭建好了。
 
四、测试
1）get 和 set数据
  2）假设测试（down掉其中一台机器或某个节点）
 
五、CRM与REDIS-CLUSTER集群的接入
1、原crm系统通过node_redis包连接redis，采用redis-cluster集群后，redis-cluster采用去中心化方式，原连接代码无需更改。启动redis-cluster的ruby脚本不知道支不支持心跳（没有找到相关资料），不了解当应用连接的服务器挂掉之后是否可以继续保持高可用（应作实验决定是否在应用端做“连接失败连接下一个地址”的代码修改）
2、redis集群不支持涉及跨key的交集并集操作，需了解原系统涉及redis的操作是否有跨key的交并集操作，如有，应评估修改量的大小决定是否修改代码（升级请教）


## 二、Codis
Codis 是一个分布式 Redis 解决方式, 对于上层的应用来说, 连接到 Codis Proxy 和连接原生的 Redis Server 没有明显的差别 (不支持的命令列表), 上层应用能够像使用单机的 Redis 一样使用, Codis 底层会处理请求的转发, 不停机的数据迁移等工作, 全部后边的一切事情, 对于前面的client来说是透明的, 能够简单的觉得后边连接的是一个内存无限大的 Redis 服务.
基本框架例如以下：

Codis 由四部分组成:
Codis Proxy (codis-proxy)
Codis Manager (codis-config)
Codis Redis (codis-server)
ZooKeeper

codis-proxy 是client连接的 Redis 代理服务, codis-proxy 本身实现了 Redis 协议, 表现得和一个原生的 Redis 没什么差别 (就像 Twemproxy), 对于一个业务来说, 能够部署多个 codis-proxy, codis-proxy 本身是无状态的.

codis-config 是 Codis 的管理工具, 支持包含, 加入/删除 Redis 节点, 加入/删除 Proxy 节点, 发起数据迁移等操作. codis-config 本身还自带了一个 http server, 会启动一个 dashboard, 用户能够直接在浏览器上观察 Codis 集群的执行状态.

codis-server 是 Codis 项目维护的一个 Redis 分支, 基于 2.8.13 开发, 增加了 slot 的支持和原子的数据迁移指令. Codis 上层的 codis-proxy 和 codis-config 仅仅能和这个版本号的 Redis 交互才干正常执行.

ZooKeeper(下面简称ZK)是一个分布式协调服务框架。能够做到各节点之间的数据强一致性。简单的理解就是在一个节点改动某个变量的值后。在其它节点能够最新的变化。这样的变化是事务性的。

通过在ZK节点上注冊监听器，就能够获得数据的变化。

Codis 依赖 ZooKeeper 来存放数据路由表和 codis-proxy 节点的元信息, codis-config 发起的命令都会通过 ZooKeeper 同步到各个存活的 codis-proxy.

    注：1.codis新版本号支持redis到2.8.21
    2.codis-group实现redis的水平扩展

以下我们来部署环境：
```shell
10.80.80.124 zookeeper_1 codis-configcodis-server-master,slave codis_proxy_1
10.80.80.126 zookeeper_2 codis-server-master,slavecodis _proxy_2
10.80.80.123 zookeeper_3 codis-serve-master,slavecodis _proxy_3
```
说明：
1.为了确保zookeeper的稳定性与可靠性。我们在124、126、123上搭建zookeeper集群来对外提供服务；
2.codis-cofig作为分布式redis的管理工具。在整个分布式server中仅仅须要一个就能够完毕管理任务。
3.codis-server和codis-proxy在3台服务器提供redis和代理服务。
 
一.部署zookeeper集群
1.配置hosts（在3台server上）
10.80.80.124 codis1
10.80.80.126 codis2
10.80.80.123 codis3
2.配置java环境（在3台server上）
 
vim /etc/profile
```shell
// JAVA
export JAVA_HOME=/usr/local/jdk1.7.0_71
export JRE_HOME=/usr/local/jdk1.7.0_71/jre
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
```
```shell
source /etc/profile
```
3.安装zookeeper（在3台server上）
```shell
cd /usr/local/src
wget http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
tar -zxvf zookeeper-3.4.6.tar.gz -C /usr/local
```
4.配置环境变量（在3台server上）
 
 
vim /etc/profile
```shell
// zookeeper
ZOOKEEPER_HOME=/usr/local/zookeeper-3.4.6
export PATH=$PATH:$ZOOKEEPER_HOME/bin
```
```shell
source /etc/profile
```
5.改动zookeeper配置文件（在3台server上）
 
创建zookeeper的数据文件夹和日志文件夹
```shell
mkdir -p /data/zookeeper/zk1/{data,log}
cd /usr/local/zookeeper-3.4.6/conf
cp zoo_sample.cfg zoo.cfg
vim /etc/zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper/zk1/data
dataLogDir=/data/zookeeper/zk1/log
clientPort=2181
server.1=codis1:2888:3888
server.2=codis2:2888:3888
server.3=codis3:2888:3888
```
6.在dataDir下创建myid文件。相应节点id（在3台服务器上）
 
```shell
// 在124上 
cd /data/zookeeper/zk1/data
echo 1 > myid
// 在126上 
cd /data/zookeeper/zk1/data
echo 2 > myid
// 在123上 
cd /data/zookeeper/zk1/data
echo 3 > myid
```
7.启动zookeeper服务（在3台server上）
```shell
/usr/local/zookeeper-3.4.6/bin/zkServer.sh start
```
注：在你所在的当前文件夹下会生成一个zookeeper.out的日志文件，里面记录了启动过程中的具体信息；因为集群没有所有信息，会报“myid 2或myid 3 未启动”的信息，当集群所有启动后就会正常，我们能够忽略。
 
 
 
8.查看zookeeper全部节点的状态（在3台server上）
```shell
#124
/usr/local/zookeeper-3.4.6/bin/zkServer.sh status
JMX enabled by default
Using config: /usr/local/zookeeper-3.4.6/bin/../conf/zoo.cfg
Mode: leader
```
```shell
#126
/usr/local/zookeeper-3.4.6/bin/zkServer.sh status
JMX enabled by default
Using config: /usr/local/zookeeper-3.4.6/bin/../conf/zoo.cfg
Mode: follower
```
```shell
#123
/usr/local/zookeeper-3.4.6/bin/zkServer.sh status
JMX enabled by default
Using config: /usr/local/zookeeper-3.4.6/bin/../conf/zoo.cfg
Mode: follower
```
 
 
二.部署codis集群
1.安装go语言（在3台server上）
```shell
tar -zxvf go1.4.2.linux-amd64.tar.gz -C /usr/local/
```
2.加入go环境变量（在3台server上）
 
 
vim /etc/profile
```shell
#go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/usr/local/codis
```
```shell
source /etc/profile
```
3.安装codis（在3台server上）
```shell
go get github.com/wandoulabs/codis
cd $GOPATH/src/github.com/wandoulabs/codis
```
#运行编译測试脚本，编译go和reids。
```shell
./bootstrap.sh make gotest #将编译好后，把bin文件夹和一些脚本复制过去/usr/local/codis文件夹下 mkdir -p /usr/local/codis/{conf,redis_conf,scripts} cp -rf bin /usr/local/codis/ cp sample/config.ini /usr/local/codis/conf/ cp -rf sample/redis_conf /usr/local/codis cp -rf sample/* /usr/local/codis/scripts
4.配置codis-proxy（在3台server上。在此以124为例）
```
```shell
#124
cd /usr/local/codis/conf
vim config.ini
zk=codis1:2181,codis2:2181,codis3:2181
product=codis
#此处配置图形化界面的dashboard。注意codis集群仅仅要一个就可以，因此所有指向10.80.80.124:18087
dashboard_addr=192.168.3.124:18087
coordinator=zookeeper
backend_ping_period=5
session_max_timeout=1800
session_max_bufsize=131072
session_max_pipeline=128
proxy_id=codis_proxy_1
#126
cd /usr/local/codis/conf
vim config.ini
zk=codis1:2181,codis2:2181,codis3:2181
product=codis
#此处配置图形化界面的dashboard，注意codis集群仅仅要一个就可以，因此所有指向10.80.80.124:18087
dashboard_addr=192.168.3.124:18087
coordinator=zookeeper
backend_ping_period=5
session_max_timeout=1800
session_max_bufsize=131072
session_max_pipeline=128
proxy_id=codis_proxy_2
#123
cd /usr/local/codis/conf
vim config.ini
zk=codis1:2181,codis2:2181,codis3:2181
product=codis
#此处配置图形化界面的dashboard，注意codis集群仅仅要一个就可以，因此所有指向10.80.80.124:18087
dashboard_addr=192.168.3.124:18087
coordinator=zookeeper
backend_ping_period=5
session_max_timeout=1800
session_max_bufsize=131072
session_max_pipeline=128
proxy_id=codis_proxy_3
```
5.改动codis-server的配置文件（在3台服务器上）
 
```shell
#创建codis-server的数据文件夹和日志文件夹
mkdir -p /data/codis/codis-server/{data,logs}
cd /usr/local/codis/redis_conf
```
```shell
#主库
vim 6380.conf
daemonize yes
pidfile /var/run/redis_6380.pid
port 6379
logfile "/data/codis_server/logs/codis_6380.log"
save 900 1
save 300 10
save 60 10000
dbfilename 6380.rdb
dir /data/codis_server/data
```
```shell
#从库
cp 6380.conf 6381.conf
sed -i 's/6380/6381/g' 6381.conf
```
6.加入内核參数
 
```shell
echo "vm.overcommit_memory = 1" >>  /etc/sysctl.conf
sysctl -p
```
7.依照启动流程启动
```shell
cat /usr/loca/codis/scripts/usage.md
start zookeeper 
change config items in config.ini 
./start_dashboard.sh 
./start_redis.sh 
./add_group.sh 
./initslot.sh 
./start_proxy.sh 
./set_proxy_online.sh 
```

open browser to http://localhost:18087/admin
尽管scripts文件夹以下有对应启动脚本，也能够用startall.sh所有启动。但刚開始建议手动启动，以熟悉codis启动过程。
 
 
因为之前zookeeper已经启动，以下我们来启动其它项目。
注：1.在启动过程中须要指定相关日志文件夹或配置文件文件夹，为便于统一管理。我们都放在/data/codis下；
2.dashboard在codis集群中仅仅须要在一台server上启动就可以，此处在124上启动；凡是用codis_config的命令都是在124上操作，其它启动项须要在3台server上操作。
相关命令例如以下：
```shell
/usr/local/codis/bin/codis-config -h
usage: codis-config  [-c <config_file>] [-L <log_file>] [--log-level=<loglevel>]
		<command> [<args>...]
options:
   -c	set config file
   -L	set output log file, default is stdout
   --log-level=<loglevel>	set log level: info, warn, error, debug [default: info]

commands:
	server
	slot
	dashboard
	action
	proxy
```
 
(1)启动dashboard（在124上启动）
```shell
#dashboard的日志文件夹和訪问文件夹
mkdir -p /data/codis/codis_dashboard/logs
codis_home=/usr/local/codis
log_path=/data/codis/codis_dashboard/logs
nohup $codis_home/bin/codis-config -c $codis_home/conf/config.ini -L $log_path/dashboard.log dashboard --addr=:18087 --http-log=$log_path/requests.log &>/dev/null &
```
通过10.80.80.124:18087就可以訪问图形管理界面

(2)启动codis-server（在3台服务器上）
```shell
/usr/local/codis/bin/codis-server /data/codis_server/conf/6380.conf
/usr/local/codis/bin/codis-server /data/codis_server/conf/6381.conf
```
(3)加入 Redis Server Group（124上）
 
注意：每个 Server Group 作为一个 Redis server组存在, 仅仅同意有一个 master, 能够有多个 slave, group id 仅支持大于等于1的整数
眼下我们在3台server上分了3组，因此我们须要加入3组。每组由一主一从构成
```shell
#相关命令	
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server
usage:
	codis-config server list
	codis-config server add <group_id> <redis_addr> <role>
	codis-config server remove <group_id> <redis_addr>
	codis-config server promote <group_id> <redis_addr>
	codis-config server add-group <group_id>
	codis-config server remove-group <group_id>
#group 1
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server add 1 10.80.80.124:6380 master
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server add 1 10.80.80.124:6381 slave
#group 2
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server add 2 10.80.80.126:6380 master
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server add 2 10.80.80.126:6381 slave
#group 3
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server add 3 10.80.80.123:6380 master
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server add 3 10.80.80.123:6381 slave
```
 
注意：1.点击“Promote to Master”就会将slave的redis提升为master，而原来的master会自己主动下线。
 
2./usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini server add 能够加入机器到对应组中。也能够更新redis的主/从角色。
3.若为新机器，此处的keys应该为空
(4) 设置 server group 服务的 slot 范围（124上）
```shell
#相关命令
/usr/local/codis/bin/codis-config -c /usr/local/codis/conf/config.ini slot
usage:
	codis-config slot init [-f]
	codis-config slot info <slot_id>
	codis-config slot set <slot_id> <group_id> <status>
	codis-config slot range-set <slot_from> <slot_to> <group_id> <status>
	codis-config slot migrate <slot_from> <slot_to> <group_id> [--delay=<delay_time_in_ms>]
	codis-config slot rebalance [--delay=<delay_time_in_ms>]
	
#Codis 採用 Pre-sharding 的技术来实现数据的分片, 默认分成 1024 个 slots (0-1023), 对于每个key来说, 通过下面公式确定所属的 Slot Id : SlotId = crc32(key) % 1024 每个 slot 都会有一个特定的 server group id 来表示这个 slot 的数据由哪个 server group 来提供。
```
 
我们在此将1024个slot分为三段，分配例如以下：
```shell
/usr/local/codis/bin/codis-config -c conf/config.ini slot range-set 0 340 1 online /usr/local/codis/bin/codis-config -c conf/config.ini slot range-set 341 681 2 online /usr/local/codis/bin/codis-config -c conf/config.ini slot range-set 682 1023 3 online
```
(5)启动codis-proxy（在3台服务器上）
 
 
#codis_proxy的日志文件夹
```shell
mkdir -p /data/codis/codis_proxy/logs
codis_home=/usr/local/codis
log_path=/data/codis/codis_proxy/logs
nohup $codis_home/bin/codis-proxy --log-level warn -c $codis_home/conf/config.ini -L $log_path/codis_proxy_1.log  --cpu=8 --addr=0.0.0.0:19000 --http-addr=0.0.0.0:11000 > $log_path/nohup.out 2>&1 &
```
 
黑线处：codis读取server的主机名。
注意：若client相关訪问proxy，须要在client加入hosts
(6)上线codis-proxy
```shell
codis_home=/usr/local/codis
log_path=/data/codis/codis_proxy/logs
nohup $codis_home/bin/codis-proxy --log-level warn -c $codis_home/conf/config.ini -L $log_path/codis_proxy_1.log  --cpu=8 --addr=0.0.0.0:19000 --http-addr=0.0.0.0:11000 > $log_path/nohup.out 2>&1 &
```
注：启动codis_proxy后。proxy此时处于offline状态。无法对外提供服务，必须将其上线后才干对外提供服务。

CRM与codis的接入
    1、原crm系统通过node_redis包连接redis，采用redis-cluster集群后，原连接代码无需更改。
    2、redis集群不支持涉及跨key的交集并集操作，需了解原系统涉及redis的操作是否有跨key的交并集操作，如有，应评估修改量的大小决定是否修改代码（升级请教）



参考文献：
1、https://www.cnblogs.com/yuanermen/p/5717885.html  //redis-cluster安装部署
2、https://www.cnblogs.com/softidea/p/5365640.html  //codis安装部署

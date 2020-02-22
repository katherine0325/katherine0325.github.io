# 使用Spark进行流量日志分析
-----

### 部分分析日志指标如下：

PV: 网站页面访问数。
UV: 页面IP的访问量统计，即独立IP。
PVPU:平均每位用户访问页面数。
Time: 用户每小时PV的统计。
Source: 用户来源域名的统计。
Browser: 用户的访问设备统计。

### 截取有意义的字段，本次排序的部分内容如下
其中第一列为时间戳，
其中第二列为手机号，
其中第三列为上行流量，
其中第四列为下行流量。

【图片】

### 需求描述
以手机号为基准，先按上行流量排序，如果上行流量相同，再按下行流量排序，以此类推再按时间戳排序，并将排序的结果生成文件

### 核心编程思想描述:
对于元祖的N次排序，使用sortBy()方法

### 具体实现步骤:
第一步：获取文件内容
第二步：将文件通过split(" ")空个切割成数组
第三步：将数组拼接成每行元祖
第四步：对元祖中指定列进行排序
第五步：将元祖恢复成string
第六步：输出成为文件

### 代码：
```scala
import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._

object LogSort {
    def main(args: Array[String]) {
        val conf = new SparkConf().setAppName("Log Sort")
        val sc = new SparkContext(conf)

        // 获取文件
        val lines = sc.textFile("/home/katherine/project/test/sparkapp/input/access_20170504.log")

        // 先按上行流量，下行流量。再按时间戳排序
        val results = lines.map(_.split(" "))
                        .map(i => (i(0).toLong, i(1), i(2).toInt, i(3).toInt))
                        .sortBy(j => (j._3, j._4, j._1))
                        .map(i => i._1 + " " + i._2 + " " + i._3 + " " + i._4)

        // 排序后数据存文件
        results.saveAsTextFile("/home/katherine/project/test/sparkapp/output/LogSort")
    }
}
```

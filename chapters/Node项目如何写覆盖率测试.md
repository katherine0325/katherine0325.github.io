# Node项目如何写覆盖率测试
------

通常，我们的测试框架会使用mocha

package.json

```

"scripts": {

"test": "mocha -b -r ts-node/register --exit --colors -t 30000000 --recursive 'src/**/*.test.ts'"

}

```

借助mocha，我们可以用nyc来进行覆盖率测试


## 安装
```

npm install nyc --save-dev

```


添加scripts

package.json

```

"scripts": {

"test": "mocha -b -r ts-node/register --exit --colors -t 30000000 --recursive 'src/**/*.test.ts'",

"coverage": "nyc npm run test"

}

```


## 增加覆盖率测试的具体设置
在scripts下面增加一个nyc的key

package.json

```

"scripts": {

"test": "mocha -b -r ts-node/register --exit --colors -t 30000000 --recursive 'src/**/*.test.ts'",

"coverage": "nyc npm run test"

},

"nyc": {

    "check-coverage": true,

    "per-file": true,

    "lines": 90,  // 检查的行数应超过百分之九十才算通过

    "statements": 90,

    "functions": 90,

    "branches": 90,

    "include": [  // 检查包括哪些文件

      "src/**/*.ts"

    ],

    "exclude": [  // 不包括的文件

      "**/*.d.ts",

      "src/**/*test.ts",

      "src/test-helper",

      "src/config.ts",

      "src/models/*",

      "src/routes/*",

      "src/index.ts",

      "src/newrelic.ts",

      "src/jobs/target-delete-registry-job.ts"

    ],

    "extension": [

      ".ts"

    ],

    "require": [  // 需要依赖的模块

      "ts-node/register"

    ],

    "reporter": [  // 覆盖率测试结果图形化报表

      "text",

      "html"

    ],

    "sourceMap": true,

    "instrument": true,

    "all": true

}

```


## 执行
```

npm run coverage

```

执行完之后，会在控制台打印类似这样的内容

![图片](https://uploader.shimo.im/f/jZb7zeWp9rAxI3zp.png!thumbnail)

而且会在项目根目录生成 /coverage文件夹，双击里面的index.html文件可以打开网页版图形化的测试覆盖率结果。


## END

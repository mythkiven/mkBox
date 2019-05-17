## sdkdiff工具
sdkdiff是一个简单的工具，能比对两个SDK中.o文件的变化。
命令使用如下：
```shell
sdkdiff.py TestSDK_v1 TestSDK_v2
+1152         361088       TitleView.o
+824          180032       UserView.o
.....
-4232         260696       SpeakModel.o
-5640         243032       NavController.o
----------------------------------
-45288        80801624     Total
```

## TODO
### 脚本里使用size命令详细比对不同版本的SDK中代码段、数据段的大小增量

 - [MacApp](./macApp): 提高工作效率而写的Mac小工具
 - [Swift  开发](./swift)
 - [Script](./sdk) ：常用的脚本工具
 - [Runtime](./runtime) 
 - -  [Mach-O Runtime Architecture](./runtime/Mach-ORuntimeArchitecture.pdf)
 - -  [Dynamic Library Programming Topics](./runtime/DynamicLibraryProgrammingTopics.pdf)


### MacApp

#####  1. iOS Link Map 文件分析工具：MKLinkMap 实现已使用、未使用代码大小统计分析功能。

使用方法： 
1. 在 XCode 中开启编译选项 Write Link Map File : XCode -> Project -> Build Settings ->  Write Link Map File 设为 yes，并指定好 linkMap 的存储位置 

2. 工程编译完成后，在指定的位置找到 Link Map 文件（默认名称:$(PRODUCT_NAME)-LinkMap-$(CURRENT_VARIANT)-$(CURRENT_ARCH).txt）
默认的文件地址：~/Library/Developer/Xcode/DerivedData/xxxxxxxxxxxx/Build/Intermediates/XXX.build/Debug-iphoneos/XXX.build/

3. 然后在本应用，导入 Link Map 文件 

4. 分析 : 解析 Link Map 文件
![](./source/macapp_1558681586.png) 
5. 格式化输出 : 输出经过处理后易于阅读的  Link Map 文件(文件过大时，输出可能需要几分钟时间)
![](./source/macapp_1558681594.png) 
6. 输出文件：输出经统计后的 Link Map 文件  
7. 搜索功能：
![](./source/macapp_1558681602.png) 
8. 按库分析：
![](./source/macapp_1558681608.png) 
```

[下载地址](https://github.com/mythkiven/mkBox/releases/tag/V1.0.0)


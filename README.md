
![](./source/icon_mkbox.png)

- [MacApp](./macApp/README.md): 包含 MKAppTool 等分析工具
- [Swift  开发](./swift)
- [Script](./script) ：常用的脚本工具
- [Runtime](./runtime)
- -  [Mach-O Runtime Architecture](./runtime/Mach-ORuntimeArchitecture.pdf)
- -  [Dynamic Library Programming Topics](./runtime/DynamicLibraryProgrammingTopics.pdf)


*** Mac App
------
___


### 1. MKAppTool : .dSYM 文件、.xcarchive 文件和 Link Map 文件的分析工具


![](https://github.com/mythkiven/MKAppTool/blob/master/MKAppTool/MKLinkMap/Assets.xcassets/AppIcon.appiconset/icon512.png)

### [PKG 安装文件下载地址](https://github.com/mythkiven/mkBox/releases/tag/MKAppTool)
目前升级到 2.0 版本，在 1.0 版本 linkmap 文件分析的基础之上，支持 dSYM 和. xcarchive 文件的分析。

下一步，将优化大文件分析和增强分析功能。

### 1、dSYM 文件分析：实现根据错误地址进行代码定位等功能

打开本工具，会自动检索本地的 .xcarchive 文件。然后可进行详细的错误定位，从而找到 crash 点。

![](https://raw.githubusercontent.com/mythkiven/mkBox/master/source/dsym8945878483.png)

### 2、LinkMap 文件分析：实现统计代码使用情况及大小等功能。

1. 在 XCode 中开启编译选项 Write Link Map File : XCode -> Project -> Build Settings ->  Write Link Map File 设为 yes，并指定好 linkMap 的存储位置

2. 工程编译完成后，在指定的位置找到 Link Map 文件（默认名称:$(PRODUCT_NAME)-LinkMap-$(CURRENT_VARIANT)-$(CURRENT_ARCH).txt）
默认的文件地址：~/Library/Developer/Xcode/DerivedData/xxxxxxxxxxxx/Build/Intermediates/XXX.build/Debug-iphoneos/XXX.build/

![](https://raw.githubusercontent.com/mythkiven/mkBox/master/source/dsym8945878483.png)

支持按关键字搜索、按库分组统计。

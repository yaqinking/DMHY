# DMHY
一个订阅关键字后自动从相应站点下载新番的工具。

使用手册见 [Wiki](https://github.com/yaqinking/DMHY/wiki)

个人使用方法：把每天要看动画的关键字+字幕组+字幕类型设定好之后，每隔 60 分钟让她自动检测是否有新 ep。

软件运行系统需求：
- 系统最低支持 OS X 10.10
- 支持 Intel 和 Apple Silicon 处理器的 Mac

目前

支持以下站点搜索和自动下载种子或者使用 bt 客户端打开 magnet 链接

- https://share.dmhy.org
- https://acg.rip
- http://bt.acg.gg
- http://www.kisssub.org
- http://mikanani.me
- http://www.nyaa.si （提示：由于 nyaa 域名进行过更改，如果不是第一次使用本 app 需要重置数据库后才会更改为新域名。）

支持以下站点搜索

- https://bangumi.moe

其它 RSS 站点如果支持类似 `https://share.dmhy.org/topics/rss/rss.xml?keyword=%@` 这种格式的可以尝试一下添加自定义站点看是否能够正常使用。（`%@` 代表搜索关键字）

功能：

- 自动下载当天订阅的关键字更新
- 导入关键字（方便批量添加，导入时如果站点不存在会添加为自定义站点）
- 导出关键字（方便备份，分享给别人）
- 文件管理（方便双击直接打开观看）

附加说明：

- 使用 Sandbox
- 使用 Apple Notarization

## Screenshot
暗色主题

![Imgur](http://i.imgur.com/engeN87.jpg)

多站点自动下载开关设置

![Imgur](http://i.imgur.com/R6IAD2Z.jpg)

文件管理

![Imgur](http://i.imgur.com/XUgmRkl.jpg)

导出关键字

![Imgur](http://i.imgur.com/INkputg.jpg)

自动下载新种子（后台观测时，实际使用时只会在下载完成时通知。）

![v1.0](http://i.imgur.com/vI4WHLw.jpg)

## 开发环境

- macOS 11.1
- Xcode 12.3

## Contact
- [Twitter](https://twitter.com/yaqinking)
- [Telegram](https://telegram.me/yaqinking)

## Donate
- [Alipay](https://www.alipay.com) yaqinking@yahoo.co.jp
- [PayPal](https://www.paypal.com) yaqinking@yahoo.co.jp

## Thanks

- [AFNetworking](https://github.com/AFNetworking/AFNetworking)
- [Ono](https://github.com/mattt/Ono)
- [AFOnoResponseSerializer](https://github.com/AFNetworking/AFOnoResponseSerializer)
- [DateTools](https://github.com/MatthewYork/DateTools)
- [CocoaPods](https://cocoapods.org/)
- [stackoverflow](http://stackoverflow.com/)
- [raywenderlich](https://www.raywenderlich.com/)
- [Google search](https://www.google.com/)
- [NSHipster](http://nshipster.com/)
- [objc](https://www.objc.io/)

and others.

## License
Under MIT license, see LICENSE file.



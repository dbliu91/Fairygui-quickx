## 这是一个基于[Cocos2d-Lua 社区版](http://cocos2d-lua.org/)的fairygui解析库,基于Lua语言,就姑且叫做`Fairygui-quickx`吧.

首先要明确一点,fairygui的官网已经提供了`FairyGUI-cocos2dx`,我的这个在兼容性,完整性和性能上都不如官方的版本.

- FairyGui官网:http://www.fairygui.com/guide/
- FairyGUI-cocos2dx源码: https://github.com/fairygui/FairyGUI-cocos2dx
- 教程:在Cocos2dx中使用FairyGUI http://www.fairygui.com/guide/cocos2dx/index.html#运行Demo
- 热心网友的分享的 Lua Binding:FairyGUI在Cocos2d-x下的多平台接入和lua绑定 https://www.jianshu.com/p/547e584e05d8

## 为什么要写这个库?

### 1. 为了更深入的阅读代码.提高我对UI控件的底层认知.顺便加深对C++和Lua的理解.

在使用FairyGui的UI编辑器的过程中,在对UI的抽象和描述上,无数次提高了我对UI的认知.就比如,最惊艳我的:

双向滚动列表中的列表项的横向滚动的实现,是直接将列表项设置为`水平滚动`,再将滚动模式设置为了`页面模式`就好了.

就像官网写到的:借助FairyGUI提供的 `组件`、`关联`、`控制器` 以及 `动效`，我们可以在不写代码的情况下使用编辑器轻松地制作大量复杂的带有动画效果的自动布局的UI。

再有就是各种list,什么`虚拟列表`,`循环列表`,`列表的下拉刷新`,`背包中几行几列的表格`,`聊天列表`,`列表东西`,`双向列表`,`树形列表`,可以说做到了用最少的代码却让ui完全可控.

所以很想深入进去看看fairygui的解析库是如何做到的.

### 2. 现在工作中用到的项目是基于Cocos2d-Lua 社区版3.6.5的,底层是cocos2d-x 3.3版本的.想在不下整包的情况下用热更新的方式使用上fairygui.

虽然可以将项目中的游戏引擎升级来使用`FairyGUI-cocos2dx`,然后在做lua的代码绑定.但考虑到自己参与的项目的实际情况,很少更整包且渠道太多.

所以,又想用fairygui的UI编辑器,又不想改C++,只好用lua再写一套了...

## 如何跑Demo以及项目架构

- 项目目前对应的Fairygui编辑器版本是3.6.1 http://www.fairygui.com/product/release_notes.html
- 项目是基于Cocos2d-Lua 社区版3.6.5  http://cocos2d-lua.org/download/index.md 

- 第一步:参照 http://cocos2d-lua.org/#快速安装指南
    - 下载 Quick-Cocos2dx-Community 3.6.5版本
    - 解压后,如果是Windows系统：双击setup_win.bat即可。
    - Windows: 点击系统在桌面上的 player.exe 快捷方式。
- 第二步:
    - 下载`Fairygui-quickx`
    - 如下图所示导入项目

![](http://static.dbliu.com/fairygui_quickx/Snipaste_2018-07-29_19-24-55.png)
    
    
其核心的库代码在`src/app/fui`目录下,而对应的测试用例,在`src/app/scenes`目录下.![](http://static.dbliu.com/fairygui_quickx/Snipaste_2018-07-29_17-09-01.png),如果要将fairygui_quickx加入到自己的项目中,只需要将`src/app/fui`目录下的代码拷贝过去即可.



## 完成度和已知bug

1. 项目路径不能有中文,否则UIPackage读取资源的时候由于路径问题会报错(gbk和utf8的问题)
2. 富文本没有实现
3. 位图字体非常简陋,只支持锚点和单行
4. fnt字体除了描边,其他的特效都不支持(比如阴影,下划线,斜体,粗体)
5. 抄C++的ActionManager,用lua写了一个很简陋的ActionManager,没有进行很好的封装.
6. 九宫格的图片不支持变灰.
7. 帧动画非常简陋,也还有bug,列表的下拉刷新的时候,转圈圈的动画没有播.
8. 等待......

## 最后贴一个gif动图

![](http://static.dbliu.com/fairygui_quickx/20180729195227.gif)







### 第一步

参照 http://cocos2d-lua.org/#快速安装指南

使用Quick-Cocos2dx-Community_3.7.2创建一个新项目

### 拷贝相关代码和资源

将`src/app`目录下的`fui`和`scenes`目录拷贝过去,还有`res`下的目录页拷贝过去,

由于3.7.2的框架中没有ByteArray.lua文件(我是从3.6.5中拷贝了一份,放在`doc`目录下)到`src/framework/cc/utils/ByteArray.lua`处.

### 修改相关的代码

1. 修改设计分辨率和将屏幕方向设置为水平:

```lua
-- screen orientation
CONFIG_SCREEN_ORIENTATION = "landscape"

-- design resolution
CONFIG_SCREEN_WIDTH  = 1136
CONFIG_SCREEN_HEIGHT = 640
```

2. 修改MyApp.lua,启动对应的场景

```lua
function MyApp.lua,启动对应的场景:run()
    cc.FileUtils:getInstance():addSearchPath("res/")
    self:enterScene("MenuScene")
end
```

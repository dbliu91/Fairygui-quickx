local M = class("DemoScene", display.newScene)

function M:ctor()
    require("app.fui.init")
    UIConfig.registerFont(UIConfig.defaultFont, "fonts/DroidSansFallback.ttf")

    local GRoot = require("app.fui.GRoot")
    ---@type GRoot
    self._groot = GRoot:create()
    self._groot:init(self)

    UIPackage.addPackage("UI/MainMenu")

    self:continueInit()

    local closeButton = UIPackage.createObject("MainMenu", "CloseButton")

    closeButton:setPosition(
            self._groot:getWidth() - closeButton:getWidth() - 10,
            self._groot:getHeight() - closeButton:getHeight() - 10)
    closeButton:addRelation(self._groot, T.RelationType.Right_Right)
    closeButton:addRelation(self._groot, T.RelationType.Bottom_Bottom)
    closeButton:setSortingOrder(100000)
    closeButton:addClickListener(handler(self, self.onClose))

    self._groot:addChild(closeButton)
end

function M:onClose(context)
    if iskindof(self,"MenuScene")==false then
        local MenuScene = require("app.scenes.MenuScene")
        local scene = MenuScene.new()
        display.replaceScene(scene,"flipX")
    else
        cc.Director:getInstance():endToLua()
        if device.platform == "windows" or device.platform == "mac" then
            os.exit()
        end
    end
end

return M
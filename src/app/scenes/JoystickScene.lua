local DemoScene = require("app.scenes.DemoScene")
local JoystickModule = require("app.scenes.JoystickModule")

local M = class("JoystickScene", DemoScene)

function M:ctor(...)
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/Joystick");

    self._view = UIPackage.createObject("Joystick", "Main");
    self._groot:addChild(self._view);

    self._joystick = JoystickModule.new();
    self._joystick:init(self._view)

    local tf = self._view:getChild("n9");

    self._joystick:addEventListener(JoystickModule.MOVE,function (context)
        tf:setText(context:getDataValue())
    end)

    self._joystick:addEventListener(JoystickModule.END,function (context)
        tf:setText("请点击遥感")
    end)
end

return M
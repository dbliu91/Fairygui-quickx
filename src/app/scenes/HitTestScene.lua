local DemoScene = require("app.scenes.DemoScene")

local M = class("HitTestScene", DemoScene)

function M:continueInit()
    UIPackage.addPackage("UI/HitTest");

    self._view = UIPackage.createObject("HitTest", "Main");
    self._groot:addChild(self._view);
end

return M
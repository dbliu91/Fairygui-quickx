local Window = require("app.fui.GWindow")

local M = class("Window1", Window)

function M:onInit()
    self:setContentPane(UIPackage.createObject("Basics", "WindowA"));
    self:center();
end

function M:onShown()

    local list = self._contentPane:getChild("n6");
    list:removeChildrenToPool();

    for i = 1, 6 do
        local item = list:addItemFromPool();
        item:setTitle(tostring(i));
        item:setIcon("ui://Basics/r4");
    end
end

return M
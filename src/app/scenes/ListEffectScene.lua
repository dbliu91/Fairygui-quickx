local DemoScene = require("app.scenes.DemoScene")

local MailItem = require("app.scenes.MailItem")

local M = class("LoopListScene", DemoScene)

function M:ctor(...)
    self._list = nil
    self._view = nil
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/Extension");
    UIConfig.horizontalScrollBar = "";
    UIConfig.verticalScrollBar = "";
    UIObjectFactory.setPackageItemExtension("ui://Extension/mailItem", function()
        local item = MailItem.new()
        item:init()
        return item
    end)

    self._view = UIPackage.createObject("Extension", "Main");
    self._groot:addChild(self._view);

    self._list = self._view:getChild("mailList")

    for i = 1, 10 do
        local item = self._list:addItemFromPool();
        item:setFetched(i % 3 == 0);
        item:setRead(i % 2 == 0);
        item:setTime("5 Nov 2015 16:24:33");
        item:setTitle("Mail title here");
    end

    self._list:ensureBoundsCorrect();
    local delay = 1.0
    for i = 1, 10 do
        local item = self._list:getChildAt(i);
        if (self._list:isChildInView(item)) then
            item:playEffect(delay);
            delay = delay + 0.2;
        else
            break ;
        end
    end

end

return M
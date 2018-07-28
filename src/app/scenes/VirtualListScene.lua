local DemoScene = require("app.scenes.DemoScene")

local MailItem = require("app.scenes.MailItem")

local M = class("VirtualListScene", DemoScene)

function M:ctor(...)
    self._list = nil
    self._view = nil
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/VirtualList");
    UIConfig.horizontalScrollBar = "";
    UIConfig.verticalScrollBar = "";
    UIObjectFactory.setPackageItemExtension("ui://VirtualList/mailItem", function ()
        local item = MailItem.new()
        item:init()
        return item
    end)

    self._view = UIPackage.createObject("VirtualList", "Main");
    self._groot:addChild(self._view);

    self._view:getChild("n6"):addClickListener(function (context)
        self._list:addSelection(500, true)
    end)
    self._view:getChild("n7"):addClickListener(function (context)
        self._list:getScrollPane():scrollTop()
    end)
    self._view:getChild("n8"):addClickListener(function (context)
        self._list:getScrollPane():scrollBottom()
    end)

    self._list = self._view:getChild("mailList")
    self._list.itemRenderer = function(index,obj)
        self:renderListItem(index,obj)
    end
    self._list:setVirtual();
    self._list:setNumItems(1000);

end

function M:renderListItem(index,obj)
    local item = obj;
    item:setFetched(index % 3 == 0);
    item:setRead(index % 2 == 0);
    item:setTime("5 Nov 2015 16:24:33");
    item:setText(tostring(index) .. " Mail title here");
end

return M
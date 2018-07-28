local DemoScene = require("app.scenes.DemoScene")

local M = class("PullToRefreshScene", DemoScene)

local ScrollPaneHeader = require("app.scenes.ScrollPaneHeader")

function M:ctor(...)
    self._list1 = nil
    self._list2 = nil
    self._view = nil
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/PullToRefresh");
    UIObjectFactory.setPackageItemExtension("ui://PullToRefresh/Header", function()
        local item = ScrollPaneHeader.new()
        item:init()
        return item
    end)

    self._view = UIPackage.createObject("PullToRefresh", "Main");
    self._groot:addChild(self._view);

    self._list1 = self._view:getChild("list1");
    self._list1.itemRenderer = handler(self, self.renderListItem1)
    self._list1:setVirtual();
    self._list1:setNumItems(1);
    self._list1:addEventListener(T.UIEventType.PullDownRelease, handler(self, self.onPullDownToRefresh));

    self._list2 = self._view:getChild("list2");
    self._list2.itemRenderer = handler(self, self.renderListItem2)
    self._list2:setVirtual();
    self._list2:setNumItems(1);
    self._list2:addEventListener(T.UIEventType.PullUpRelease, handler(self, self.onPullUpToRefresh));

end

function M:renderListItem1(index, obj)
    local idx = self._list1:getNumItems() - index
    obj:setText("Item" .. idx)
end

function M:renderListItem2(index, obj)
    obj:setText("Item" .. index)
end

function M:onPullDownToRefresh(context)
    local header = self._list1:getScrollPane():getHeader()
    if (header:isReadyToRefresh()) then
        header:setRefreshStatus(3);
        self._list1:getScrollPane():lockHeader(header.sourceSize.height)

        --Simulate a async resquest
        local q = UIRoot:getCoroutine()
        q:PlayRoutine(function()
            q:WaitTime(2)

            self._list1:setNumItems(self._list1:getNumItems() + 5)

            --Refresh completed
            header:setRefreshStatus(4);
            self._list1:getScrollPane():lockHeader(35)

            q:WaitTime(2)

            header:setRefreshStatus(1);
            self._list1:getScrollPane():lockHeader(0)
        end)

    end
end

function M:onPullUpToRefresh(context)
    local footer = self._list2:getScrollPane():getFooter()
    footer:getController("c1"):setSelectedIndex(2);
    self._list2:getScrollPane():lockFooter(footer.sourceSize.height)
    --Simulate a async resquest
    local q = UIRoot:getCoroutine()
    q:PlayRoutine(function()
        q:WaitTime(2)

        self._list2:setNumItems(self._list2:getNumItems() + 5)

        --Refresh completed
        footer:getController("c1"):setSelectedIndex(1);
        self._list2:getScrollPane():lockHeader(0)
    end)
end

return M
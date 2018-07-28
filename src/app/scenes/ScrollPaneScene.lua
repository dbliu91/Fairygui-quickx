local DemoScene = require("app.scenes.DemoScene")

local M = class("TreeViewScene", DemoScene)

function M:ctor(...)
    self._list = nil
    self._view = nil
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/ScrollPane");
    UIConfig.horizontalScrollBar = "";
    UIConfig.verticalScrollBar = "";

    self._view = UIPackage.createObject("ScrollPane", "Main");
    self._groot:addChild(self._view);

    self._list = self._view:getChild("list");
    self._list.itemRenderer = function(index, obj)
        self:renderListItem(index, obj)
    end
    self._list:setVirtual();
    self._list:setNumItems(1000);
    self._list:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onClickList));

end

function M:renderListItem(index, obj)
    local item = obj;
    item:setTitle("Item " .. index);
    item:getScrollPane():setPosX(0); --reset scroll pos

    --Be carefull, RenderListItem is calling repeatedly, add tag to avoid adding duplicately.
    item:getChild("b0"):addClickListener(handler(self, self.onClickStick), self);
    item:getChild("b1"):addClickListener(handler(self, self.onClickDelete), self);

end

function M:onClickStick(context)
    local str = "Stick " .. context:getSender():getParent():getText()
    self._view:getChild("txt"):setText(str);
end

function M:onClickDelete(context)
    local str = "Delete " .. context:getSender():getParent():getText()
    self._view:getChild("txt"):setText(str);
end

function M:onClickList(context)
    --find out if there is an item in edit status
    --查找是否有项目处于编辑状态
    local cnt = self._list:numChildren();
    for i = 1, cnt do
        local item = self._list:getChildAt(i);
        if (item:getScrollPane():getPosX() ~= 0) then
            --Check if clicked on the button
            if (item:getChild("b0"):isAncestorOf(self._groot:getTouchTarget())
                    or item:getChild("b1"):isAncestorOf(self._groot:getTouchTarget())) then
                return
            end
            item:getScrollPane():setPosX(0, true);
            --avoid scroll pane default behavior。
            --取消滚动面板可能发生的拉动。
            item:getScrollPane():cancelDragging();
            self._list:getScrollPane():cancelDragging();
            break
        end
    end
end

return M
local M = class("PopupMenu")

function M:ctor()
    self._contentPane = nil
    self._list = nil
end

function M:doDestory()
    G_doDestory(self._contentPane)
end

function M:init(resourceURL)
    if not resourceURL then
        resourceURL = ""
    end

    if resourceURL == "" then
        resourceURL = UIConfig.popupMenu

        if resourceURL == "" then
            print("FairyGUI: UIConfig.popupMenu not defined")
        end
    end

    self._contentPane = UIPackage.createObjectFromURL(resourceURL);
    self._contentPane:addEventListener(T.UIEventType.Enter, handler(self, self.onEnter));

    self._list = self._contentPane:getChild("list");
    self._list:removeChildrenToPool();

    self._list:addRelation(self._contentPane, T.RelationType.Width);
    self._list:removeRelation(self._contentPane, T.RelationType.Height);
    self._contentPane:addRelation(self._list, T.RelationType.Height);

    self._list:addEventListener(T.UIEventType.ClickItem, handler(self, self.onClickItem))

end

function M:addItem(caption, callback)
    local item = self._list:addItemFromPool();
    item:setTitle(caption);
    item:setGrayed(false);
    local c = item:getController("checked");
    if (c) then
        c:setSelectedIndex(1);
    end
    item:removeEventListener(T.UIEventType.ClickMenu);
    if (callback) then
        item:addEventListener(T.UIEventType.ClickMenu, callback);
    end

    return item;
end

function M:addItemAt(caption, index, callback)
    local item = self._list:getFromPool(self._list:getDefaultItem());
    self._list:addChildAt(item, index);

    item:setTitle(caption);
    item:setGrayed(false);
    local c = item:getController("checked");
    if (c) then
        c:setSelectedIndex(1);
    end
    item:removeEventListener(T.UIEventType.ClickMenu);
    if (callback) then
        item:addEventListener(T.UIEventType.ClickMenu, callback);
    end

    return item;
end

function M:addSeperator()

    if UIConfig.popupMenu_seperator == nil or UIConfig.popupMenu_seperator == "" then
        print("FairyGUI: UIConfig.popupMenu_seperator not defined");
        return
    end

    self._list:addItemFromPool(UIConfig.popupMenu_seperator);
end

function M:getItemName(index)
    local item = self._list:getChildAt(index);
    return item.name;
end

function M:setItemText(name, caption)
    local item = self._list:getChild(name);
    item:setTitle(caption);
end

function M:setItemVisible(name, visible)
    local item = self._list:getChild(name);
    if (item:isVisible() ~= visible) then
        item:setVisible(visible);
        self._list:setBoundsChangedFlag();
    end
end

function M:setItemGrayed(name, grayed)
    local item = self._list:getChild(name);
    item:setGrayed(grayed);
end

function M:setItemCheckable(name, checkable)
    local item = self._list:getChild(name);
    local c = item:getController("checked");
    if (c) then
        if (checkable == true) then
            if (c:getSelectedIndex() == 1) then
                c:setSelectedIndex(2);
            else
                c:setSelectedIndex(1);
            end
        end
    end
end

function M:setItemChecked(name, check)
    local item = self._list:getChild(name);
    local c = item:getController("checked");
    if (c) then
        c:setSelectedIndex((check == true) and 3 or 2);
    end
end

function M:isItemChecked(name)
    local item = self._list:getChild(name);
    local c = item:getController("checked");
    if (c) then
        return c:getSelectedIndex() == 3
    else
        return false
    end
end

function M:removeItem(name)
    local item = self._list:getChild(name);
    if item then

        local index = self._list:getChildIndex(item);
        self._list:removeChildToPoolAt(index);
        item:removeEventListener(T.UIEventType.ClickMenu);

        return true
    else
        return false
    end
end

function M:clearItems()
    local cnt = self._list:numChildren();
    for i = 1, cnt do
        self._list:getChildAt(i):removeEventListener(T.UIEventType.ClickMenu);
    end
    self._list:removeChildrenToPool();
end

function M:getItemCount()
    return self._list:numChildren();
end

function M:getContentPane()
    return self._contentPane
end

function M:getList()
    return self._list
end

function M:show(target, dir)
    if not dir then
        dir = T.PopupDirection.AUTO
    end

    local r = target and target:getRoot() or UIRoot;
    if iskindof(target, "GRoot") == false then
        r:showPopup(self._contentPane, target, dir);
    else
        r:showPopup(self._contentPane, nil, dir);
    end
end

function M:onEnter(context)
    self._list:setSelectedIndex(-1);
    self._list:resizeToFit(nil, 10);
end

function M:onClickItem(context)
    local item = context:getData();
    if (item == nil) then
        return ;
    end

    if (item:isGrayed()) then
        self._list:setSelectedIndex(-1);
        return ;
    end

    local c = item:getController("checked");
    if (c and c:getSelectedIndex() ~= 1) then
        if (c:getSelectedIndex() == 2) then
            c:setSelectedIndex(3);
        else
            c:setSelectedIndex(2);
        end
    end

    local r = self._contentPane:getParent();
    r:hidePopup(self._contentPane);

    item:dispatchEvent(T.UIEventType.ClickMenu, context:getData());
end

return M
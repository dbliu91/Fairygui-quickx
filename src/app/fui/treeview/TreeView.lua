local UIEventDispatcher = require("app.fui.event.UIEventDispatcher")
local TreeNode = require("app.fui.treeview.TreeNode")

---@class TreeView:UIEventDispatcher
local M = class("TreeView", UIEventDispatcher)

function M:ctor()
    M.super.ctor(self)
    self._list = nil
    self._rootNode = nil
    self._indent = 30
end

function M:doDestory()
    M.super.doDestory(self)
    G_doDestory(self._list)
    G_doDestory(self._rootNode)
end

function M:init(list)
    self._list = list
    self._list:addEventListener(T.UIEventType.ClickItem, handler(self, self.onClickItem));
    self._list:addEventListener(T.UIEventType.RightClickItem, handler(self, self.onClickItem));
    self._list:removeChildrenToPool();

    self._rootNode = TreeNode.new(true);
    self._rootNode._isRootNode = true;
    self._rootNode:setRoot(self);
    self._rootNode:setExpaned(true);
end

function M:getList()
    return self._list
end

function M:getRootNode()
    return self._rootNode
end

function M:getSelectedNode()
    if (self._list:getSelectedIndex() ~= -1) then
        return self._list:getChildAt(self._list:getSelectedIndex()):getData();
    else
        return nil;
    end
end

function M:getSelection()
    local result = {}
    local ids = self._list:getSelection()
    for i, v in ipairs(ids) do
        local node = self._list:getChildAt(v):getData()
        table.insert(result, node)
    end
    return result
end

function M:addSelection(node, scrollItToView)
    if not scrollItToView then
        scrollItToView = false
    end

    local parentNode = node._parent
    while (parentNode ~= nil and parentNode ~= self._rootNode) do
        parentNode:setExpaned(true)
        parentNode = parentNode._parent
    end
    if node._cell ~= nil then
        self._list:addSelection(self._list:getChildIndex(node._cell), scrollItToView)
    end
end

function M:removeSelection(node)
    if node._cell ~= nil then
        self._list:removeSelection(self._list:getChildIndex(node._cell))
    end
end

function M:clearSelection()
    self._list:clearSelection()
end

function M:getNodeIndex(node)
    if node._cell == nil then
        return -1
    else
        return self._list:getChildIndex(node._cell)
    end
end

function M:updateNode(node)
    if node._cell == nil then
        return
    end

    if self.treeNodeRender ~= nil then
        self.treeNodeRender(node)
    end
end

function M:expandAll(folderNode)
    folderNode:setExpaned(true)
    for i, v in ipairs(folderNode._children) do
        if v:isFolder() then
            self:expandAll(v)
        end
    end
end

function M:expandAll(folderNode)
    if folderNode ~= self._rootNode then
        folderNode:setExpaned(false)
    end

    for i, v in ipairs(folderNode._children) do
        if v:isFolder() then
            self:collapseAll(v)
        end
    end
end

function M:createCell(node)
    local obj
    if self.treeNodeCreateCell then
        obj = self.treeNodeCreateCell(node)
    else
        obj = self._list:getItemPool():getObject(self._list:getDefaultItem())
    end

    assert(obj, "Unable to create tree cell")

    node:setCell(obj)

    local indentObj = node._cell:getChild("indent")
    if indentObj ~= nil then
        indentObj:setWidth((node._level - 1) * self._indent)
    end

    local expandButton = node._cell:getChild("expandButton")
    if expandButton ~= nil then
        if node:isFolder() == true then
            expandButton:setVisible(true);
            expandButton:addClickListener(handler(self, self.onClickExpandButton));
            expandButton:setData(node);
            expandButton:setSelected(node:isExpanded());
        else
            expandButton:setVisible(false)
        end
    end

    if self.treeNodeRender then
        self.treeNodeRender(node)
    end

end

function M:afterInserted(node)
    self:createCell(node);

    local index = self:getInsertIndexForNode(node);
    self._list:addChildAt(node._cell, index)

    if self.treeNodeRender then
        self.treeNodeRender(node)
    end

    if (node:isFolder() and node:isExpanded()) then
        self:checkChildren(node, index);
    end
end

function M:getInsertIndexForNode(node)
    local prevNode = node:getPrevSibling();
    if (prevNode == nil) then
        prevNode = node:getParent();
    end

    local insertIndex
    if prevNode._cell then
        insertIndex = self._list:getChildIndex(prevNode._cell) + 1;
    else
        insertIndex = 1
    end

    local myLevel = node._level;
    local cnt = self._list:numChildren();

    for i = insertIndex, cnt do
        local testNode = self._list:getChildAt(i):getData()
        if testNode._level < myLevel then
            break
        end

        insertIndex = insertIndex + 1
    end

    return insertIndex

end

function M:afterRemoved(node)
    self:removeNode(node)
end

function M:afterExpanded(node)
    if (node ~= self._rootNode and self.treeNodeWillExpand ~= nil) then
        self.treeNodeWillExpand(node, true);
    end

    if node ~= self._rootNode then
        if node._cell == nil then
            return
        end

        if (self.treeNodeRender ~= nil) then
            self.treeNodeRender(node);
        end

        local expandButton = node._cell:getChild("expandButton")
        if (expandButton ~= nil) then
            expandButton:setSelected(true);
        end

        if node._cell:getParent() ~= nil then
            self:checkChildren(node, self._list:getChildIndex(node._cell))
        end
    else
        self:checkChildren(node, -1)
    end
end

function M:afterCollapsed(node)
    if (node ~= self._rootNode and self.treeNodeWillExpand ~= nil) then
        self.treeNodeWillExpand(node, false);
    end

    if (node ~= self._rootNode) then
        if (node._cell == nil) then
            return ;
        end

        if self.treeNodeRender ~= nil then
            self.treeNodeRender(node)
        end

        local expandButton = node._cell:getChild("expandButton")
        if (expandButton ~= nil) then
            expandButton:setSelected(false);
        end

        if node._cell:getParent() ~= nil then
            self:hideFolderNode(node)
        end
    else
        self:hideFolderNode(node)
    end

end

function M:afterMoved(node)
    if (false == node:isFolder()) then
        self._list:removeChild(node._cell);
    else
        self:hideFolderNode(node);
    end

    local index = self:getInsertIndexForNode(node);
    self._list:addChildAt(node._cell, index)

    if node:isFolder() and node:isExpanded() then
        self:checkChildren(node, index)
    end
end

function M:checkChildren(folderNode, index)
    local cnt = folderNode:numChildren();
    for i = 1, cnt do
        index = index + 1
        local node = folderNode:getChildAt(i);
        if node._cell == nil then
            self:createCell(node)
        end

        if node._cell:getParent() == nil then
            self._list:addChildAt(node._cell, index)
        end

        if node:isFolder() and node:isExpanded() then
            index = self:checkChildren(node, index)
        end
    end

    return index
end

function M:hideFolderNode(folderNode)
    local cnt = folderNode:numChildren();
    for i = 1, cnt do
        local node = folderNode:getChildAt(i);
        if node._cell ~= nil then
            if node._cell:getParent() ~= nil then
                self._list:removeChild(node._cell)
            end

            node._cell:setData(nil)
            node._cell = nil
        end
        if node:isFolder() and node:isExpanded() then
            self:hideFolderNode(node)
        end
    end
end

function M:removeNode(node)
    if (node._cell ~= nil) then
        if node._cell:getParent() ~= nil then
            self._list:removeChild(node._cell)
        end

        self._list:getItemPool():returnObject(node._cell)
        node._cell:setData(nil)
        node._cell = nil

    end

    if node:isFolder() then
        local cnt = node:numChildren()
        for i = 1, cnt do
            local node2 = node:getChildAt(i)
            self:removeNode(node2)
        end
    end

end

function M:onClickExpandButton(context)
    context:stopPropagation()

    local expandButton = context:getSender()
    local node = expandButton:getParent():getData()

    if self._list:getScrollPane() ~= nil then
        local posY = self._list:getScrollPane():getPosY();
        if (expandButton:isSelected()) then
            node:setExpaned(true);
        else
            node:setExpaned(false);
        end
        self._list:getScrollPane():setPosY(posY);
        self._list:getScrollPane():scrollToView(node._cell);
    else
        if (expandButton:isSelected()) then
            node:setExpaned(true);
        else
            node:setExpaned(false);
        end
    end

end

function M:onClickItem(context)
    local posY = 0
    if self._list:getScrollPane() ~= nil then
        posY = self._list:getScrollPane():getPosY()
    end

    local item = context:getData()
    local node = item:getData()

    self:dispatchEvent(context:getType(), node)

    if self._list:getScrollPane() ~= nil then
        self._list:getScrollPane():setPosY(posY)
        self._list:getScrollPane():scrollToView(node._cell)
    end
end

return M
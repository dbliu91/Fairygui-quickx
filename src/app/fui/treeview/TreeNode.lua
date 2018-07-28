---@class TreeNode
local M = class("TreeNode")

function M:ctor(isFolder)
    self._root = nil
    self._parent = nil
    self._cell = nil
    self._level = 0

    self._expanded = false
    self._isRootNode = false

    self._data = nil
    self._children = {}

    self._isFolder = isFolder or false
end

function M:getParent()
    return self._parent
end

function M:getRoot()
    return self._root
end

function M:getCell()
    return self._cell
end

function M:getData()
    return self._data
end

function M:setData(value)
    self._data = value
end

function M:isExpanded()
    return self._expanded
end

function M:setExpaned(value)

    if self._isFolder == false then
        return
    end

    if self._expanded ~= value then
        self._expanded = value

        if self._root ~= nil then
            if self._expanded == true then
                self._root:afterExpanded(self)
            else
                self._root:afterCollapsed(self)
            end
        end
    end
end

function M:isFolder()
    return self._isFolder
end

function M:getText()
    if self._cell then
        return self._cell:getText()
    else
        return ""
    end
end

function M:addChild(child)
    self:addChildAt(child, #self._children + 1)
    return child
end

function M:addChildAt(child, index)
    assert(child, "Argument must be non-nil")

    if (child._parent == self) then
        self:setChildIndex(child, index);
    else
        if child._parent then
            child._parent:removeChild(child)
        end
        child._parent = self

        local cnt = #self._children
        if index > cnt then
            table.insert(self._children, child)
        else
            table.insert(self._children, index, child)
        end

        child._level = self._level + 1
        child:setRoot(self._root)

        if self._isRootNode == true or (self._cell ~= nil and self._cell:getParent() ~= nil and self._expanded == true) then
            self._root:afterInserted(child)
        end

    end

    return child
end

function M:removeChild(child)
    assert(child, "Argument must be non-nil")

    local childIndex = table.indexof(self._children, child)
    if childIndex ~= false then
        self:removeChildAt(childIndex)
    end
end

function M:removeChildAt(index)
    local child = self._children[index]
    child._parent = nil
    table.remove(self._children, index)

    if self._root ~= nil then
        child:setRoot(nil)
        self._root:afterRemoved(child)
    end
end

function M:removeChildren(beginIndex, endIndex)
    if not beginIndex then
        beginIndex = 1
    end
    if not endIndex then
        endIndex = -1
    end
    if endIndex < 1 or endIndex > #self._children then
        endIndex = #self._children
    end

    for i = beginIndex, endIndex do
        self:removeChildAt(beginIndex)
    end
end

function M:getChildAt(index)
    return self._children[index]
end

function M:getPrevSibling()
    if self._parent == nil then
        return nil
    end

    local idx = table.indexof(self._children, self)
    if idx ~= false and idx > 1 then
        return self._children[idx - 1]
    else
        return nil
    end
end

function M:getNextSibling()
    if self._parent == nil then
        return nil
    end

    local idx = table.indexof(self._children, self)
    if idx ~= false and idx < #self._children then
        return self._children[idx + 1]
    else
        return nil
    end
end

function M:getChildIndex(child)
    assert(child, "Argument must be non-nil")
    return table.indexof(self._children, child)
end

function M:setChildIndex(child, index)
    assert(child, "Argument must be non-nil")
    local oldIndex = table.indexof(self._children, child)
    assert(oldIndex ~= false, "Not a child of this container")
    self:moveChild(child, oldIndex, index)
end

function M:setChildIndexBefore(child, index)
    assert(child, "Argument must be non-nil")
    local oldIndex = self:getChildIndex(child)
    assert(oldIndex ~= false, "Not a child of this container")

    if oldIndex < index then
        return self:moveChild(child, oldIndex, index - 1)
    else
        return self:moveChild(child, oldIndex, index)
    end

end

function M:moveChild(child, oldIndex, index)
    local cnt = #self._children
    if index > cnt + 1 then
        index = cnt + 1
    end

    if oldIndex == index then
        return oldIndex
    end

    table.remove(self._children, oldIndex)

    if index > cnt then
        table.insert(self._children, child)
    else
        table.insert(self._children, index, child)
    end

    if self._cell ~= nil and self._cell:getParent() ~= nil and self._expanded == true then
        self._root:afterMoved(child)
    end

    return index

end

function M:swapChildren(child1, child2)
    assert(child1, "Argument1 must be non-nil")
    assert(child2, "Argument2 must be non-nil")

    local index1 = table.indexof(self._children, child1)
    local index2 = table.indexof(self._children, child2)

    assert(index1 ~= false, "Not a child of this container");
    assert(index2 ~= false, "Not a child of this container");

    self:swapChildrenAt(index1, index2)
end

function M:swapChildrenAt(index1, index2)
    local child1 = self._children[index1]
    local child2 = self._children[index2]

    self:setChildIndex(child1, index2)
    self:setChildIndex(child2, index1)
end

function M:numChildren()
    return #self._children
end

function M:setRoot(value)
    self._root = value

    if self._root ~= nil and self._root.treeNodeWillExpand ~= nil and self._expanded == true then
        self._root:treeNodeWillExpand(self, true)
    end

    if self._isFolder then
        for i, v in ipairs(self._children) do
            v._level = self._level + 1
            v:setRoot(value)
        end
    end

end

function M:setCell(value)
    if self._cell ~= value then
        if self._cell then
            --self._cell:doDestory()
        end
        self._cell = value
        if self._cell then
            self._cell:setData(self)
        end
    end
end

return M
local GObject = require("app.fui.GObject")

---@type Margin
local Margin = require("app.fui.Margin")

---@type FUIContainer
local FUIContainer = require("app.fui.node.FUIContainer")

---@type FUIInnerContainer
local FUIInnerContainer = require("app.fui.node.FUIInnerContainer")

---@type GController
local GController = require("app.fui.GController")

---@type ScrollPane
local ScrollPane = require("app.fui.ScrollPane")

---@type Transition
local Transition = require("app.fui.Transition")

local PixelHitTest = require("app.fui.event.PixelHitTest")

---@class GComponent:GObject
---@field public _buildingDisplayList boolean
---@field protected _opaque boolean
---@field protected _margin Margin
---@field protected _container FUIInnerContainer
---@field protected _children cocos2d::Vector<GObject*>
---@field protected _scrollPane
---@field protected _childrenRenderOrder
---@field protected _apexIndex
---@field protected _boundsChanged
---@field protected _trackBounds
---@field protected _sortingChildCount
---@field protected _applyingController GController
---@field protected _buildingDisplayList
---@field protected _maskOwner
---@field protected _hitArea
local M = class("GComponent", GObject)

function M:ctor()
    M.super.ctor(self)

    self._container = nil
    self._scrollPane = nil
    self._childrenRenderOrder = T.ChildrenRenderOrder.ASCENT
    self._apexIndex = 0
    self._boundsChanged = false
    self._trackBounds = false
    self._opaque = false
    self._sortingChildCount = 0
    self._applyingController = nil
    self._buildingDisplayList = false
    self._maskOwner = nil
    self._hitArea = nil

    self._margin = Margin.new()
    self._children = {}
    self._controllers = {}
    self._transitions = {}

    self._alignOffset = cc.p(0, 0)
end

function M:doDestory()
    M.super.doDestory(self)

    for i, v in ipairs(self._children) do
        v._parent = nil
        v:doDestory()
    end

    self._children = {}
    self._controllers = {}
    self._transitions = {}

    if self._maskOwner then
        self._maskOwner:doDestory()
        self._maskOwner = nil
    end

    if self._container then
        --self._container:release()
        self._container = nil
    end

    if self._scrollPane then
        self._scrollPane:doDestory()
        self._scrollPane = nil
    end

    CALL_LATER_CANCEL(self, self.doUpdateBounds)
    CALL_LATER_CANCEL(self, self.buildNativeDisplayList)
end

function M:handleInit()
    local NodeClass = cc.Node
    if self._packageItem then
        local xml = self._packageItem.componentData:children()[1]
        local overflow = xml["@overflow"] or T.OverflowType.VISIBLE
        if overflow ~= T.OverflowType.VISIBLE then
            NodeClass = cc.ClippingRectangleNode
        end

        local p = xml["@mask"]
        if p then
            NodeClass = cc.ClippingNode
            --NodeClass = cc.Node
        end

    end
    self._displayObject = FUIContainer.new(NodeClass)

    if NodeClass == cc.ClippingRectangleNode then
        self._displayObject:setClippingEnabled(true)
    end

    self._displayObject:retain()
    UIPackage.markForRelease(self._displayObject,self.__cname)

    self._container = FUIInnerContainer.new()
    --self._container:retain()
    --UIPackage.markForRelease(self._container)
    self._container:setCascadeOpacityEnabled(true)
    self._displayObject:addChild(self._container)
end

function M:addChild(child)
    self:addChildAt(child, #self._children + 1)
    return child
end

---@param child GObject
function M:addChildAt(child, index)
    if child._parent == self then
        self:setChildIndex(child, index)
    else
        --child->retain();
        child:removeFromParent()
        child._parent = self

        local cnt = #self._children
        if child._sortingOrder ~= 0 then
            self._sortingChildCount = self._sortingChildCount + 1
            index = self:getInsertPosForSortingChild(child) + 1
        elseif self._sortingChildCount > 0 then
            if (index > (cnt - self._sortingChildCount + 1)) then
                index = cnt - self._sortingChildCount + 1
            end
        end

        if (index > cnt) then
            table.insert(self._children, child)
        else
            table.insert(self._children, index, child)
        end

        --child->release();

        self:childStateChanged(child)
        self:setBoundsChangedFlag()
        if child._group then
            child._group:setBoundsChangedFlag(true)
        end
    end
    return child
end

---@param target GObject
function M:getInsertPosForSortingChild(target)
    local idx = 0
    for i, child in ipairs(self._children) do
        while true do
            if child == target then
                break
            end
            break
        end

        idx = i

        if target._sortingOrder < child._sortingOrder then
            break
        end
    end

    return idx
end

---@param child GObject
function M:removeChild(child)
    local idx = table.indexof(self._children, child)
    if idx ~= false then
        self:removeChildAt(idx)
    end
end

function M:removeChildAt(idx)
    ---@type GObject
    local child = self._children[idx]

    child._parent = nil

    if child._sortingOrder ~= 0 then
        self._sortingChildCount = self._sortingChildCount - 1
    end

    child:setGroup(nil)

    if child._displayObject:getParent() then
        self._container:removeChild(child._displayObject, false)

        if self._childrenRenderOrder == T.ChildrenRenderOrder.ARCH then
            CALL_LATER(self, self.buildNativeDisplayList)
        end
    end

    table.remove(self._children, idx)

    self:setBoundsChangedFlag()

end

function M:removeChildren(beginIndex, endIndex)
    if not beginIndex and not endIndex then
        beginIndex = 1
        endIndex = -1
    end
    if endIndex < 0 or endIndex > #self._children then
        endIndex = #self._children
    end

    for i = beginIndex, endIndex do
        self:removeChildAt(beginIndex)
    end
end

function M:getChildAt(index)
    return self._children[index]
end

function M:getChild(name)
    for i, c in ipairs(self._children) do
        if c.name == name then
            return c
        end
    end
end

---@param group GGroup
function M:getChildInGroup(group, name)
    for i, child in ipairs(self._children) do
        if child._group == group and child.name == name then
            return child
        end
    end
end

---@param id string
function M:getChildById(id)
    for i, child in ipairs(self._children) do
        if child.id == id then
            return child
        end
    end
end

---@param child GObject
function M:getChildIndex(child)
    return table.indexof(self._children, child)
end

function M:setChildIndex(child, index)
    -- CCASSERT(child != nullptr, "Argument must be non-nil");
    local oldIndex = self:getChildIndex(child)
    -- CCASSERT(oldIndex != -1, "Not a child of this container");
    if child._sortingChildCount ~= 0 then
        return
    end

    local cnt = #self._children
    if self._sortingChildCount > 0 then
        if index > cnt - self._sortingChildCount then
            index = cnt - self._sortingChildCount
        end
    end

    self:moveChild(child, oldIndex, index)
end

function M:setChildIndexBefore(child, index)
    -- CCASSERT(child != nullptr, "Argument must be non-nil");
    local oldIndex = self:getChildIndex(child)
    -- CCASSERT(oldIndex != -1, "Not a child of this container");

    if (child._sortingOrder ~= 0) then
        --no effect
        return oldIndex;
    end

    local cnt = #self._children
    if self._sortingChildCount > 0 then
        if index > (cnt - self._sortingChildCount) then
            index = cnt - self._sortingChildCount;
        end
    end

    if oldIndex < index then
        self:moveChild(child, oldIndex, index - 1)
    else
        self:moveChild(child, oldIndex, index)
    end

end

function M:moveChild(child, oldIndex, index)
    local cnt = #self._children
    --if index > cnt then
    --    index = cnt
    --end

    if oldIndex == index then
        return oldIndex
    end

    table.remove(self._children, oldIndex)

    if index >= cnt then
        table.insert(self._children, child)
    else
        table.insert(self._children, index, child)
    end

    if child._displayObject:getParent() then
        if self._childrenRenderOrder == T.ChildrenRenderOrder.ASCENT then
            local fromIndex = math.min(index, oldIndex)
            local toIndex = math.min(math.max(index, oldIndex), cnt)
            for i = fromIndex, toIndex do
                local g = self._children[i]
                if g._displayObject:getParent() then
                    g._displayObject:setLocalZOrder(i - 1)
                end
            end
        elseif self._childrenRenderOrder == T.ChildrenRenderOrder.DESCENT then
            local fromIndex = math.min(index, oldIndex)
            local toIndex = math.min(math.max(index, oldIndex), cnt)
            for i = fromIndex, toIndex do
                local g = self._children[i]
                if g._displayObject:getParent() then
                    g._displayObject:setLocalZOrder(cnt - (i - 1) - 1)
                end
            end
        else
            CALL_LATER(self, self.buildNativeDisplayList)
        end

        self:setBoundsChangedFlag()

    end

    return index

end

--[[

void GComponent::swapChildren(GObject* child1, GObject* child2)
{
    CCASSERT(child1 != nullptr, "Argument1 must be non-nil");
    CCASSERT(child2 != nullptr, "Argument2 must be non-nil");

    int index1 = (int)_children.getIndex(child1);
    int index2 = (int)_children.getIndex(child2);

    CCASSERT(index1 != -1, "Not a child of this container");
    CCASSERT(index2 != -1, "Not a child of this container");

    swapChildrenAt(index1, index2);
}

void GComponent::swapChildrenAt(int index1, int index2)
{
    GObject* child1 = _children.at(index1);
    GObject* child2 = _children.at(index2);

    setChildIndex(child1, index2);
    setChildIndex(child2, index1);
}

--]]

function M:numChildren()
    return #self._children
end

function M:isAncestorOf(obj)
    if obj == nil then
        return false
    end

    local p = obj._parent
    while p ~= nil do
        if p == self then
            return true
        end

        p = p._parent
    end

    return false
end

function M:addAdoptiveChild(child)
    child._parent = self
    child._isAdoptiveChild = true
    self._displayObject:addChild(child._displayObject)
end

function M:isChildInView(child)
    if (self._scrollPane) then
        return self._scrollPane:isChildInView(child);
    elseif (self._displayObject:isClippingEnabled()) then
        return child._position.x + child._size.width >= 0 and child._position.x <= self._size.width
                and child._position.y + child._size.height >= 0 and child._position.y <= self._size.height;
    else
        return true;
    end
end

function M:getFirstChildInView()
    for i, v in ipairs(self._children) do
        if self:isChildInView(v) then
            return i
        end
    end
    return -1
end

function M:getController(name)
    for i, c in ipairs(self._controllers) do
        if c.name == name then
            return c
        end
    end
end

--[[
void GComponent::addController(GController* c)
{
    CCASSERT(c != nullptr, "Argument must be non-nil");

    _controllers.pushBack(c);
}

GController * GComponent::getControllerAt(int index) const
{
    return _controllers.at(index);
}


void GComponent::removeController(GController* c)
{
    CCASSERT(c != nullptr, "Argument must be non-nil");

    ssize_t index = _controllers.getIndex(c);
    CCASSERT(index != -1, "controller not exists");

    c->setParent(nullptr);
    applyController(c);
    _controllers.erase(index);
}

--]]

---@param c GController
function M:applyController(c)
    self._applyingController = c

    for i, child in ipairs(self._children) do
        child:handleControllerChanged(c)
    end

    self._applyingController = nil

    c:runActions()
end

function M:applyAllControllers()
    for i, v in ipairs(self._controllers) do
        self:applyController(v)
    end
end

function M:getTransition(name)
    for i, v in ipairs(self._transitions) do
        if v.name == name then
            return v
        end
    end
end

function M:getTransitionAt(index)
    return self._transitions[index]
end

function M:getTransitions()
    return self._transitions
end

--[[
void GComponent::adjustRadioGroupDepth(GObject* obj, GController* c)
{
    ssize_t cnt = (ssize_t)_children.size();
    ssize_t i;
    GObject* child;
    ssize_t myIndex = -1, maxIndex = -1;
    for (i = 0; i < cnt; i++)
    {
        child = _children.at(i);
        if (child == obj)
        {
            myIndex = i;
        }
        else if (dynamic_cast<GButton*>(child)
            && ((GButton *)child)->getRelatedController() == c)
        {
            if (i > maxIndex)
                maxIndex = i;
        }
    }
    if (myIndex < maxIndex)
    {
        if (_applyingController != nullptr)
            _children.at(maxIndex)->handleControllerChanged(_applyingController);
        swapChildrenAt((int)myIndex, (int)maxIndex);
    }
}
--]]

function M:getOpaque()
    return self._opaque
end

function M:setOpaque(value)
    self._opaque = value;
end

--[[
void GComponent::setMargin(const Margin & value)
{
    _margin = value;
}

void GComponent::setChildrenRenderOrder(ChildrenRenderOrder value)
{
    if (_childrenRenderOrder != value)
    {
        _childrenRenderOrder = value;
        CALL_LATER(GComponent, buildNativeDisplayList);
    }
}

void GComponent::setApexIndex(int value)
{
    if (_apexIndex != value)
    {
        _apexIndex = value;

        if (_childrenRenderOrder == ChildrenRenderOrder::ARCH)
            CALL_LATER(GComponent, buildNativeDisplayList);
    }
}

cocos2d::Node* GComponent::getMask() const
{
    return ((FUIContainer*)_displayObject)->getStencil();
}
--]]

function M:setMask(node, inverted)

    if self._maskOwner then
        self._isAdoptiveChild = false
        self:childStateChanged(self._maskOwner)
        self._maskOwner:handlePositionChanged()
        self._maskOwner = nil
    end

    if node then
        for i, v in ipairs(self._children) do
            if v._displayObject == node then
                self._maskOwner = v
                --node:retain()
                if node:getParent() then
                    node:getParent():removeChild(node, false)
                end
                self._maskOwner._isAdoptiveChild = true
                self._maskOwner:handleSizeChanged()

                break
            end
        end
    end

    self._displayObject:setStencil(node)

    if node then
        --TODO 坐标是倒过来的。。。
        node:setPositionY(self:getHeight() - self._maskOwner:getY())

        self._displayObject:setAlphaThreshold(0.05)
        self._displayObject:setInverted(inverted)
        node:release()
    end

end


function M:setHitArea(value)
    if self._hitArea~=value then
        self._hitArea = value
    end
end

function M:getScrollPane()
    return self._scrollPane
end

function M:getViewWidth()
    if (self._scrollPane) then
        return self._scrollPane:getViewSize().width;
    else
        return self._size.width - self._margin.left - self._margin.right;
    end
end

function M:setViewWidth(value)
    if (self._scrollPane) then
        self._scrollPane:setViewWidth(value);
    else
        self:setWidth(value + self._margin.left + self._margin.right);
    end
end

function M:getViewHeight()
    if (self._scrollPane) then
        return self._scrollPane:getViewSize().height;
    else
        return self._size.height - self._margin.top - self._margin.bottom;
    end
end

function M:setViewHeight(value)
    if (self._scrollPane) then
        self._scrollPane:setViewHeight(value);
    else
        self:setHeight(value + self._margin.top + self._margin.bottom);
    end
end

function M:setBoundsChangedFlag()

    if not self._scrollPane and not self._trackBounds then
        return
    end

    self._boundsChanged = true

    CALL_LATER(self, self.doUpdateBounds);
end

function M:ensureBoundsCorrect()
    if self._boundsChanged == true then
        self:updateBounds()
    end
end

function M:updateBounds()
    local ax, ay, aw, ah

    if #self._children ~= 0 then
        local ar, ab
        local tmp
        local cnt = #self._children
        for i = 1, cnt do
            local child = self._children[i]
            tmp = child:getX()
            if not ax then
                ax = tmp
            end
            ax = math.min(ax, tmp)  -- 左上角

            tmp = child:getY()
            if not ay then
                ay = tmp
            end
            ay = math.min(ay, tmp) -- 左上角

            tmp = child:getX() + child:getWidth()
            if not ar then
                ar = tmp
            end
            ar = math.max(ar, tmp) -- 右下角

            tmp = child:getY() + child:getHeight()
            if not ab then
                ab = tmp
            end
            ab = math.max(ab, tmp) -- 右下角
        end

        aw = ar - ax
        ah = ab - ay
    else
        ax = 0
        ay = 0
        aw = 0
        ah = 0
    end

    self:setBounds(ax, ay, aw, ah)
end

function M:setBounds(ax, ay, aw, ah)
    self._boundsChanged = false
    if self._scrollPane then
        self._scrollPane:setContentSize(math.ceil(ax + aw), math.ceil(ay + ah))
    end
end

function M:doUpdateBounds()
    if self._boundsChanged == true then
        self:updateBounds()
    end
end

---@param child GObject
function M:childStateChanged(child)
    if self._buildingDisplayList == true then
        return
    end

    if iskindof(child, "GGroup") == true then
        for i, g in ipairs(self._children) do
            if g._group == child then
                self:childStateChanged(g)
            end
        end
    end

    if child._displayObject == nil or child == self._maskOwner then
        return
    end

    if (child:internalVisible() == true) then
        if child._displayObject:getParent() == nil then
            if self._childrenRenderOrder == T.ChildrenRenderOrder.ASCENT then
                local index = table.indexof(self._children, child)
                self._container:addChild(child._displayObject, index)
                local cnt = #self._children
                for i = index + 1, cnt do
                    local c = self._children[i]
                    if c._displayObject:getParent() then
                        c._displayObject:setLocalZOrder(i)
                    end
                end
            elseif self._childrenRenderOrder == T.ChildrenRenderOrder.DESCENT then
                local index = table.indexof(self._children, child)
                local cnt = #self._children
                index = cnt - index
                self._container:addChild(child._displayObject, index)
                for i = #self._children, index, -1 do
                    local c = self._children[i]
                    if c._displayObject:getParent() then
                        c._displayObject:setLocalZOrder(cnt - i)
                    end
                end
            else
                CALL_LATER(self, self.buildNativeDisplayList)
            end
        end
    else
        if child._displayObject:getParent() ~= nil then
            self._container:removeChild(child._displayObject, false)
            if self._childrenRenderOrder == T.ChildrenRenderOrder.ARCH then
                CALL_LATER(self, self.buildNativeDisplayList)
            end
        end
    end
end

---@param child GObject
function M:childSortingOrderChanged(child, oldValue, newValue)
    if newValue == 0 then
        self._sortingChildCount = self._sortingChildCount - 1
        self:setChildIndex(child, #self._children)
    else
        if (oldValue == 0) then
            self._sortingChildCount = self._sortingChildCount + 1
        end
        local oldIndex = table.indexof(self._children, child)
        local index = self:getInsertPosForSortingChild(child)
        if (oldIndex < index) then
            self:moveChild(child, oldIndex, index - 1)
        else
            self:moveChild(child, oldIndex, index)
        end
    end
end

function M:buildNativeDisplayList()
    local cnt = #self._children
    if cnt == 0 then
        return
    end

    if self._childrenRenderOrder == T.ChildrenRenderOrder.ASCENT then
        for i, child in ipairs(self._children) do
            if child._displayObject and child ~= self._maskOwner and child:internalVisible() == true then
                self._container:addChild(child._displayObject, i)
            end
        end
    elseif self._childrenRenderOrder == T.ChildrenRenderOrder.DESCENT then
        for i, child in ipairs(self._children) do
            if child._displayObject and child ~= self._maskOwner and child:internalVisible() == true then
                self._container:addChild(child._displayObject, cnt - 1 - i)
            end
        end
    elseif self._childrenRenderOrder == T.ChildrenRenderOrder.ARCH then
        for i = 1, self._apexIndex do
            local child = self._children[i]
            if child._displayObject and child ~= self._maskOwner and child:internalVisible() == true then
                self._container:addChild(child._displayObject, i)
            end
        end
        for i = #self._children, self._apexIndex, -1 do
            local child = self._children[i]
            if child._displayObject and child ~= self._maskOwner and child:internalVisible() == true then
                self._container:addChild(child._displayObject, cnt - 1 - i)
            end
        end
    end
end

function M:getSnappingPosition(pt)
    local cnt = #self._children
    if cnt == 0 then
        return pt
    end

    self:ensureBoundsCorrect()

    local obj

    local ret = clone(pt)

    local idx_y = -1;
    if (ret.y ~= 0) then
        for i = 1, cnt do
            obj = self._children[i]
            if (ret.y < obj:getY()) then
                idx_y = i --标记是否找到
                if i == 1 then
                    ret.y = 0
                    break
                else
                    local prev = self._children[i - 1]
                    if (ret.y < prev:getY() + prev:getHeight() / 2) then
                        --top half part
                        ret.y = prev:getY();
                    else
                        --bottom half part
                        ret.y = obj:getY();
                    end
                    break
                end
            end
        end

        if idx_y == -1 then
            idx_y = idx_y + 1
            ret.y = obj:getY()
        end
    end

    local idx_x = -1
    if (ret.x ~= 0) then
        for i = idx_y, cnt do
            obj = self._children[i]
            if (ret.x < obj:getX()) then
                idx_x = i
                if (i == 1) then
                    ret.x = 0
                    break
                else
                    local prev = self._children[i - 1]
                    if (ret.x < prev:getX() + prev:getWidth() / 2) then
                        --top half part
                        ret.x = prev:getX();
                    else
                        --bottom half part
                        ret.x = obj:getWidth();
                    end
                    break
                end
            end
        end

        if idx_x == -1 then
            ret.x = obj:getX();
        end
    end

    return ret;
end

function M:hitTest(worldPoint)

    if self._touchDisabled == true
            or self._touchable == false
            or self._displayObject:isVisible() == false
            or self._displayObject:getParent() == nil
    then
        return nil
    end

    local target

    if self._maskOwner then
        ---[[
        if self:hitTest_maskOwner(worldPoint) ~= nil then
            --]]
            --[[
            if self._maskOwner:hitTest(worldPoint) ~= nil then
            --]]
            if self._displayObject:isInverted() == true then
                return nil
            end
        else
            if self._displayObject:isInverted() == false then
                return nil
            end
        end

    end

    local flag = 0

    if self._hitArea then
        local rect = cc.rect(0, 0, self._size.width, self._size.height)
        local localPoint = self._displayObject:convertToNodeSpace(worldPoint)

        if cc.rectContainsPoint(rect, localPoint) == true then
            flag = 1
        else
            flag = 2
        end

        if self._hitArea:hitTest(self, localPoint) == false then
            return nil
        end
    else
        if self._displayObject:isClippingEnabled() then
            local rect = cc.rect(0, 0, self._size.width, self._size.height)
            local localPoint = self._displayObject:convertToNodeSpace(worldPoint)
            if cc.rectContainsPoint(rect, localPoint) == true then
                flag = 1
            else
                flag = 2
            end

            local clipRect = self._displayObject:getClippingRegion()
            if cc.rectContainsPoint(clipRect, localPoint) == false then
                return nil
            end
        end
    end

    if self._scrollPane then
        target = self._scrollPane:hitTest(worldPoint)
        if target == nil then
            return nil
        end

        if target ~= self then
            return target
        end
    end

    for i = #self._children, 1, -1 do
        local child = self._children[i]
        while true do
            if child._displayObject == nil or child == self._maskOwner then
                break
            end

            target = child:hitTest(worldPoint)
            if target then
                return target
            end

            break
        end
    end

    if self._opaque == true then
        if flag == 0 then
            local rect = cc.rect(0, 0, self._size.width, self._size.height)
            local localPoint = self._displayObject:convertToNodeSpace(worldPoint)
            if cc.rectContainsPoint(rect, localPoint) == true then
                flag = 1
            else
                flag = 2
            end
        end

        if flag == 1 then
            return self
        else
            return nil
        end
    else
        return nil
    end

end

---@param overflow OverflowType string
function M:setupOverflow(overflow)
    if overflow == T.OverflowType.HIDDEN then

        self._displayObject:setClippingEnabled(true)
        self._displayObject:setClippingRegion(cc.rect(
                self._margin.left,
                self._margin.top,
                self._size.width - self._margin.left - self._margin.right,
                self._size.height - self._margin.top - self._margin.bottom
        ))
    end

    self._container:setPosition2(self._margin.left, self._margin.top)
end

---@param scrollBarMargin Margin
---@param scroll ScrollType
---@param scrollBarDisplay ScrollBarDisplayType
---@param scrollBarFlags number
---@param vtScrollBarRes string
---@param hzScrollBarRes string
---@param headerRes string
---@param footerRes string
function M:setupScroll(scrollBarMargin, scroll, scrollBarDisplay, scrollBarFlags,
                       vtScrollBarRes, hzScrollBarRes, headerRes, footerRes)
    self._scrollPane = ScrollPane.new(self, scroll, scrollBarMargin, scrollBarDisplay, scrollBarFlags,
            vtScrollBarRes, hzScrollBarRes, headerRes, footerRes)
end

function M:handleSizeChanged()
    M.super.handleSizeChanged(self)

    if self._scrollPane then
        self._scrollPane:onOwnerSizeChanged()
    else
        self._container:setPosition2(self._margin.left, self._margin.top)
    end

    if self._maskOwner then
        self._maskOwner:handlePositionChanged()
    end

    if self._displayObject:isClippingEnabled() then
        self._displayObject:setClippingRegion(
                cc.rect(
                        self._margin.left,
                        self._margin.top,
                        self._size.width - self._margin.left - self._margin.right,
                        self._size.height - self._margin.top - self._margin.bottom
                )
        )
    end


    if self._hitArea then
        local test = self._hitArea
        if self.sourceSize.width ~= 0 then
            test.scaleX = self._size.width/self.sourceSize.width
        end
        if self.sourceSize.height ~= 0 then
            test.scaleY = self._size.height/self.sourceSize.height
        end
    end
end

function M:handleGrayedChanged()
    M.super.handleGrayedChanged(self)

    local cc = self:getController("grayed");
    if (cc) then
        cc:setSelectedIndex(self:isGrayed() and 2 or 1);
    else
        for i, child in ipairs(self._children) do
            child:handleGrayedChanged();
        end
    end
end

function M:handleControllerChanged(c)
    GObject.handleControllerChanged(self, c)

    if self._scrollPane then
        self._scrollPane:handleControllerChanged(c)
    end
end

function M:onEnter()
    M.super.onEnter(self)

    for i, v in ipairs(self._transitions) do
        if v:isAutoPlay() == true then
            v:play(v.autoPlayRepeat, v.autoPlayDelay, nil)
        end
    end
end

function M:onExit()
    M.super.onExit(self)

    for i, v in ipairs(self._transitions) do
        v:OnOwnerRemovedFromStage()
    end
end

---@param objectPool std::vector<GObject*>* @可为空
---@param poolIndex number @默认为0
function M:constructFromResource(objectPool, poolIndex)
    local xml = self._packageItem.componentData:children()[1]

    self._underConstruct = true

    local p = xml["@size"]
    if p then
        local v2 = string.split(p, ',')
        local p1 = checkint(v2[1])
        local p2 = checkint(v2[2])
        self.initSize = cc.size(p1, p2)
        self.sourceSize = cc.size(p1, p2)

        self:setSize(p1, p2)
    end

    p = xml["@restrictSize"]
    if p then
        local v4 = string.split(p, ',')
        self.minSize.width = checkint(v4[1])
        self.minSize.height = checkint(v4[2])
        self.maxSize.width = checkint(v4[3])
        self.maxSize.height = checkint(v4[4])
    end

    p = xml["@pivot"]
    if p then
        local v2 = string.split(p, ',')
        local p1 = checkint(v2[1])
        local p2 = checkint(v2[2])

        local anchor = (xml["@anchor"] == "trie")

        self:setPivot(p1, p2, anchor)
    end

    p = xml["@opaque"]
    if p then
        self._opaque = (not (p == "false"))
    else
        self._opaque = true
    end

    p = xml["@hitTest"]
    if p then
        local arr = string.split(p, ",")
        local hitTestData = self._packageItem.owner:getPixelHitTestData(arr[1])
        if hitTestData then
            self:setHitArea(PixelHitTest.new(hitTestData, checkint(arr[2]), checkint(arr[3])))
        end
    end

    local overflow = xml["@overflow"] or T.OverflowType.VISIBLE

    p = xml["@margin"]
    if p then
        local v4 = string.split(p, ',')
        local p1 = checkint(v4[1])
        local p2 = checkint(v4[2])
        local p3 = checkint(v4[3])
        local p4 = checkint(v4[4])

        self._margin:setMargin(p1, p2, p3, p4);
    end

    if (overflow == T.OverflowType.SCROLL) then
        local scroll = xml["@scroll"] or T.ScrollType.VERTICAL
        local scrollBarDisplay = xml["@scrollBar"] or T.ScrollBarDisplayType.DEFAULT

        local scrollBarFlags = checkint(xml["@scrollBarFlags"])

        local scrollBarMargin = Margin.new()
        local p = xml["@scrollBarMargin"]
        if p then
            local v4 = string.split(p, ',')
            local p1 = checkint(v4[1])
            local p2 = checkint(v4[2])
            local p3 = checkint(v4[3])
            local p4 = checkint(v4[4])

            scrollBarMargin:setMargin(p1, p2, p3, p4)
        end

        local vtScrollBarRes
        local hzScrollBarRes
        local p = xml["@scrollBarRes"]
        if p then
            local arr = string.split(p, ',')
            vtScrollBarRes = arr[1]
            hzScrollBarRes = arr[2]
        end

        local headerRes
        local footerRes
        local p = xml["@ptrRes"]
        if p then
            local arr = string.split(p, ',')
            headerRes = arr[1]
            footerRes = arr[2]
        end

        self:setupScroll(scrollBarMargin, scroll, scrollBarDisplay, scrollBarFlags,
                vtScrollBarRes, hzScrollBarRes, headerRes, footerRes)

    else
        self:setupOverflow(overflow)
    end

    self._buildingDisplayList = true

    for i, v in ipairs(xml:children()) do
        if v:name() == "controller" then
            local exml = v

            local controller = GController.new()
            table.insert(self._controllers, controller)
            controller:setParent(self)
            controller:setup(exml)

        end
    end

    local displayList = self._packageItem.displayList
    if displayList then
        for i, v in ipairs(displayList) do

            ---@type GObject
            local child

            ---@type DisplayListItem
            local di = v
            if objectPool then
                child = objectPool[poolIndex + 1]
            elseif di.packageItem then
                di.packageItem:load()
                child = UIObjectFactory.newObject(di.packageItem,di)
                child:constructFromResource()
            else
                child = UIObjectFactory.newObject(di.type,di)
            end

            child._underConstruct = true
            child:setup_BeforeAdd(di.desc)
            child._parent = self
            table.insert(self._children, child)

        end
    end

    self._relations:setup(xml)

    for i, child in ipairs(self._children) do
        child._relations:setup(displayList[i].desc)
    end

    for i, child in ipairs(self._children) do
        child:setup_AfterAdd(displayList[i].desc)
        child._underConstruct = false
    end

    local p = xml["@mask"]
    if p then
        local inverted = xml["@reversedMask"] == "true"

        self:setMask(self:getChildById(p):displayObject(), inverted)
    end

    for i, v in ipairs(xml:children()) do
        if v:name() == "transition" then
            local exml = v
            local trans = Transition.new(self, #self._transitions)
            table.insert(self._transitions, trans)
            trans:setup(exml)
        end
    end

    self:applyAllControllers()

    self._buildingDisplayList = false
    self._underConstruct = false

    self:buildNativeDisplayList()
    self:setBoundsChangedFlag()

    self:constructFromXML(xml)

end

function M:constructFromXML(xml)

end

function M:setup_AfterAdd(xml)
    GObject.setup_AfterAdd(self, xml)

    local p

    if (self._scrollPane ~= nil and self._scrollPane:isPageMode()) then
        p = xml["@pageController"]
        if p then
            self._scrollPane:setPageController(self._parent:getController(p));
        end
    end

    p = xml["@controller"]

    if p then
        local arr = string.split(p, ",")
        local cnt = #arr
        for i = 1, cnt, 2 do
            local cc = self:getController(arr[i])
            if cc then
                cc:setSelectedPageId(arr[i + 1])
            end
        end
    end
end

---遮罩的触摸判断要重新实现：self._maskOwner:hitTest
function M:hitTest_maskOwner(worldPoint)
    local width = self._maskOwner._size.width
    local height = self._maskOwner._size.height
    local x = self._maskOwner._displayObject:getPositionX()
    local y = self._maskOwner._displayObject:getPositionY() - height
    local rect = cc.rect(x, y, width, height)
    local p = self._displayObject:convertToNodeSpace(worldPoint)
    if cc.rectContainsPoint(rect, p) == true then
        return self
    else
        return nil
    end
end

return M
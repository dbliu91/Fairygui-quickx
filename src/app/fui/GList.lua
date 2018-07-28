local ItemInfo = require("app.fui.GItemInfo")

local GObjectPool = require("app.fui.GObjectPool")

local Margin = require("app.fui.Margin")

local GComponent = require("app.fui.GComponent")

---@class GList:GComponent
---@field foldInvisibleItems boolean @如果true，当item不可见时自动折叠，否则依然占位
---@field _selectionMode ListSelectionMode @选择模式，单选，多选（shift），多选（单击）
---@field itemRenderer  function @Callback function when an item is needed to update its look.
---@field itemProvider function @Callback funtion to return item resource url.
local M = class("GList", GComponent)

function M:ctor()
    M.super.ctor(self)

    self.foldInvisibleItems = false
    self._selectionMode = T.ListSelectionMode.SINGLE
    self.scrollItemToViewOnClick = true
    self._layout = T.ListLayoutType.SINGLE_COLUMN
    self._lineCount = 0
    self._columnCount = 0
    self._lineGap = 0
    self._columnGap = 0

    self._align = T.TextHAlignment.LEFT
    self._verticalAlign = T.TextVAlignment.TOP
    self._autoResizeItem = true

    self._selectionController = nil
    self._pool = nil
    self._selectionHandled = false
    self._lastSelectedIndex = -1

    ---Virtual List support
    self._virtual = false
    self._loop = 0
    self._numItems = 0
    self._realNumItems = 0

    self._firstIndex = -1 ---the top left index
    self._virtualListChanged = 0 --- 1-content changed, 2-size changed
    self._eventLocked = false

    self._enterCounter = 0 ---因为HandleScroll是会重入的，这个用来避免极端情况下的死锁
    self._itemInfoVer = 0 ---用来标志item是否在本次处理中已经被重用了

    self._trackBounds = true
    self._pool = GObjectPool.new()
    self:setOpaque(true)

    self.itemRenderer = nil
    self.itemProvider = nil

    self._defaultItem = ""
    self._curLineItemCount = 0 ---item count in one line
    self._curLineItemCount2 = 0 ---只用在页面模式，表示垂直方向的项目数
    self._itemSize = cc.p(0, 0)

    self._virtualItems = {}
end

function M:doDestory()
    M.super.doDestory(self)

    self._pool = nil
    if (self._virtualListChanged ~= 0) then
        CALL_LATER_CANCEL(self, self.doRefreshVirtualList)
    end

    self._selectionController = nil;
    self.scrollItemToViewOnClick = false;
end

function M:getDefaultItem()
    return self._defaultItem
end

function M:setDefaultItem(value)
    self._defaultItem = value
end

function M:getLayout()
    return self._layout
end

function M:setLayout(value)
    if (self._layout ~= value) then
        self._layout = value;
        self:setBoundsChangedFlag();
        if (self._virtual==true) then
            self:setVirtualListChangedFlag(true);
        end
    end
end

function M:getLineCount()
    return self._lineCount
end

function M:setLineCount(value)
    if (self._lineCount ~= value) then
        self._lineCount = value;
        if (self._layout == T.ListLayoutType.FLOW_VERTICAL or self._layout == T.ListLayoutType.PAGINATION) then
            self:setBoundsChangedFlag();
            if (self._virtual==true) then
                self:setVirtualListChangedFlag(true);
            end
        end
    end
end

function M:getColumnCount()
    return self._columnCount
end

function M:setColumnCount(value)
    if (self._columnCount ~= value) then

        self._columnCount = value;
        if (self._layout == T.ListLayoutType.FLOW_HORIZONTAL or self._layout == T.ListLayoutType.PAGINATION) then
            self:setBoundsChangedFlag();
            if (self._virtual==true) then
                self:setVirtualListChangedFlag(true);
            end
        end

    end

end

function M:getLineGap()
    return self._lineGap
end

function M:setLineGap(value)
    if (self._lineGap ~= value) then
        self._lineGap = value;
        self:setBoundsChangedFlag();
        if (self._virtual==true) then
            self:setVirtualListChangedFlag(true);
        end
    end
end

function M:getColumnGap()
    return self._columnGap
end

function M:setColumnGap(value)
    if (self._columnGap ~= value) then
        self._columnGap = value;
        self:setBoundsChangedFlag();
        if (self._virtual==true) then
            self:setVirtualListChangedFlag(true);
        end
    end
end

function M:getAlign()
    return self._align
end

function M:setAlign(value)
    if (self._align ~= value) then
        self._align = value;
        self:setBoundsChangedFlag();
        if (self._virtual==true) then
            self:setVirtualListChangedFlag(true);
        end
    end
end

function M:getVerticalAlign()
    return self._verticalAlign
end

function M:setVerticalAlign(value)
    if (self._verticalAlign ~= value) then
        self._verticalAlign = value;
        self:setBoundsChangedFlag();
        if (self._virtual==true) then
            self:setVirtualListChangedFlag(true);
        end
    end
end

function M:getAutoResizeItem()
    return self._autoResizeItem
end

function M:setAutoResizeItem(value)
    if (self._autoResizeItem ~= value) then
        self._autoResizeItem = value;
        self:setBoundsChangedFlag();
        if (self._virtual==true) then
            self:setVirtualListChangedFlag(true);
        end
    end
end

function M:getSelectionMode()
    return self._selectionMode
end

function M:setSelectionMode(value)
    self._selectionMode = value
end

function M:getItemPool()
    return self._pool
end

function M:getFromPool(url)

    if not url then
        url = ""
    end

    local ret;
    if (url == "") then
        ret = self._pool:getObject(self._defaultItem);
    else
        ret = self._pool:getObject(url);
    end
    if (ret ~= nil) then
        ret:setVisible(true);
    end
    return ret;
end

function M:returnToPool(obj)
    self._pool:returnObject(obj);
end

function M:addItemFromPool(url)
    if not url then
        url = ""
    end
    local obj = self:getFromPool(url)
    return self:addChild(obj)
end

function M:addChildAt(child, index)
    GComponent.addChildAt(self, child, index);
    if iskindof(child, "GButton") then
        local button = child;
        button:setSelected(false);
        button:setChangeStateOnClick(false);
    end

    child:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onItemTouchBegin), self);
    child:addClickListener(handler(self, self.onClickItem), self);
    child:addEventListener(T.UIEventType.RightClick, handler(self, self.onClickItem), self);

    return child;
end

function M:removeChildAt(index)
    local child = self._children[index]
    child:removeClickListener(self);
    child:removeEventListener(T.UIEventType.TouchBegin, self);
    child:removeEventListener(T.UIEventType.RightClick, self);

    GComponent.removeChildAt(self, index);
end

function M:removeChildToPoolAt(index)
    self:returnToPool(self:getChildAt(index));
    self:removeChildAt(index);
end

function M:removeChildToPool(child)
    self:returnToPool(child);
    self:removeChild(child);
end

function M:removeChildrenToPool(beginIndex, endIndex)
    if not beginIndex then
        beginIndex = 1
    end

    if not endIndex then
        endIndex = #self._children
    end
	
	if endIndex <= 0 or endIndex > #self._children then
		endIndex = #self._children
	end

    for i = beginIndex, endIndex do
        self:removeChildToPoolAt(beginIndex)
    end

end

function M:getSelectedIndex()
    if (self._virtual == true) then
        local cnt = self._realNumItems
        for i = 1, cnt do
            local ii = self._virtualItems[i]
            if (iskindof(ii.obj, "GButton") and ii.obj:isSelected())
                    or (ii.obj == nil and ii.selected == true) then
                if self._loop == true then
                    return LUA_MOD(i,self._numItems)
                else
                    return i
                end
            end
        end
    else
        for i, obj in ipairs(self._children) do
            if iskindof(obj, "GButton") and obj:isSelected() then
                return i
            end
        end
    end

    return -1
end

function M:setSelectedIndex(value)
    if value > 0 and value <= self:getNumItems() then
        if (self._selectionMode ~= T.ListSelectionMode.SINGLE) then
            self:clearSelection();
        end
        self:addSelection(value, false);
    else
        self:clearSelection()
    end
end

function M:getSelectionController()
    return self._selectionController
end

function M:setSelectionController(value)
    self._selectionController = value
end


function M:getSelection(result_no_use)
    if result_no_use then
        assert(false,"getSelection 不接受传值")
    end

    local result = {}

    if self._virtual == true then
        local cnt = self._realNumItems
        for i = 1, cnt do
            local ii = self._virtualItems[i]
            if (iskindof(ii, "GButton") and ii.obj:isSelected())
                    or (ii.obj and ii.selected == true)
            then
                local j = i
                while true do
                    if self._loop == true then
                        j = LUA_MOD(i,self._numItems)
                        if table.indexof(result, j) ~= false then
                            break
                        end
                    end
                    break
                end

                table.insert(result, j)
            end
        end
    else
        for i, v in ipairs(self._children) do
            if iskindof(v, "GButton") and v:isSelected() then
                table.insert(result, i)
            end
        end
    end

    return result

end

function M:addSelection(index, scrollItToView)
    if (self._selectionMode == T.ListSelectionMode.NONE) then
        return ;
    end

    self:checkVirtualList();

    if (self._selectionMode == T.ListSelectionMode.SINGLE) then
        self:clearSelection();
    end

    if (scrollItToView) then
        self:scrollToView(index);
    end

    self._lastSelectedIndex = index;
    local obj
    if (self._virtual==true) then

        local ii = self._virtualItems[index];
        if (ii.obj) then
            obj = ii.obj
        end
        ii.selected = true;
    else
        obj = self:getChildAt(index);
    end

    if (obj and obj:isSelected() == false) then
        obj:setSelected(true);
        self:updateSelectionController(index);
    end
end

function M:removeSelection(index)
    if (self._selectionMode == T.ListSelectionMode.NONE) then
        return ;
    end

    local obj
    if (self._virtual==true) then
        local ii = self._virtualItems[index];
        if (ii.obj) then
            obj = ii.obj;
        end
        ii.selected = false;
    else
        obj = self:getChildAt(index);
    end

    if obj then
        obj:setSelected(false);
    end
end

function M:clearSelection()
    if (self._virtual) then
        local cnt = self._realNumItems
        for i = 1, cnt do
            local ii = self._virtualItems[i]
            if iskindof(ii.obj, "GButton") then
                ii.obj:setSelected(false)
            end
            ii.selected = false
        end
    else
        for i, v in ipairs(self._children) do
            if iskindof(v, "GButton") then
                v:setSelected(false)
            end
        end
    end
end

---@param g GObject
function M:clearSelectionExcept(g)
    if (self._virtual) then
        for i, v in ipairs(self._virtualItems) do
            if v.obj ~= g then
                if iskindof(v.obj, "GButton") then
                    v.obj:setSelected(false);
                end
                v.selected = false
            end
        end
    else
        for i, v in ipairs(self._children) do
            if iskindof(v, "GButton") and v ~= g then
                v:setSelected(false);
            end
        end
    end
end

function M:selectAll()
    self:checkVirtualList()

    local last = -1
    if self._virtual then
        local cnt = self._realNumItems
        for i = 1, cnt do
            local ii = self._virtualItems[i]
            if iskindof(ii.obj, "GButton") and ii.obj:isSelected() == false then
                ii.obj:setSelected(true)
                last = i
            end
            ii.selected = true
        end
    else
        for i, v in ipairs(self._children) do
            if iskindof(v, "GButton") and v:isSelected() == false then
                v:setSelected(true)
                last = i
            end
        end
    end

    if last ~= -1 then
        self:updateSelectionController(last)
    end
end

function M:selectReverse()
    self:checkVirtualList()

    local last = -1
    if self._virtual then
        local cnt = self._realNumItems
        for i = 1, cnt do
            local ii = self._virtualItems[i]
            if iskindof(ii.obj, "GButton") then
                ii.obj:setSelected(not ii.obj:isSelected())
                if ii.obj:isSelected() then
                    last = i
                end
            end
            ii.selected = not ii.selected
        end
    else
        for i, v in ipairs(self._children) do
            if iskindof(v, "GButton") then
                v:setSelected(not v:isSelected())
                if v:isSelected() then
                    last = i
                end
            end
        end
    end

    if last ~= -1 then
        self:updateSelectionController(last)
    end
end

function M:handleArrowKey(dir)
    local index = self:getSelectedIndex();
    if (index == -1) then
        return ;
    end

    --TODO  方向键。。。
    --这个函数没有地方调用了。。。

    --[[
    switch (dir)
    {
    case 1://up
        if (_layout == ListLayoutType::SINGLE_COLUMN || _layout == ListLayoutType::FLOW_VERTICAL)
        {
            index--;
            if (index >= 0)
            {
                clearSelection();
                addSelection(index, true);
            }
        }
        else if (_layout == ListLayoutType::FLOW_HORIZONTAL || _layout == ListLayoutType::PAGINATION)
        {
            GObject* current = _children.at(index);
            int k = 0;
            int i;
            for (i = index - 1; i >= 0; i--)
            {
                GObject *obj = _children.at(i);
                if (obj->getY() != current->getY())
                {
                    current = obj;
                    break;
                }
                k++;
            }
            for (; i >= 0; i--)
            {
                GObject *obj = _children.at(i);
                if (obj->getY() != current->getY())
                {
                    clearSelection();
                    addSelection(i + k + 1, true);
                    break;
                }
            }
        }
        break;

    case 3://right
        if (_layout == ListLayoutType::SINGLE_ROW || _layout == ListLayoutType::FLOW_HORIZONTAL || _layout == ListLayoutType::PAGINATION)
        {
            index++;
            if (index < _children.size())
            {
                clearSelection();
                addSelection(index, true);
            }
        }
        else if (_layout == ListLayoutType::FLOW_VERTICAL)
        {
            GObject* current = _children.at(index);
            int k = 0;
            int cnt = (int)_children.size();
            int i;
            for (i = index + 1; i < cnt; i++)
            {
                GObject *obj = _children.at(i);
                if (obj->getX() != current->getX())
                {
                    current = obj;
                    break;
                }
                k++;
            }
            for (; i < cnt; i++)
            {
                GObject *obj = _children.at(i);
                if (obj->getX() != current->getX())
                {
                    clearSelection();
                    addSelection(i - k - 1, true);
                    break;
                }
            }
        }
        break;

    case 5://down
        if (_layout == ListLayoutType::SINGLE_COLUMN || _layout == ListLayoutType::FLOW_VERTICAL)
        {
            index++;
            if (index < _children.size())
            {
                clearSelection();
                addSelection(index, true);
            }
        }
        else if (_layout == ListLayoutType::FLOW_HORIZONTAL || _layout == ListLayoutType::PAGINATION)
        {
            GObject* current = _children.at(index);
            int k = 0;
            int cnt = (int)_children.size();
            int i;
            for (i = index + 1; i < cnt; i++)
            {
                GObject *obj = _children.at(i);
                if (obj->getY() != current->getY())
                {
                    current = obj;
                    break;
                }
                k++;
            }
            for (; i < cnt; i++)
            {
                GObject *obj = _children.at(i);
                if (obj->getY() != current->getY())
                {
                    clearSelection();
                    addSelection(i - k - 1, true);
                    break;
                }
            }
        }
        break;

    case 7://left
        if (_layout == ListLayoutType::SINGLE_ROW || _layout == ListLayoutType::FLOW_HORIZONTAL || _layout == ListLayoutType::PAGINATION)
        {
            index--;
            if (index >= 0)
            {
                clearSelection();
                addSelection(index, true);
            }
        }
        else if (_layout == ListLayoutType::FLOW_VERTICAL)
        {
            GObject* current = _children.at(index);
            int k = 0;
            int i;
            for (i = index - 1; i >= 0; i--)
            {
                GObject *obj = _children.at(i);
                if (obj->getX() != current->getX())
                {
                    current = obj;
                    break;
                }
                k++;
            }
            for (; i >= 0; i--)
            {
                GObject *obj = _children.at(i);
                if (obj->getX() != current->getX())
                {
                    clearSelection();
                    addSelection(i + k + 1, true);
                    break;
                }
            }
        }
        break;
    }
    --]]

end

---@param context EventContext
function M:onItemTouchBegin(context)
    local item = context:getSender()
    if (self._selectionMode == T.ListSelectionMode.NONE) then
        return ;
    end

    self._selectionHandled = false;

    if (UIConfig.defaultScrollTouchEffect
            and (self._scrollPane or (self._parent and self._parent:getScrollPane()))) then
        return ;
    end

    if (self._selectionMode == T.ListSelectionMode.SINGLE) then
        self:setSelectionOnEvent(item, context:getInput());
    else
        if (false == item:isSelected()) then
            self:setSelectionOnEvent(item, context:getInput());
        end
    end
end

---Dispatched when a list item being clicked.
---@param context EventContext
function M:onClickItem(context)
    local item = context:getSender()
    if self._selectionHandled == false then
        self:setSelectionOnEvent(item, context:getInput());
    end
    self._selectionHandled = false;

    if (self._scrollPane and self.scrollItemToViewOnClick) then
        self._scrollPane:scrollToView(item, true);
    end

    if context:getType() == T.UIEventType.Click then
        self:dispatchEvent(T.UIEventType.ClickItem, item)
    else
        self:dispatchEvent(T.UIEventType.RightClickItem, item)
    end


end


---@param item GObject
---@param evt InputEvent
function M:setSelectionOnEvent(item, evt)
    self._selectionHandled = true
    local dontChangeLastIndex = false;
    local button = item;
    local index = self:childIndexToItemIndex(self:getChildIndex(item));

    if (self._selectionMode == T.ListSelectionMode.SINGLE) then
        if (false == button:isSelected()) then
            self:clearSelectionExcept(button);
            button:setSelected(true);
        end
        if evt:isShiftDown() then
            --TODO 暂时不管键盘事件
            --[[
            if (!button->isSelected())
            {
                if (_lastSelectedIndex != -1)
                {
                    int min = MIN(_lastSelectedIndex, index);
                    int max = MAX(_lastSelectedIndex, index);
                    max = MIN(max, getNumItems() - 1);
                    if (_virtual)
                    {
                        for (int i = min; i <= max; i++)
                        {
                            ItemInfo& ii = _virtualItems[i];
                            if (dynamic_cast<GButton*>(ii.obj))
                                ((GButton*)ii.obj)->setSelected(true);
                            ii.selected = true;
                        }
                    }
                    else
                    {
                        for (int i = min; i <= max; i++)
                        {
                            GButton *obj = getChildAt(i)->as<GButton>();
                            if (obj != nullptr && !obj->isSelected())
                                obj->setSelected(true);
                        }
                    }

                    dontChangeLastIndex = true;
                }
                else
                {
                    button->setSelected(true);
                }
            }
            --]]
        elseif (evt:isCtrlDown() or self._selectionMode == T.ListSelectionMode.MULTIPLE_SINGLECLICK) then
            button:setSelected(not button:isSelected());
        else
            if (false == button:isSelected()) then
                self:clearSelectionExcept(button);
                button:setSelected(true);
            else
                self:clearSelectionExcept(button);
            end
        end
    else

    end

    if (false == dontChangeLastIndex) then
        self._lastSelectedIndex = index;
    end

    if (button:isSelected()) then
        self:updateSelectionController(index);
    end


end

function M:resizeToFit(itemCount, minSize)
    if not minSize then
        minSize = 0
    end

    self:ensureBoundsCorrect();

    local curCount = self:getNumItems();

    if not itemCount then
        itemCount = curCount
    end

    if (itemCount > curCount) then
        itemCount = curCount;
    end

    if (self._virtual) then

        local lineCount = math.ceil(itemCount / self._curLineItemCount);
        if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
            self:setViewHeight(lineCount * self._itemSize.y + math.max(0, lineCount - 1) * self._lineGap);
        else
            self:setViewWidth(lineCount * self._itemSize.x + math.max(0, lineCount - 1) * self._columnGap);
        end
    elseif (itemCount == 1) then
        if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
            self:setViewHeight(minSize);
        else
            self:setViewWidth(minSize);
        end
    else
        local i = itemCount;
        local obj
        while (i > 0) do
            obj = self:getChildAt(i);
            if (false == self.foldInvisibleItems or obj:isVisible()) then
                break ;
            end
            i = i - 1;
        end

        if i <= 0 then
            if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
                self:setViewHeight(minSize);
            else
                self:setViewWidth(minSize);
            end
        else
            local size;
            if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
                size = obj:getY() + obj:getHeight();
                if (size < minSize) then
                    size = minSize;
                end
                self:setViewHeight(size);
            else

                size = obj:getX() + obj:getWidth();
                if (size < minSize) then
                    size = minSize;
                end
                self:setViewWidth(size);
            end
        end
    end
end

function M:getFirstChildInView()
    local xx = GComponent.getFirstChildInView(self)
    return self:childIndexToItemIndex(xx);
end

function M:handleSizeChanged()
    GComponent.handleSizeChanged(self)

    self:setBoundsChangedFlag()
    if self._virtual then
        self:setVirtualListChangedFlag(true);
    end
end

function M:handleControllerChanged(c)
    GComponent.handleControllerChanged(self, c);

    if self._selectionController == c then
        self:setSelectedIndex(c:getSelectedIndex());
    end
end

function M:updateSelectionController(index)
    if (self._selectionController and false == self._selectionController.changing
            and index <= self._selectionController:getPageCount()) then
        local c = self._selectionController
        self._selectionController = nil
        c:setSelectedIndex(index)
        self._selectionController = c
    end
end

---@param index number @下标从1开始
function M:scrollToView(index, ani, setFirst)

    local cpp_index = index - 1

    if not ani then
        ani = false
    end

    if not setFirst then
        setFirst = false
    end

    if (self._virtual) then

        if (self._numItems == 0) then
            return ;
        end

        self:checkVirtualList();

        if cpp_index < 0 or cpp_index >= #self._virtualItems then
            error("Invalid child index")
        end

        if (self._loop) then
            cpp_index = math.floor(self._firstIndex / self._numItems) * self._numItems + cpp_index;
        end

        local rect = cc.rect(0, 0, 0, 0);
        local ii = self._virtualItems[cpp_index +1];
        if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then

            local pos = 0;

            for i = 1, cpp_index, self._curLineItemCount do
                pos = pos + self._virtualItems[i].size.y + self._lineGap;
            end
            rect.x = 0
            rect.y = pos
            rect.width = self._itemSize.x
            rect.height = ii.size.y
        elseif (self._layout == T.ListLayoutType.SINGLE_ROW or self._layout == T.ListLayoutType.FLOW_VERTICAL) then
            local pos = 0;
            for i = 1, cpp_index, self._curLineItemCount do
                pos = pos + self._virtualItems[i].size.x + self._columnGap;
            end
            rect.x = pos
            rect.y = 0
            rect.width = ii.size.x
            rect.height = self._itemSize.y
        else
            local page = checkint(cpp_index / (self._curLineItemCount * self._curLineItemCount2));
            rect.x = page * self:getViewWidth() + (cpp_index % self._curLineItemCount) * (ii.size.x + self._columnGap)
            rect.y = (cpp_index / self._curLineItemCount) % self._curLineItemCount2 * (ii.size.y + self._lineGap)
            rect.width = ii.size.x
            rect.height = ii.size.y
        end

        setFirst = true;
        if (self._scrollPane) then
            self._scrollPane:scrollToView(rect, ani, setFirst);
        elseif (self._parent and self._parent:getScrollPane()) then
            self._parent:getScrollPane():scrollToView(self:transformRect(rect, self._parent), ani, setFirst);
        end
    else
        local obj = self:getChildAt(cpp_index);
        if (self._scrollPane) then
            self._scrollPane:scrollToView(obj, ani, setFirst);
        elseif (self._parent and self._parent:getScrollPane()) then
            self._parent:getScrollPane():scrollToView(obj, ani, setFirst);
        end
    end

end


function M:childIndexToItemIndex(index)
    if (not self._virtual) then
        return index;
    end

    if (self._layout == T.ListLayoutType.PAGINATION) then

        for i = self._firstIndex, self._realNumItems do
            if self._virtualItems[i].obj then
                index = index - 1
                if index < 1 then
                    return i
                end
            end
        end

        return index;
    else
        --index = index + self._firstIndex
        index = index + self._firstIndex - 1 -- lua和c++下标差异

        if self._loop and self._numItems > 0 then
            index = (index % self._numItems) == 0 and self._numItems or (index % self._numItems)
        end

        return index
    end
end


function M:itemIndexToChildIndex(index)
    if self._virtual == false then
        return index
    end

    if (self._layout == T.ListLayoutType.PAGINATION) then
        return self:getChildIndex(self._virtualItems[index].obj)
    else
        if self._loop and self._numItems > 0 then
        else
            index = index - self._firstIndex;
            local j = (self._firstIndex % self._numItems) == 0 and self._numItems or (self._firstIndex % self._numItems);

            if (index >= j) then
                index = index - j;
            else
                index = self._numItems - j + index;
            end
        end
        return index;
    end
end

function M:isVirtual()
    return self._virtual
end

function M:setVirtualAndLoop()
    self:setVirtual(true)
end

function M:setVirtual(loop)
    if not loop then
        loop = false
    end

    if self._virtual == false then
        if self._scrollPane == nil then
            print("FairyGUI: Virtual list must be scrollable!")
        end

        if (loop) then

            if self._layout == T.ListLayoutType.FLOW_HORIZONTAL or self._layout == T.ListLayoutType.FLOW_VERTICAL then
                print("FairyGUI: Loop list is not supported for FlowHorizontal or FlowVertical layout!")
            end

            self._scrollPane:setBouncebackEffect(false);
        end

        self._virtual = true;
        self._loop = loop;
        self:removeChildrenToPool();

    end

    if (self._itemSize.x == 0 or self._itemSize.y == 0) then

        local obj = self:getFromPool();

        if obj == nil then
            print("FairyGUI: Virtual List must have a default list item resource.")
        end

        self._itemSize = cc.p(obj:getSize().width, obj:getSize().height);
        self._itemSize.x = math.ceil(self._itemSize.x);
        self._itemSize.y = math.ceil(self._itemSize.y);
        self:returnToPool(obj);
    end

    if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
        self._scrollPane:setScrollStep(self._itemSize.y);
        if (self._loop) then
            self._scrollPane._loop = 2;
        end
    else
        self._scrollPane:setScrollStep(self._itemSize.x);
        if (self._loop) then
            self._scrollPane._loop = 1;
        end
    end

    self:addEventListener(T.UIEventType.Scroll, handler(self, self.onScroll));
    self:setVirtualListChangedFlag(true);

end

function M:getNumItems()
    if self._virtual then
        return self._numItems
    else
        return #self._children
    end
end

function M:setNumItems(value)
    if (self._virtual) then
        if self.itemRenderer == nil then
            print("FairyGUI: Set itemRenderer first!")
        end

        self._numItems = value

        if (self._loop) then
            self._realNumItems = self._numItems * 6;
        else
            self._realNumItems = self._numItems;
        end

        local oldCount = #self._virtualItems;
        if (self._realNumItems > oldCount) then
            for i = oldCount + 1, self._realNumItems do
                local ii = ItemInfo.new()
                ii.size = self._itemSize

                table.insert(self._virtualItems, ii)
            end
        else
            for i = self._realNumItems + 1, oldCount do
                self._virtualItems[i].selected = false
            end
        end

        if self._virtualListChanged ~= 0 then
            CALL_LATER_CANCEL(self, self.doRefreshVirtualList)
        end

        --立即刷新
        self:doRefreshVirtualList()
    else
        local cnt = #self._children
        if value > cnt then
            for i = cnt+1, value do
                if self.itemProvider==nil then
                    self:addItemFromPool();
                else
                    self:addItemFromPool(self.itemProvider(i));
                end
            end
        else
            self:removeChildrenToPool(value, cnt);
        end

        if (self.itemRenderer) then
            for i = 1, value do
                self.itemRenderer(i, self:getChildAt(i));
            end
        end
    end
end

function M:refreshVirtualList()
    if self._virtual == nil then
        print("FairyGUI: not virtual list")
    end

    self:setVirtualListChangedFlag(false)
end

function M:getSnappingPosition(pt)
    if (self._virtual) then
        local ret = clone(pt)
        if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
            local index,ret_pos = self:getIndexOnPos1(ret.y, false);
            ret.y = ret_pos
            if (index <= #self._virtualItems and ((pt.y - ret.y) > self._virtualItems[index].size.y / 2) and index <= self._realNumItems) then
                ret.y = ret.y + self._virtualItems[index].size.y + self._lineGap;
            end
        elseif (self._layout == T.ListLayoutType.SINGLE_ROW or self._layout == T.ListLayoutType.FLOW_VERTICAL) then
            local index,ret_pos = self:getIndexOnPos2(ret.x, false);
            ret.x = ret_pos
            if (index <= #self._virtualItems and ((pt.x - ret.x) > self._virtualItems[index].size.x / 2) and index <= self._realNumItems) then
                ret.x = ret.x + self._virtualItems[index].size.x + self._columnGap;
            end
        else
            local index,ret_pos = self:getIndexOnPos3(ret.x, false);
            ret.x = ret_pos
            if (index <= #self._virtualItems and ((pt.x - ret.x) > self._virtualItems[index].size.x / 2) and index <= self._realNumItems) then
                ret.x = ret.x + self._virtualItems[index].size.x + self._columnGap;
            end
        end

        return ret
    else
        return GComponent.getSnappingPosition(self, pt);
    end
end

function M:checkVirtualList()
    if (self._virtualListChanged ~= 0) then
        self:doRefreshVirtualList();
        CALL_LATER_CANCEL(self, self.doRefreshVirtualList);
    end
end

function M:setVirtualListChangedFlag(layoutChanged)
    if (layoutChanged) then
        self._virtualListChanged = 2;
    elseif (self._virtualListChanged == 0) then
        self._virtualListChanged = 1;
    end
    CALL_LATER(self, self.doRefreshVirtualList);
end


function M:doRefreshVirtualList()
    local layoutChanged = (self._virtualListChanged == 2)
    self._virtualListChanged = 0;
    self._eventLocked = true;

    if (layoutChanged) then

        if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.SINGLE_ROW) then
            self._curLineItemCount = 1;
        elseif (self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
            if (self._columnCount > 0) then
                self._curLineItemCount = self._columnCount;
            else
                self._curLineItemCount = math.floor((self._scrollPane:getViewSize().width + self._columnGap) / (self._itemSize.x + self._columnGap));
                if (self._curLineItemCount <= 0) then
                    self._curLineItemCount = 1;
                end
            end
        elseif (self._layout == T.ListLayoutType.FLOW_VERTICAL) then
            if (self._lineCount > 0) then
                self._curLineItemCount = self._lineCount;
            else
                self._curLineItemCount = math.floor((self._scrollPane:getViewSize().height + self._lineGap) / (self._itemSize.y + self._lineGap));
                if (self._curLineItemCount <= 0) then
                    self._curLineItemCount = 1;
                end
            end
        else
            --pagination
            if (self._columnCount > 0) then
                self._curLineItemCount = self._columnCount;
            else
                self._curLineItemCount = math.floor((self._scrollPane:getViewSize().width + self._columnGap) / (self._itemSize.x + self._columnGap));
                if (self._curLineItemCount <= 0) then
                    self._curLineItemCount = 1;
                end
            end

            if (self._lineCount > 0) then
                self._curLineItemCount2 = self._lineCount;
            else
                self._curLineItemCount2 = math.floor((self._scrollPane:getViewSize().height + self._lineGap) / (self._itemSize.y + self._lineGap));
                if (self._curLineItemCount2 <= 0) then
                    self._curLineItemCount2 = 1;
                end
            end

        end
    end

    local ch = 0;
    local cw = 0;

    if (self._realNumItems > 0) then
        local len = math.ceil(self._realNumItems / self._curLineItemCount) * self._curLineItemCount;
        local len2 = math.min(self._curLineItemCount, self._realNumItems);

        if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
            for i = 1, len, self._curLineItemCount do
                ch = ch + self._virtualItems[i].size.y + self._lineGap
            end

            if (ch > 0) then
                ch = ch - self._lineGap;
            end

            if (self._autoResizeItem) then
                cw = self._scrollPane:getViewSize().width;
            else
                for i = 1, len2 do
                    cw = cw + self._virtualItems[i].size.x + self._columnGap;
                end
                if (cw > 0) then
                    cw = cw - self._columnGap
                end
            end
        elseif (self._layout == T.ListLayoutType.SINGLE_ROW or self._layout == T.ListLayoutType.FLOW_VERTICAL) then
            for i = 1, len, self._curLineItemCount do
                cw = cw + self._virtualItems[i].size.x + self._columnGap;
            end

            if (cw > 0) then
                cw = cw - self._columnGap;
            end

            if (self._autoResizeItem) then
                ch = self._scrollPane:getViewSize().height;
            else
                for i = 1, len2 do
                    ch = ch + self._virtualItems[i].size.y + self._lineGap;
                end

                if (ch > 0) then
                    ch = ch - self._lineGap;
                end
            end
        else
            local pageCount = matn.ceil(len / (self._curLineItemCount * self._curLineItemCount2));
            cw = pageCount * self:getViewWidth();
            ch = self:getViewHeight();
        end
    end

    self:handleAlign(cw, ch);
    self._scrollPane:setContentSize(cw, ch);

    self._eventLocked = false;

    self:handleScroll(true);

end

function M:onScroll(context)
    self:handleScroll(false)
end


function M:getIndexOnPos1(pos, forceUpdate)

    local ret_pos = 0

    if (self._realNumItems < self._curLineItemCount) then
        ret_pos = 0;
        return 1, ret_pos;
    end

    if (self:numChildren() > 0 and false == forceUpdate) then
        local pos2 = self:getChildAt(1):getY();
        if (pos2 + (self._lineGap > 0 and 0 or -self._lineGap) > pos) then
            for i = self._firstIndex - self._curLineItemCount, 1, -self._curLineItemCount do
                pos2 = pos2 - (self._virtualItems[i].size.y + self._lineGap);
                if (pos2 <= pos) then
                    ret_pos = pos2;
                    return i, ret_pos;
                end
            end

            ret_pos = 0;
            return 1, ret_pos;
        else
            local testGap = self._lineGap > 0 and self._lineGap or 0;

            for i = self._firstIndex, self._realNumItems, self._curLineItemCount do
                local pos3 = pos2 + self._virtualItems[i].size.y;
                if (pos3 + testGap > pos) then
                    ret_pos = pos2;
                    return i, ret_pos;
                end
                pos2 = pos3 + self._lineGap;
            end

            ret_pos = pos2;
            return self._realNumItems - self._curLineItemCount, ret_pos;
        end
    else
        local pos2 = 0;
        local testGap = self._lineGap > 0 and self._lineGap or 0;

        for i = 1, self._realNumItems, self._curLineItemCount do
            local pos3 = pos2 + self._virtualItems[i].size.y;
            if (pos3 + testGap > pos) then
                ret_pos = pos2;
                return i, ret_pos;
            end
            pos2 = pos3 + self._lineGap;
        end

        ret_pos = pos2;
        return self._realNumItems - self._curLineItemCount, ret_pos;
    end
end


function M:getIndexOnPos2(pos, forceUpdate)

    local ret_pos = 0

    if (self._realNumItems < self._curLineItemCount) then
        ret_pos = 0;
        return 1, ret_pos;
    end

    if (self:numChildren() > 0 and false == forceUpdate) then
        local pos2 = self:getChildAt(1):getX();
        if (pos2 + (self._columnGap > 0 and 0 or -self._columnGap) > pos) then
            for i = self._firstIndex - self._curLineItemCount, 1, -self._curLineItemCount do
                pos2 = pos2 - (self._virtualItems[i].size.x + self._columnGap);
                if (pos2 <= pos) then
                    ret_pos = pos2;
                    return i, ret_pos;
                end
            end

            ret_pos = 0;
            return 1, ret_pos;
        else
            local testGap = self._columnGap > 0 and self._columnGap or 0;

            for i = self._firstIndex, self._realNumItems, self._curLineItemCount do
                local pos3 = pos2 + self._virtualItems[i].size.x;
                if (pos3 + testGap > pos) then
                    ret_pos = pos2;
                    return i, ret_pos;
                end
                pos2 = pos3 + self._columnGap;
            end

            ret_pos = pos2;
            return self._realNumItems - self._curLineItemCount, ret_pos;
        end
    else
        local pos2 = 0;
        local testGap = self._columnGap > 0 and self._columnGap or 0;

        for i = 1, self._realNumItems, self._curLineItemCount do
            local pos3 = pos2 + self._virtualItems[i].size.x;
            if (pos3 + testGap > pos) then
                ret_pos = pos2;
                return i, ret_pos;
            end
            pos2 = pos3 + self._columnGap;
        end

        ret_pos = pos2;
        return self._realNumItems - self._curLineItemCount, ret_pos;
    end
end

function M:getIndexOnPos3(pos,forceUpdate)
    print("getIndexOnPos3",pos,forceUpdate)
    --[[
    if (_realNumItems < _curLineItemCount)
    {
        pos = 0;
        return 0;
    }

    float viewWidth = getViewWidth();
    int page = floor(pos / viewWidth);
    int startIndex = page * (_curLineItemCount * _curLineItemCount2);
    float pos2 = page * viewWidth;
    float testGap = _columnGap > 0 ? _columnGap : 0;
    for (int i = 0; i < _curLineItemCount; i++)
    {
        float pos3 = pos2 + _virtualItems[startIndex + i].size.x;
        if (pos3 + testGap > pos)
        {
            pos = pos2;
            return startIndex + i;
        }
        pos2 = pos3 + _columnGap;
    }

    pos = pos2;
    return startIndex + _curLineItemCount - 1;
    --]]
end


function M:handleScroll(forceUpdate)
    if (self._eventLocked) then
        return ;
    end

    self._enterCounter = 0;

    if (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
        self:handleScroll1(forceUpdate);
        self:handleArchOrder1();
    elseif (self._layout == T.ListLayoutType.SINGLE_ROW or self._layout == T.ListLayoutType.FLOW_VERTICAL) then
        self:handleScroll2(forceUpdate);
        self:handleArchOrder2();
    else
        self:handleScroll3(forceUpdate);
    end

    self._boundsChanged = false;

end


function M:handleScroll1(forceUpdate)
    self._enterCounter = self._enterCounter + 1
    if self._enterCounter > 3 then
        ---防止递归太深
        return
    end

    local pos = self._scrollPane:getScrollingPosY();--滚动层的底部Y坐标
    local max_h = pos + self._scrollPane:getViewSize().height;--滚动层的顶部Y坐标

    local ended = (max_h == self._scrollPane:getContentSize().height);

    local newFirstIndex, ret_pos = self:getIndexOnPos1(pos, forceUpdate);

    if (newFirstIndex == self._firstIndex and false == forceUpdate) then
        return
    end

    local oldFirstIndex = self._firstIndex;
    self._firstIndex = newFirstIndex;
    local curIndex = newFirstIndex;
    local forward = oldFirstIndex > newFirstIndex;
    local oldCount = self:numChildren();
    local lastIndex = oldFirstIndex + oldCount - 1;
    local reuseIndex = forward and lastIndex or oldFirstIndex;
    local curX = 0
    local curY = ret_pos;
    local needRender;
    local deltaSize = 0;
    local firstItemDeltaSize = 0;
    local url = self._defaultItem;
    local partSize = checkint((self._scrollPane:getViewSize().width - self._columnGap * (self._curLineItemCount - 1)) / self._curLineItemCount);

    self._itemInfoVer = self._itemInfoVer + 1;

    while (curIndex <= self._realNumItems and (ended or curY < max_h)) do
        local ii = self._virtualItems[curIndex]

        if (ii.obj == nil or forceUpdate == true) then
            if (self.itemProvider) then
                local xxx = curIndex % self._numItems
                url = self.itemProvider(xxx == 0 and self._numItems or xxx);
                if url == nil or url == "" then
                    url = self._defaultItem
                end
                url = UIPackage.normalizeURL(url)
            end

            if (ii.obj and ii.obj:getResourceURL() ~= url) then
                if iskindof(ii.obj, "GButton") then
                    ii.selected = ii.obj:isSelected()
                end

                self:removeChildToPool(ii.obj)
                ii.obj = nil
            end
        end

        if (ii.obj == nil) then
            if (forward) then
                for j = reuseIndex, oldFirstIndex, -1 do
                    local ii2 = self._virtualItems[j]

                    if (ii2.obj and ii2.updateFlag ~= self._itemInfoVer and ii2.obj:getResourceURL() ~= url) then
                        if iskindof(ii2.obj, "GButton") then
                            ii2.selected = ii2.obj:isSelected()
                        end

                        ii.obj = ii2.obj
                        ii2.obj = nil

                        if (j == reuseIndex) then
                            reuseIndex = reuseIndex - 1;
                        end

                        break ;
                    end

                end
            else
                for j = reuseIndex, lastIndex, 1 do
                    local ii2 = self._virtualItems[j]

                    if (ii2.obj and ii2.updateFlag ~= self._itemInfoVer and ii2.obj:getResourceURL() == url) then
                        if iskindof(ii2.obj, "GButton") then
                            ii2.selected = ii2.obj:isSelected()
                        end

                        ii.obj = ii2.obj
                        ii2.obj = nil

                        if (j == reuseIndex) then
                            reuseIndex = reuseIndex + 1;
                        end

                        break ;
                    end
                end
            end

            if (ii.obj) then
                self:setChildIndex(ii.obj, forward and (curIndex - newFirstIndex) or self:numChildren());
            else
                ii.obj = self._pool:getObject(url);
                if forward then
                    self:addChildAt(ii.obj, curIndex - newFirstIndex + 1)
                else
                    self:addChild(ii.obj)
                end
            end
            if iskindof(ii.obj, "GButton") then
                ii.obj:setSelected(ii.selected)
            end

            needRender = true;
        else
            needRender = forceUpdate;
        end

        if needRender then
            if (self._autoResizeItem and (self._layout == T.ListLayoutType.SINGLE_COLUMN or self._columnCount > 0)) then
                ii.obj:setSize(partSize, ii.obj:getHeight(), true);
            end

            local xxx = curIndex % self._numItems
            self.itemRenderer(xxx == 0 and self._numItems or xxx, ii.obj);

            if ((curIndex - 1) % self._curLineItemCount == 1) then
                deltaSize = deltaSize + math.ceil(ii.obj:getHeight()) - ii.size.y;
                if (curIndex == newFirstIndex and oldFirstIndex > newFirstIndex) then
                    firstItemDeltaSize = math.ceil(ii.obj:getHeight()) - ii.size.y;
                end
            end

            ii.size.x = math.ceil(ii.obj:getWidth());
            ii.size.y = math.ceil(ii.obj:getHeight());

        end

        ii.updateFlag = self._itemInfoVer;
        ii.obj:setPosition(curX, curY);
        if (curIndex == newFirstIndex) then
            max_h = max_h + ii.size.y;
        end

        curX = curX + ii.size.x + self._columnGap;

        if (curIndex % self._curLineItemCount == 0) then
            curX = 0;
            curY = curY + ii.size.y + self._lineGap;
        end

        curIndex = curIndex + 1;

    end

    for i = 1, oldCount do
        local ii = self._virtualItems[oldFirstIndex + i - 1];
        if (ii.updateFlag ~= self._itemInfoVer and ii.obj) then
            if iskindof(ii.obj, "GButton") then
                ii.obj:setSelected(ii.selected)
            end
            self:removeChildToPool(ii.obj);
            ii.obj = nil;
        end
    end

    if (deltaSize ~= 0 or firstItemDeltaSize ~= 0) then
        self._scrollPane:changeContentSizeOnScrolling(0, deltaSize, 0, firstItemDeltaSize);
    end

    if (curIndex > 1 and self:numChildren() > 0
            and self._container:getPositionY2() < 0 and self:getChildAt(1):getY() > -self._container:getPositionY2()) then
        self:handleScroll1(false);
    end

end


function M:handleScroll2(forceUpdate)
    self._enterCounter = self._enterCounter + 1
    if self._enterCounter > 3 then
        ---防止递归太深
        return
    end

    local pos = self._scrollPane:getScrollingPosX();
    local max_w = pos + self._scrollPane:getViewSize().width;
    local ended = (pos == self._scrollPane:getContentSize().width);

    local newFirstIndex, ret_pos = self:getIndexOnPos2(pos, forceUpdate);

    if (newFirstIndex == self._firstIndex and false == forceUpdate) then
        return
    end

    local oldFirstIndex = self._firstIndex;
    self._firstIndex = newFirstIndex;
    local curIndex = newFirstIndex;
    local forward = oldFirstIndex > newFirstIndex;
    local oldCount = self:numChildren();
    local lastIndex = oldFirstIndex + oldCount - 1;
    local reuseIndex = forward and lastIndex or oldFirstIndex;
    local curX = ret_pos
    local curY = 0;
    local needRender;
    local deltaSize = 0;
    local firstItemDeltaSize = 0;
    local url = self._defaultItem;
    local partSize = checkint((self._scrollPane:getViewSize().height - self._lineGap * (self._curLineItemCount - 1)) / self._curLineItemCount);

    self._itemInfoVer = self._itemInfoVer + 1;

    while (curIndex <= self._realNumItems and (ended or curX < max_w)) do
        local ii = self._virtualItems[curIndex]

        if (ii.obj == nil or forceUpdate == true) then
            if (self.itemProvider) then
                local xxx = curIndex % self._numItems
                url = self.itemProvider(xxx == 0 and self._numItems or xxx);
                if url == nil or url == "" then
                    url = self._defaultItem
                end
                url = UIPackage.normalizeURL(url)
            end

            if (ii.obj and ii.obj:getResourceURL() ~= url) then
                if iskindof(ii.obj, "GButton") then
                    ii.selected = ii.obj:isSelected()
                end

                self:removeChildToPool(ii.obj)
                ii.obj = nil
            end
        end

        if (ii.obj == nil) then
            if (forward) then
                for j = reuseIndex, oldFirstIndex, -1 do
                    local ii2 = self._virtualItems[j]

                    if (ii2.obj and ii2.updateFlag ~= self._itemInfoVer and ii2.obj:getResourceURL() ~= url) then
                        if iskindof(ii2.obj, "GButton") then
                            ii2.selected = ii2.obj:isSelected()
                        end

                        ii.obj = ii2.obj
                        ii2.obj = nil

                        if (j == reuseIndex) then
                            reuseIndex = reuseIndex - 1;
                        end

                        break ;
                    end

                end
            else
                for j = reuseIndex, lastIndex, 1 do
                    local ii2 = self._virtualItems[j]

                    if (ii2.obj and ii2.updateFlag ~= self._itemInfoVer and ii2.obj:getResourceURL() == url) then
                        if iskindof(ii2.obj, "GButton") then
                            ii2.selected = ii2.obj:isSelected()
                        end

                        ii.obj = ii2.obj
                        ii2.obj = nil

                        if (j == reuseIndex) then
                            reuseIndex = reuseIndex + 1;
                        end

                        break ;
                    end
                end
            end

            if (ii.obj) then
                self:setChildIndex(ii.obj, forward and (curIndex - newFirstIndex) or self:numChildren());
            else
                ii.obj = self._pool:getObject(url);
                if forward then
                    self:addChildAt(ii.obj, curIndex - newFirstIndex + 1)
                else
                    self:addChild(ii.obj)
                end
            end
            if iskindof(ii.obj, "GButton") then
                ii.obj:setSelected(ii.selected)
            end

            needRender = true;
        else
            needRender = forceUpdate;
        end

        if needRender then
            if (self._autoResizeItem and (self._layout == T.ListLayoutType.SINGLE_ROW or self._lineCount > 0)) then
                ii.obj:setSize(ii.obj:getWidth(), partSize, true);
            end

            local xxx = curIndex % self._numItems
            self.itemRenderer(xxx == 0 and self._numItems or xxx, ii.obj);

            if ((curIndex - 1) % self._curLineItemCount == 1) then
                deltaSize = deltaSize + math.ceil(ii.obj:getWidth()) - ii.size.x;
                if (curIndex == newFirstIndex and oldFirstIndex > newFirstIndex) then
                    firstItemDeltaSize = math.ceil(ii.obj:getWidth()) - ii.size.x;
                end
            end

            ii.size.x = math.ceil(ii.obj:getWidth());
            ii.size.y = math.ceil(ii.obj:getHeight());

        end

        ii.updateFlag = self._itemInfoVer;
        ii.obj:setPosition(curX, curY);
        if (curIndex == newFirstIndex) then
            max_w = max_w + ii.size.x;
        end

        curY = curY + ii.size.y + self._lineGap;

        if (curIndex % self._curLineItemCount == 0) then
            curY = 0;
            curX = curX + ii.size.x + self._columnGap;
        end

        curIndex = curIndex + 1;

    end

    for i = 1, oldCount do
        local ii = self._virtualItems[oldFirstIndex + i - 1];
        if (ii.updateFlag ~= self._itemInfoVer and ii.obj) then
            if iskindof(ii.obj, "GButton") then
                ii.obj:setSelected(ii.selected)
            end
            self:removeChildToPool(ii.obj);
            ii.obj = nil;
        end
    end

    if (deltaSize ~= 0 or firstItemDeltaSize ~= 0) then
        self._scrollPane:changeContentSizeOnScrolling(deltaSize, 0, firstItemDeltaSize, 0);
    end

    if (curIndex > 1 and self:numChildren() > 0
            and self._container:getPositionX() < 0
            and self:getChildAt(1):getX() > -self._container:getPositionX()) then
        self:handleScroll2(false);
    end

end

function M:handleScroll3(forceUpdate)
    --[[
    float pos = _scrollPane->getScrollingPosX();

    int newFirstIndex = getIndexOnPos3(pos, forceUpdate);
    if (newFirstIndex == _firstIndex && !forceUpdate)
        return;

    int oldFirstIndex = _firstIndex;
    _firstIndex = newFirstIndex;

    int reuseIndex = oldFirstIndex;
    int virtualItemCount = (int)_virtualItems.size();
    int pageSize = _curLineItemCount * _curLineItemCount2;
    int startCol = newFirstIndex % _curLineItemCount;
    float viewWidth = getViewWidth();
    int page = (int)(newFirstIndex / pageSize);
    int startIndex = page * pageSize;
    int lastIndex = startIndex + pageSize * 2;
    bool needRender;
    string url = _defaultItem;
    int partWidth = (int)((_scrollPane->getViewSize().width - _columnGap * (_curLineItemCount - 1)) / _curLineItemCount);
    int partHeight = (int)((_scrollPane->getViewSize().height - _lineGap * (_curLineItemCount2 - 1)) / _curLineItemCount2);
    _itemInfoVer++;

    for (int i = startIndex; i < lastIndex; i++)
    {
        if (i >= _realNumItems)
            continue;

        int col = i % _curLineItemCount;
        if (i - startIndex < pageSize)
        {
            if (col < startCol)
                continue;
        }
        else
        {
            if (col > startCol)
                continue;
        }

        ItemInfo& ii = _virtualItems[i];
        ii.updateFlag = _itemInfoVer;
    }

    GObject* lastObj = nullptr;
    int insertIndex = 0;
    for (int i = startIndex; i < lastIndex; i++)
    {
        if (i >= _realNumItems)
            continue;

        ItemInfo& ii = _virtualItems[i];
        if (ii.updateFlag != _itemInfoVer)
            continue;

        if (ii.obj == nullptr)
        {
            while (reuseIndex < virtualItemCount)
            {
                ItemInfo& ii2 = _virtualItems[reuseIndex];
                if (ii2.obj != nullptr && ii2.updateFlag != _itemInfoVer)
                {
                    if (dynamic_cast<GButton*>(ii2.obj))
                        ii2.selected = ((GButton*)ii2.obj)->isSelected();
                    ii.obj = ii2.obj;
                    ii2.obj = nullptr;
                    break;
                }
                reuseIndex++;
            }

            if (insertIndex == -1)
                insertIndex = getChildIndex(lastObj) + 1;

            if (ii.obj == nullptr)
            {
                if (itemProvider != nullptr)
                {
                    url = itemProvider(i % _numItems);
                    if (url.size() == 0)
                        url = _defaultItem;
                    url = UIPackage::normalizeURL(url);
                }

                ii.obj = _pool->getObject(url);
                addChildAt(ii.obj, insertIndex);
            }
            else
            {
                insertIndex = setChildIndexBefore(ii.obj, insertIndex);
            }
            insertIndex++;

            if (dynamic_cast<GButton*>(ii.obj))
                ((GButton*)ii.obj)->setSelected(ii.selected);

            needRender = true;
        }
        else
        {
            needRender = forceUpdate;
            insertIndex = -1;
            lastObj = ii.obj;
        }

        if (needRender)
        {
            if (_autoResizeItem)
            {
                if (_curLineItemCount == _columnCount && _curLineItemCount2 == _lineCount)
                    ii.obj->setSize(partWidth, partHeight, true);
                else if (_curLineItemCount == _columnCount)
                    ii.obj->setSize(partWidth, ii.obj->getHeight(), true);
                else if (_curLineItemCount2 == _lineCount)
                    ii.obj->setSize(ii.obj->getWidth(), partHeight, true);
            }

            itemRenderer(i % _numItems, ii.obj);
            ii.size.x = ceil(ii.obj->getWidth());
            ii.size.y = ceil(ii.obj->getHeight());
        }
    }

    float borderX = (startIndex / pageSize) * viewWidth;
    float xx = borderX;
    float yy = 0;
    float lineHeight = 0;
    for (int i = startIndex; i < lastIndex; i++)
    {
        if (i >= _realNumItems)
            continue;

        ItemInfo& ii = _virtualItems[i];
        if (ii.updateFlag == _itemInfoVer)
            ii.obj->setPosition(xx, yy);

        if (ii.size.y > lineHeight)
            lineHeight = ii.size.y;
        if (i % _curLineItemCount == _curLineItemCount - 1)
        {
            xx = borderX;
            yy += lineHeight + _lineGap;
            lineHeight = 0;

            if (i == startIndex + pageSize - 1)
            {
                borderX += viewWidth;
                xx = borderX;
                yy = 0;
            }
        }
        else
            xx += ii.size.x + _columnGap;
    }

    for (int i = reuseIndex; i < virtualItemCount; i++)
    {
        ItemInfo& ii = _virtualItems[i];
        if (ii.updateFlag != _itemInfoVer && ii.obj != nullptr)
        {
            if (dynamic_cast<GButton*>(ii.obj))
                ii.selected = ((GButton*)ii.obj)->isSelected();
            removeChildToPool(ii.obj);
            ii.obj = nullptr;
        }
    }
    --]]
end


function M:handleArchOrder1()
    if (self._childrenRenderOrder == T.ChildrenRenderOrder.ARCH) then
        local mid = self._scrollPane:getPosY() + self:getViewHeight() / 2;
        local minDist, dist
        local apexIndex = 0;
        local cnt = self:numChildren();
        for i = 1, cnt do
            local obj = self:getChildAt(i)
            if (self.foldInvisibleItems and obj:isVisible() == false) then
            else
                dist = math.abs(mid - obj:getY() - obj:getHeight() / 2);
                if not minDist or dist < minDist then
                    minDist = dist
                    apexIndex = i
                end

            end
        end

        self:setApexIndex(apexIndex);
    end
end

function M:handleArchOrder2()
    if (self._childrenRenderOrder == T.ChildrenRenderOrder.ARCH) then
        local mid = self._scrollPane:getPosX() + self:getViewWidth() / 2;
        local minDist, dist
        local apexIndex = 0;
        local cnt = self:numChildren();
        for i = 1, cnt do
            local obj = self:getChildAt(i)
            if (self.foldInvisibleItems and obj:isVisible() == false) then
            else
                dist = math.abs(mid - obj:getX() - obj:getWidth() / 2);
                if not minDist or dist < minDist then
                    minDist = dist
                    apexIndex = i
                end

            end
        end

        self:setApexIndex(apexIndex);
    end
end


function M:handleAlign(contentWidth, contentHeight)
    local newOffset = cc.p(0, 0)

    local viewHeight = self:getViewHeight();
    local viewWidth = self:getViewWidth();

    if (contentHeight < viewHeight) then
        if (self._verticalAlign == T.TextVAlignment.CENTER) then
            newOffset.y = checkint((viewHeight - contentHeight) / 2);
        elseif (self._verticalAlign == T.TextVAlignment.BOTTOM) then
            newOffset.y = viewHeight - contentHeight;
        end
    end

    if (contentWidth < viewWidth) then

        if (self._align == T.TextHAlignment.CENTER) then
            newOffset.x = checkint((viewWidth - contentWidth) / 2);
        elseif (self._align == T.TextHAlignment.RIGHT) then
            newOffset.x = viewWidth - contentWidth;
        end
    end

    if (newOffset.x ~= self._alignOffset.x or newOffset.y ~= self._alignOffset.y) then
        self._alignOffset = newOffset;
        if (self._scrollPane) then
            self._scrollPane:adjustMaskContainer();
        else
            self._container:setPosition2(self._margin.left + self._alignOffset.x, self._margin.top + self._alignOffset.y);
        end
    end

end

function M:updateBounds()
    if (self._virtual) then
        return ;
    end

    local cnt = #self._children;
    local i;
    local j = 0;
    local child;
    local curX = 0;
    local curY = 0;
    local cw, ch;
    local maxWidth = 0;
    local maxHeight = 0;
    local viewWidth = self:getViewWidth();
    local viewHeight = self:getViewHeight();

    if (self._layout == T.ListLayoutType.SINGLE_COLUMN) then
        for i = 1, cnt do
            while true do
                child = self:getChildAt(i)
                if (self.foldInvisibleItems and child:isVisible() == false) then
                    break
                end

                if (curY ~= 0) then
                    curY = curY + self._lineGap;
                end

                child:setY(curY)

                if (self._autoResizeItem) then
                    child:setSize(viewWidth, child:getHeight(), true);
                end
                curY = curY + math.ceil(child:getHeight());
                if (child:getWidth() > maxWidth) then
                    maxWidth = child:getWidth();
                end

                break
            end
        end

        cw = math.ceil(maxWidth);
        ch = curY;
    elseif (self._layout == T.ListLayoutType.SINGLE_ROW) then
        for i = 1, cnt do
            while true do
                child = self:getChildAt(i)
                if (self.foldInvisibleItems and child:isVisible() == false) then
                    break
                end

                if (curX ~= 0) then
                    curX = curX + self._columnGap;
                end
                child:setX(curX);
                if (self._autoResizeItem) then
                    child:setSize(child:getWidth(), viewHeight, true);
                end
                curX = curX + math.ceil(child:getWidth());
                if (child:getHeight() > maxHeight) then
                    maxHeight = child:getHeight();
                end

                break
            end
        end
        cw = curX;
        ch = math.ceil(maxHeight);
    elseif (self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
        if (self._autoResizeItem and self._columnCount > 0) then
            local lineSize = 0;
            local lineStart = 0;
            local ratio;

            for i = 1, cnt do
                while true do
                    child = self:getChildAt(i)
                    if (self.foldInvisibleItems and child:isVisible() == false) then
                        break
                    end
                    lineSize = lineSize + child.sourceSize.width;

                    j = j + 1

                    if (j == self._columnCount or i == cnt) then
                        -- 这里可能有bug
                        ratio = (viewWidth - lineSize - (j - 1) * self._columnGap) / lineSize;
                        curX = 0;

                        for j = lineSize, i + 1 do
                            -- 这里可能有bug
                            while true do
                                child = self:getChildAt(j);
                                if (self.foldInvisibleItems and false == child:isVisible()) then
                                    break ;
                                end

                                child:setPosition(curX, curY);

                                if (j < i) then
                                    -- 这里可能有bug
                                    child:setSize(child.sourceSize.width + math.round(child.sourceSize.width * ratio), child:getHeight(), true);
                                    curX = curX + math.ceil(child:getWidth()) + self._columnGap;
                                else
                                    child:setSize(viewWidth - curX, child:getHeight(), true);
                                end

                                if (child:getHeight() > maxHeight) then
                                    maxHeight = child:getHeight();
                                end

                                break
                            end
                        end

                        --new line
                        curY = curY + math.ceil(maxHeight) + self._lineGap;
                        maxHeight = 0;
                        j = 0;
                        lineStart = i + 1;
                        lineSize = 0;

                    end

                end
            end

            ch = curY + math.ceil(maxHeight);
            cw = viewWidth;
        else

            for i = 1, cnt do
                while true do
                    child = self:getChildAt(i)
                    if (self.foldInvisibleItems and child:isVisible() == false) then
                        break
                    end

                    if (curX ~= 0) then
                        curX = curX + self._columnGap;
                    end

                    if ((self._columnCount ~= 0 and j >= self._columnCount)
                            or (self._columnCount == 0 and curX + child:getWidth() > viewWidth and maxHeight ~= 0)) then
                        --new line
                        curX = 0;
                        curY = curY + math.ceil(maxHeight) + self._lineGap;
                        maxHeight = 0;
                        j = 0;
                    end

                    child:setPosition(curX, curY);
                    curX = curX + math.ceil(child:getWidth());

                    if (curX > maxWidth) then
                        maxWidth = curX;
                    end

                    if (child:getHeight() > maxHeight) then
                        maxHeight = child:getHeight();
                    end

                    j = j + 1

                    break
                end
            end

            ch = curY + math.ceil(maxHeight);
            cw = math.ceil(maxWidth);
        end
    elseif (self._layout == T.ListLayoutType.FLOW_VERTICAL) then
        if (self._autoResizeItem and self._lineCount > 0) then
            local lineSize = 0;
            local lineStart = 0;
            local ratio;

            for i = 1, cnt do
                while true do
                    child = self:getChildAt(i)
                    if (self.foldInvisibleItems and child:isVisible() == false) then
                        break
                    end
                    lineSize = lineSize + child.sourceSize.height;
                    j = j + 1;

                    if (j == self._columnCount or i == cnt) then
                        -- 这里可能有bug
                        ratio = (viewHeight - lineSize - (j - 1) * self._lineGap) / lineSize;
                        curY = 0;
                        for j = lineSize, i + 1 do
                            -- 这里可能有bug
                            while true do
                                child = self:getChildAt(j);
                                if (self.foldInvisibleItems and false == child:isVisible()) then
                                    break ;
                                end

                                child:setPosition(curX, curY);

                                if (j < i) then
                                    -- 这里可能有bug
                                    child:setSize(child:getWidth(), child.sourceSize.height + math.round(child.sourceSize.height * ratio), true);
                                    curY = curY + math.ceil(child:getHeight()) + self._lineGap;
                                else
                                    child:setSize(child:getWidth(), viewHeight - curY, true);
                                end

                                if (child:getWidth() > maxWidth) then
                                    maxWidth = child:getWidth();
                                end

                                break
                            end
                        end

                        --new line
                        curX = curX + math.ceil(maxWidth) + self._columnGap;
                        maxWidth = 0;
                        j = 0;
                        lineStart = i + 1;
                        lineSize = 0;

                    end

                    break
                end
            end

            cw = curX + math.ceil(maxWidth);
            ch = viewHeight;
        else
            for i = 1, cnt do
                while true do
                    child = self:getChildAt(i)
                    if (self.foldInvisibleItems and child:isVisible() == false) then
                        break
                    end

                    if (curY ~= 0) then
                        curY = curY + self._lineGap;
                    end

                    if ((self._lineCount ~= 0 and j >= self._lineCount)
                            or (self._lineCount == 0 and curY + child:getHeight() > viewHeight and maxWidth ~= 0)) then
                        --new line
                        curY = 0;
                        curX = curX + math.ceil(maxWidth) + self._columnGap;
                        maxWidth = 0;
                        j = 0;
                    end

                    child:setPosition(curX, curY);
                    curY = curY + child:getHeight();

                    if (curY > maxHeight) then
                        maxHeight = curY;
                    end

                    if (child:getWidth() > maxWidth) then
                        maxWidth = child:getWidth();
                    end

                    j = j + 1

                    break
                end
            end

            cw = curX + math.ceil(maxWidth);
            ch = math.ceil(maxHeight);
        end
    else
        --pagination
        local page = 0;
        local k = 0;
        local eachHeight = 0;
        if (self._autoResizeItem and self._lineCount > 0) then
            eachHeight = math.floor((viewHeight - (self._lineCount - 1) * self._lineGap) / self._lineCount);
        end

        if (self._autoResizeItem and self._columnCount > 0) then
            local lineSize = 0;
            local lineStart = 0;
            local ratio;

            for i = 1, cnt do
                while true do
                    child = self:getChildAt(i)
                    if (self.foldInvisibleItems and child:isVisible() == false) then
                        break
                    end

                    lineSize = lineSize + child.sourceSize.width;
                    j = j + 1;

                    if (j == self._columnCount or i == cnt) then
                        -- 这里可能有bug
                        ratio = (viewWidth - lineSize - (j - 1) * self._columnGap) / lineSize;
                        curX = 0;
                        for j = lineSize, i + 1 do
                            -- 这里可能有bug
                            while true do
                                child = self:getChildAt(j);
                                if (self.foldInvisibleItems and false == child:isVisible()) then
                                    break ;
                                end

                                child:setPosition(page * viewWidth + curX, curY);

                                if (j < i) then
                                    child : setSize(child . sourceSize.width + math.round(child . sourceSize.width * ratio),
                                            self._lineCount > 0 and eachHeight or child:getHeight(), true);
                                    curX = curX + math.ceil(child:getWidth()) + self._columnGap;
                                else
                                    child :setSize(viewWidth - curX, self._lineCount > 0 and eachHeight or child:getHeight(), true);
                                end
                                if (child : getHeight() > maxHeight) then
                                    maxHeight = child : getHeight();
                                end

                                break

                            end
                        end

                        --new line
                        curY = curY + math.ceil(maxHeight) + self._lineGap;
                        maxHeight = 0;
                        j = 0;
                        lineStart = i + 1;
                        lineSize = 0;

                        k = k + 1

                        if ((self._lineCount ~= 0 and k >= self._lineCount)
                                or (self._lineCount == 0 and curY + child:getHeight() > viewHeight)) then

                        end
                        --new page
                        page = page + 1;
                        curY = 0;
                        k = 0;
                    end

                    break
                end

            end
        else

            for i = 1, cnt do
                while true do
                    child = self:getChildAt(i)
                    if (self.foldInvisibleItems and child:isVisible() == false) then
                        break
                    end

                    if (curX ~= 0) then
                        curX = curX + self._columnGap;
                    end

                    if (self._autoResizeItem and self._lineCount > 0) then
                        child:setSize(child:getWidth(), eachHeight, true);
                    end

                    if ((self._columnCount ~= 0 and j >= self._columnCount)
                            or (self._columnCount == 0 and curX + child:getWidth() > viewWidth and maxHeight ~= 0)) then

                        curX = 0;
                        curY = curY + maxHeight + self._lineGap;
                        maxHeight = 0;
                        j = 0;
                        k = k + 1;

                        if ((self._lineCount ~= 0 and k >= self._lineCount)
                                or (self._lineCount == 0 and curY + child:getHeight() > viewHeight and maxWidth ~= 0)) then
                            --new page
                            page = page + 1;
                            curY = 0;
                            k = 0;
                        end

                    end

                    child:setPosition(page * viewWidth + curX, curY);
                    curX = curX + math.ceil(child:getWidth());
                    if (curX > maxWidth) then
                        maxWidth = curX;
                    end
                    if (child:getHeight() > maxHeight) then
                        maxHeight = child:getHeight();
                    end
                    j = j + 1;

                    break
                end
            end

            ch = page > 0 and viewHeight or (curY + math.ceil(maxHeight));
            cw = (page + 1) * viewWidth;
        end

    end

    self:handleAlign(cw, ch);
    self:setBounds(0, 0, cw, ch);

end

function M:setup_BeforeAdd(xml)
    GComponent.setup_BeforeAdd(self, xml)

    local p

    p = xml["@layout"]
    if p then
        self._layout = p
    end

    p = xml["@selectionMode"]
    if p then
        self._selectionMode = p
    end

    local overflow
    p = xml["@overflow"]
    if p then
        overflow = p
    else
        overflow = T.OverflowType.VISIBLE
    end

    p = xml["@margin"]
    if p then
        local v4 = string.split(p, ",")
        self._margin:setMargin(
                checkint(v4[3]),
                checkint(v4[1]),
                checkint(v4[4]),
                checkint(v4[2])
        )
    end

    p = xml["@align"]
    if p then
        self._align = ToolSet.parseAlign(p)
    end

    p = xml["@vAlign"]
    if p then
        self._verticalAlign = ToolSet.parseVerticalAlign(p)
    end

    if (overflow == T.OverflowType.SCROLL) then
        ---@type ScrollType
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
        self:setupOverflow(overflow);
    end

    self._lineGap = checkint(xml["@lineGap"])
    self._columnGap = checkint(xml["@colGap"])

    local c = checkint(xml["@lineItemCount"])

    if (self._layout == T.ListLayoutType.FLOW_HORIZONTAL) then
        self._columnCount = c;
    elseif (self._layout == T.ListLayoutType.FLOW_VERTICAL) then
        self._lineCount = c;
    elseif (self._layout == T.ListLayoutType.PAGINATION) then
        self._columnCount = c;
        self._lineCount = checkint(xml["@lineItemCount2"])
    end

    p = xml["@defaultItem"]
    if p then
        self._defaultItem = p
    end

    p = xml["@autoItemSize"]
    if p then
        self._autoResizeItem = (p == "true")
    elseif (self._layout == T.ListLayoutType.SINGLE_ROW or self._layout == T.ListLayoutType.SINGLE_COLUMN) then
        self._autoResizeItem = true;
    else
        self._autoResizeItem = false;
    end

    p = xml["@renderOrder"]
    if p then
        self._childrenRenderOrder = p
        if self._childrenRenderOrder == T.ChildrenRenderOrder.ARCH then
            self._apexIndex = checkint(xml["@apex"])
        end
    end

    for i, cxml in ipairs(xml:children()) do

        if cxml:name() == "item" then
            local url = cxml["@url"]
            if not url then
                url = self._defaultItem
            end
            if url and url ~= "" then
                local obj = self:getFromPool(url)
                if obj then
                    self:addChild(obj)

                    p = cxml["@title"]
                    if p then
                        obj:setText(p)
                    end

                    p = cxml["@icon"]
                    if p then
                        obj:setIcon(p)
                    end

                    p = cxml["@name"]
                    if p then
                        obj.name = p
                    end

                    p = xml["@selectedIcon"]
                    if p and iskindof(obj, "GButton") then
                        obj:setSelectedIcon(p)
                    end
                end
            end
        end

    end

end

function M:setup_AfterAdd(xml)
    GComponent.setup_AfterAdd(self, xml)

    local p = xml["@selectionController"]
    if p then
        self._selectionController = self._parent:getController(p)
    end
end

return M
local GObject = require("app.fui.GObject")

---@class GGroup:GObject
local M = class("GGroup", GObject)

function M:ctor()
    M.super.ctor(self)
    self._layout = T.GroupLayoutType.NONE
    self._updating = 0
    self._lineGap = 0
    self._columnGap = 0
    self._percentReady = false
    self._boundsChanged = false

    self._touchDisabled = true

end

function M:doDestory()
    M.super.doDestory(self)
    CALL_LATER_CANCEL(self, self.ensureBoundsCorrect)
end

function M:getLayout()
    return self._layout
end

function M:setLayout(value)
    if (self._layout ~= value) then
        self._layout = value
        self:setBoundsChangedFlag(true)
    end
end

function M:getColumnGap()
    return self._columnGap
end

function M:setColumnGap(value)
    if (self._columnGap ~= value) then
        self._columnGap = value
        self:setBoundsChangedFlag()
    end
end

function M:getLineGap()
    return self._lineGap
end

function M:setLineGap(value)
    if (self._lineGap ~= value) then
        self._lineGap = value
        self:setBoundsChangedFlag()
    end
end

function M:setBoundsChangedFlag(childSizeChanged)
    if nil == childSizeChanged then
        childSizeChanged = false
    end

    if self._updating == 0 and self._parent ~= nil then
        if childSizeChanged == true then
            self._percentReady = false
        end

        if self._boundsChanged == false then
            self._boundsChanged = true

            if self._layout ~= T.GroupLayoutType.NONE then
                CALL_LATER(self, self.ensureBoundsCorrect)
            end
        end
    end
end

function M:moveChildren(dx, dy)

    if bit.band(self._updating, 1) ~= 0 or self._parent == nil then
        return
    end

    self._updating = bit.bor(self._updating, 1)

    local cnt = self._parent:numChildren()

    for i = 1, cnt do
        local child = self._parent:getChildAt(i)
        if child._group == self then
            child:setPosition(child:getX() + dx, child:getY() + dy)
        end
    end

    self._updating = bit.band(self._updating, 2)
end

function M:resizeChildren(dw, dh)

    if self._layout == T.GroupLayoutType.NONE or bit.band(self._updating, 2) ~= 0 or self._parent == nil then
        return
    end

    self._updating = bit.bor(self._updating, 2)

    if self._percentReady == false then
        self:updatePercent()
    end

    local cnt = self._parent:numChildren()

    local last = -1
    local found = false

    local numChildren = 0

    local lineSize = 0;
    local remainSize = 0;

    for i = 1, cnt do
        while true do
            local child = self:getChildAt(i)
            if child._group ~= self then
                break
            end
            last = i
            numChildren = numChildren + 1
            break
        end
    end

    if self._layout == T.GroupLayoutType.HORIZONTAL then
        remainSize = self._size.width - (numChildren - 1) * self._columnGap
        lineSize = remainSize
        local curX = 0
        local started = false
        local nw
        for i = 1, cnt do
            while true do
                local child = self:getChildAt(i)
                if child._group ~= self then
                    break
                end

                if started == false then
                    started = true
                    curX = checkint(child:getX())
                else
                    child:setX(curX)
                end

                if last == i then
                    nw = remainSize
                else
                    nw = math.round(child._sizePercentInGroup * lineSize)
                end

                child:setSize(nw, child._rawSize.height + dh, true)
                remainSize = remainSize - child:getWidth()

                if last == i then
                    if remainSize >= 1 then
                        for j = 1, i do
                            while true do
                                local c = self._parent:getChildAt(j)
                                if c._group ~= self then
                                    break
                                end

                                if found == false then
                                    nw = c:getWidth() + remainSize
                                    if (c.maxSize.width == 0 or nw < c.maxSize.width)
                                            and
                                            c.minSize.width == 0 or nw > c.minSize.width
                                    then
                                        c:setSize(nw, c:getHeight(), true)
                                        found = true
                                    end
                                else
                                    c:setX(c:getX() + remainSize)
                                end

                                break
                            end
                        end
                    end
                else
                    curX = curX + (child:getWidth() + self._columnGap)
                end

                break
            end
        end
    elseif self._layout == T.GroupLayoutType.VERTICAL then
        remainSize = self._size.height - (numChildren - 1) * self._lineGap
        lineSize = remainSize
        local curY = 0
        local started = false
        local nh
        for i = 1, cnt do
            while true do
                local child = self:getChildAt(i)
                if child._group ~= self then
                    break
                end

                if started == false then
                    started = true
                    curY = checkint(child:getY())
                else
                    child:setY(curY)
                end

                if last == i then
                    nh = remainSize
                else
                    nh = math.round(child._sizePercentInGroup * lineSize)
                end

                child:setSize(child._rawSize.height + dw, nh, true)

                remainSize = remainSize - child:getHeight()

                if last == i then
                    if remainSize >= 1 then
                        for j = 1, i do
                            while true do
                                local c = self._parent:getChildAt(j)
                                if c._group ~= self then
                                    break
                                end

                                if found == false then
                                    nh = c:getHeight() + remainSize
                                    if (c.maxSize.height == 0 or nh < c.maxSize.height)
                                            and
                                            c.minSize.width == 0 or nh > c.minSize.width
                                    then
                                        c:setSize(c:getWidth(), nh, true)
                                        found = true
                                    end
                                else
                                    c:setY(c:getY() + remainSize)
                                end
                                break

                            end

                        end

                    end
                else
                    curY = curY + (child:getHeight() + self._lineGap)
                end
                break
            end
        end
    end

    self._updating = bit.band(self._updating, 1)
end

function M:setup_BeforeAdd(xml)
    M.super.setup_BeforeAdd(self, xml)

    local p

    p = xml["@layout"]
    if p then
        self._layout = ToolSet.parseGroupLayoutType(p)
        self._lineGap = checkint(xml["@lineGap"])
        self._columnGap = checkint(xml["@colGap"])
    end
end

function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self, xml)

    if (self._visible == false) then
        self:handleVisibleChanged();
    end
end

function M:handleAlphaChanged()
    M.super.handleAlphaChanged(self)

    if (self._underConstruct) then
        return ;
    end

    local cnt = self._parent:numChildren();
    for i = 1, cnt do
        local child = self._parent:getChildAt(i);
        if (child._group == self) then
            child:setAlpha(self._alpha);
        end
    end
end

function M:handleVisibleChanged()
    M.super.handleAlphaChanged(self)

    if (self._parent == nil) then
        return ;
    end

    local cnt = self._parent:numChildren();
    for i = 1, cnt do
        local child = self._parent:getChildAt(i);
        if (child._group == self) then
            child:handleVisibleChanged();
        end
    end
end

function M:updateBounds()
    self._boundsChanged = false;
    if (self._parent == nil) then
        return ;
    end

    self:handleLayout()

    local cnt = self._parent:numChildren();
    local child
    local ax, ay, ar, ab
    local tmp
    local empty = true

    for i = 1, cnt do
        child = self._parent:getChildAt(i);
        if (child._group == self) then
            tmp = child:getX()
            if not ax or tmp < ax then
                ax = tmp
            end

            tmp = child:getY();
            if not ay or tmp < ay then
                ay = tmp;
            end

            tmp = child:getX() + child:getWidth();
            if not ar or tmp > ar then
                ar = tmp;
            end

            tmp = child:getY() + child:getHeight();
            if not ab or tmp > ab then
                ab = tmp;
            end

            empty = false;
        end
    end

    if empty == false then
        self._updating = 1;
        self:setPosition(ax, ay);
        self._updating = 2;
        self:setSize(ar - ax, ab - ay);
    else
        self._updating = 2;
        self:setSize(0, 0);
    end

    self._updating = 0;
end

function M:handleLayout()
    self._updating = bit.bor(self._updating, 1)

    if (self._layout == T.GroupLayoutType.HORIZONTAL) then
        local curX = 0;
        local started = false;
        local cnt = self._parent:numChildren();

        for i = 1, cnt do
            local child = self._parent:getChildAt(i);
            if (child._group == self) then
                if started == false then
                    started = true;
                    curX = checkint(child:getX());
                else
                    child:setX(curX);
                end
                if (child:getWidth() ~= 0) then
                    curX = curX + checkint(child:getWidth() + self._columnGap);
                end
            end
        end

        if (self._percentReady == false) then
            self:updatePercent();
        end
    elseif (self._layout == T.GroupLayoutType.VERTICAL) then
        local curY = 0;
        local started = false;
        local cnt = self._parent:numChildren();

        for i = 1, cnt do
            local child = self._parent:getChildAt(i);
            if (child._group == self) then
                if started == false then
                    started = true;
                    curY = checkint(child:getY());
                else
                    child:setY(curY);
                end
                if (child:getHeight() ~= 0) then
                    curY = curY + checkint(child:getHeight() + self._lineGap);
                end
            end
        end

        if (self._percentReady == false) then
            self:updatePercent();
        end
    end

    self._updating = bit.band(self._updating, 2)
end

function M:updatePercent()
    self._percentReady = true;

    local cnt = self._parent:numChildren();
    local child;
    local size = 0;
    if (self._layout == T.GroupLayoutType.HORIZONTAL) then
        for i = 1, cnt do
            child = self._parent:getChildAt(i);
            if (child._group == self) then
                size = size + child:getWidth();
            end
        end

        for i = 1, cnt do
            child = self._parent:getChildAt(i);
            if (child._group == self) then
                if size>0 then
                    child._sizePercentInGroup = child:getWidth() / size;
                else
                    child._sizePercentInGroup = 0;
                end
            end
        end
    end

    if (self._layout == T.GroupLayoutType.VERTICAL) then
        for i = 1, cnt do
            child = self._parent:getChildAt(i);
            if (child._group == self) then
                size = size + child:getHeight();
            end
        end

        for i = 1, cnt do
            child = self._parent:getChildAt(i);
            if (child._group == self) then
                if size>0 then
                    child._sizePercentInGroup = child:getHeight() / size;
                else
                    child._sizePercentInGroup = 0;
                end
            end
        end
    end
end

return M
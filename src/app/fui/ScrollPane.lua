local GObject = require("app.fui.GObject")

---@type FUIContainer
local FUIContainer = require("app.fui.node.FUIContainer")

---@class ScrollPane
local M = class("ScrollPane")

local TWEEN_TIME_GO = 0.5 --tween time for SetPos(ani)
local TWEEN_TIME_DEFAULT = 0.3 --min tween time for inertial scroll
local PULL_RATIO = 0.5 --pull down/up ratio

local __gestureFlag = 0
local __draggingPane = nil

local sp_getField = function(field, axis)
    if field.x and field.y then
        return axis == 0 and field.x or field.y
    elseif field.width and field.height then
        return axis == 0 and field.width or field.height
    else
        assert(false, "sp_getField")
    end
end

local sp_setField = function(field, axis, value)
    if type(value) ~= "number" then
        assert(false, "sp_setField")
    end
    if field.x and field.y then
        if axis == 0 then
            field.x = value
        else
            field.y = value
        end
    elseif field.width and field.height then
        if axis == 0 then
            field.width = value
        else
            field.height = value
        end
    else
        assert(false, "sp_setField")
    end
end

local sp_incField = function(field, axis, value)
    if type(value) ~= "number" then
        assert(false, "sp_incField")
    end
    if field.x and field.y then
        if axis == 0 then
            field.x = field.x + value
        else
            field.y = field.y + value
        end
    elseif field.width and field.height then
        if axis == 0 then
            field.width = field.width + value
        else
            field.height = field.width + value
        end
    else
        assert(false, "sp_incField")
    end
end

local sp_EaseFunc = function(t, d)
    if type(t) ~= "number" then
        assert(false, "sp_EaseFunc")
    end
    if type(d) ~= "number" then
        assert(false, "sp_EaseFunc")
    end
    t = t / d - 1
    return t * t * t + 1 --cubicOut
end

---@param scrollBarMargin Margin
---@param scrollType ScrollType
---@param scrollBarDisplay ScrollBarDisplayType
---@param scrollBarFlags number
---@param vtScrollBarRes string
---@param hzScrollBarRes string
---@param headerRes string
---@param footerRes string
function M:ctor(owner, scrollType, scrollBarMargin, scrollBarDisplay, scrollBarFlags,
                vtScrollBarRes, hzScrollBarRes, headerRes, footerRes)

    self._vtScrollBar = nil
    self._hzScrollBar = nil
    self._header = nil
    self._footer = nil
    self._pageController = nil
    self._needRefresh = false
    self._refreshBarAxis = 0
    self._aniFlag = 0
    self._loop = 0
    self._headerLockedSize = 0
    self._footerLockedSize = 0

    self._vScrollNone = false
    self._hScrollNone = false
    self._tweening = 0
    self._xPos = 0
    self._yPos = 0

    self._viewSize = cc.size(0, 0)
    self._contentSize = cc.size(0, 0)
    self._overlapSize = cc.size(0, 0)
    self._pageSize = cc.size(0, 0)

    self._containerPos = cc.p(0, 0)
    self._beginTouchPos = cc.p(0, 0)
    self._lastTouchPos = cc.p(0, 0)
    self._lastTouchGlobalPos = cc.p(0, 0)
    self._velocity = cc.p(0, 0)

    self._tweenStart = cc.p(0, 0)
    self._tweenChange = cc.p(0, 0)
    self._tweenTime = cc.p(0, 0)
    self._tweenDuration = cc.p(0, 0)

    self._lastMoveTime = 0
    self._velocityScale = 0

    self._owner = owner
    self._maskContainer = FUIContainer.new(cc.ClippingRectangleNode)
    self._maskContainer:setCascadeOpacityEnabled(true)
    self._owner:displayObject():addChild(self._maskContainer)

    self._container = self._owner:displayObject():getChildren()[1]
    self._container:setPosition2(0, 0)
    self._container:removeFromParent()
    self._maskContainer:addChild(self._container, 1)

    self._scrollBarMargin = scrollBarMargin
    self._scrollType = scrollType

    self._scrollStep = UIConfig.defaultScrollStep
    self._mouseWheelStep = self._scrollStep * 2
    self._decelerationRate = UIConfig.defaultScrollDecelerationRate

    if scrollBarFlags == nil then
        scrollBarFlags = 0
    end

    self._displayOnLeft = bit.band(scrollBarFlags, 1) ~= 0
    self._snapToItem = bit.band(scrollBarFlags, 2) ~= 0
    self._displayInDemand = bit.band(scrollBarFlags, 4) ~= 0
    self._pageMode = bit.band(scrollBarFlags, 8) ~= 0

    if bit.band(scrollBarFlags, 16) ~= 0 then
        self._touchEffect = true
    elseif bit.band(scrollBarFlags, 32) ~= 0 then
        self._touchEffect = false
    else
        self._touchEffect = UIConfig.defaultScrollTouchEffect
    end

    if bit.band(scrollBarFlags, 64) ~= 0 then
        self._bouncebackEffect = true
    elseif bit.band(scrollBarFlags, 128) ~= 0 then
        self._bouncebackEffect = false
    else
        self._bouncebackEffect = UIConfig.defaultScrollBounceEffect
    end

    self._inertiaDisabled = bit.band(scrollBarFlags, 256) ~= 0
    self._maskContainer:setClippingEnabled(bit.band(scrollBarFlags, 512) == 0)

    self._scrollBarVisible = true
    self._mouseWheelEnabled = true
    self._pageSize = cc.p(1, 1)

    if scrollBarDisplay == T.ScrollBarDisplayType.DEFAULT then
        scrollBarDisplay = UIConfig.defaultScrollBarDisplay
    end

    if scrollBarDisplay ~= T.ScrollBarDisplayType.HIDDEN then
        if self._scrollType == T.ScrollType.BOTH or self._scrollType == T.ScrollType.VERTICAL then
            local res = (vtScrollBarRes and vtScrollBarRes ~= "") and vtScrollBarRes or UIConfig.verticalScrollBar
            if res and res ~= "" then
                self._vtScrollBar = UIPackage.createObjectFromURL(res)
                if self._vtScrollBar == nil then
                    print(string.format("FairyGUI: cannot create scrollbar from %s", res))
                else
                    self._vtScrollBar:setScrollPane(self, true)
                    self._owner:addAdoptiveChild(self._vtScrollBar)
                end
            end
        end

        if self._scrollType == T.ScrollType.BOTH or self._scrollType == T.ScrollType.HORIZONTAL then
            local res = (hzScrollBarRes and hzScrollBarRes ~= "") and hzScrollBarRes or UIConfig.horizontalScrollBar
            if res and res ~= "" then
                self._hzScrollBar = UIPackage.createObjectFromURL(res)
                if self._hzScrollBar == nil then
                    print(string.format("FairyGUI: cannot create scrollbar from %s", res))
                else
                    self._hzScrollBar:setScrollPane(self, false)
                    self._owner:addAdoptiveChild(self._hzScrollBar)
                end
            end
        end

        self._scrollBarDisplayAuto = (T.ScrollBarDisplayType.AUTO == scrollBarDisplay)

        if self._scrollBarDisplayAuto == true then
            if self._vtScrollBar then
                self._vtScrollBar:setVisible(false)
            end

            if self._hzScrollBar then
                self._hzScrollBar:setVisible(false)
            end

            self._scrollBarVisible = false

            self._owner:addEventListener(T.UIEventType.RollOver, handler(self, self.onRollOver))
            self._owner:addEventListener(T.UIEventType.RollOut, handler(self, self.onRollOut))
        end
    else
        self._mouseWheelEnabled = false
    end

    if headerRes and headerRes ~= "" then
        self._header = UIPackage.createObjectFromURL(headerRes)
        if self._header == nil then
            print(string.format("FairyGUI: cannot create scrollPane header from %s", headerRes))
        else
            self._header:setVisible(false)
            self._owner:addAdoptiveChild(self._header)
        end
    end

    if footerRes and footerRes ~= "" then
        self._footer = UIPackage.createObjectFromURL(footerRes)

        if self._footer == nil then
            print(string.format("FairyGUI: cannot create scrollPane footer from %s", footerRes))
        else
            self._footer:setVisible(false)
            self._owner:addAdoptiveChild(self._footer)
        end
    end


    if self._header or self._footer then
        self._refreshBarAxis = (self._scrollType == T.ScrollType.BOTH or self._scrollType == T.ScrollType.VERTICAL) and 1 or 0
    end

    self:setSize(self._owner:getWidth(), self._owner:getHeight())

    self._owner:addEventListener(T.UIEventType.MouseWheel, handler(self, self.onMouseWheel))
    self._owner:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onTouchBegin))
    self._owner:addEventListener(T.UIEventType.TouchMove, handler(self, self.onTouchMove))
    self._owner:addEventListener(T.UIEventType.TouchEnd, handler(self, self.onTouchEnd))

end

function M:doDestory()

    self._maskContainer:unscheduleUpdate()
    CALL_LATER_CANCEL(self, self.refresh)
    CALL_LATER_CANCEL(self, self.onShowScrollBar)

    if self._hzScrollBar then
        self._hzScrollBar._parent = nil
        self._hzScrollBar:doDestory()
    end

    if self._vtScrollBar then
        self._vtScrollBar._parent = nil
        self._vtScrollBar:doDestory()
    end

    if self._header then
        self._header._parent = nil
        self._header:doDestory()
    end

    if self._footer then
        self._footer._parent = nil
        self._footer:doDestory()
    end
end

function M:getOwner()
    return self._owner
end

function M:getHeader()
    return self._header
end

function M:getFooter()
    return self._footer
end

function M:getVtScrollBar()
    return self._vtScrollBar
end

function M:getHzScrollBar()
    return self._hzScrollBar
end

function M:isBouncebackEffect()
    return self._bouncebackEffect
end

function M:setBouncebackEffect(value)
    self._bouncebackEffect = value
end

function M:isTouchEffect()
    return self._touchEffect
end

function M:setTouchEffect(value)
    self._touchEffect = value
end

function M:isInertiaDisabled()
    return self._inertiaDisabled
end

function M:setInertiaDisabled(value)
    self._inertiaDisabled = value
end

function M:getScrollStep()
    return self._scrollStep
end

function M:setScrollStep(value)
    self._scrollStep = value

    if self._scrollStep == 0 then
        self._scrollStep = UIConfig.defaultScrollStep
    end
    self._mouseWheelStep = self._scrollStep * 2
end

function M:isSnapToItem()
    return self._snapToItem
end

function M:setSnapToItem(value)
    self._snapToItem = value
end

function M:isPageMode()
    return self._pageMode
end

function M:setPageMode(value)
    self._pageMode = value
end

function M:getPageController()
    return self._pageController
end

function M:setPageController(value)
    self._pageController = value
end

function M:isMouseWheelEnabled()
    return self._mouseWheelEnabled
end

function M:setMouseWheelEnabled(value)
    self._mouseWheelEnabled = value
end

function M:getDecelerationRate()
    return self._decelerationRate
end

function M:setDecelerationRate(value)
    self._decelerationRate = value
end

function M:getPosX()
    return self._xPos
end

function M:setPosX(value, has_ani)
    self._owner:ensureBoundsCorrect()
    if (self._loop == 1) then
        value = self:loopCheckingNewPos(value, 0)
    end

    value = math.clamp(value, 0, self._overlapSize.width)

    if value ~= self._xPos then
        self._xPos = value
        self:posChanged(has_ani)
    end

end

function M:getPosY()
    return self._yPos
end

function M:setPosY(value, has_ani)
    self._owner:ensureBoundsCorrect()
    if (self._loop == 2) then
        value = self:loopCheckingNewPos(value, 1)
    end

    value = math.clamp(value, 0, self._overlapSize.height)

    if value ~= self._yPos then
        self._yPos = value
        self:posChanged(has_ani)
    end
end

function M:getPercX()
    return self._overlapSize.width == 0 and 0 or (self._xPos / self._overlapSize.width)
end

function M:setPercX(value, has_ani)
    self._owner:ensureBoundsCorrect()

    value = math.clamp(value, 0, 1)

    self:setPosX(self._overlapSize.width * value, has_ani)
end

function M:getPercY()
    return self._overlapSize.height == 0 and 0 or (self._yPos / self._overlapSize.height)
end

function M:setPercY(value, has_ani)
    self._owner:ensureBoundsCorrect()

    value = math.clamp(value, 0, 1)

    self:setPosY(self._overlapSize.height * value, has_ani)
end

function M:isBottomMost()
    return self._yPos == self._overlapSize.height or self._overlapSize.height == 0
end

function M:isRightMost()
    return self._xPos == self._overlapSize.width or self._overlapSize.width == 0
end

function M:scrollLeft(ratio, ani)
    if ratio == nil then
        ratio = 1
    end
    if ani == nil then
        ani = false
    end

    if (self._pageMode == true) then
        self:setPosX(self._xPos - self._pageSize.width * ratio, ani)
    else
        self:setPosX(self._xPos - self._scrollStep * ratio, ani)
    end
end

function M:scrollRight(ratio, ani)
    if ratio == nil then
        ratio = 1
    end
    if ani == nil then
        ani = false
    end

    if (self._pageMode == true) then
        self:setPosX(self._xPos + self._pageSize.width * ratio, ani)
    else
        self:setPosX(self._xPos + self._scrollStep * ratio, ani)
    end
end

function M:scrollUp(ratio, ani)

    if ratio == nil then
        ratio = 1
    end

    if ani == nil then
        ani = false
    end

    if (self._pageMode == true) then
        self:setPosY(self._yPos - self._pageSize.height * ratio, ani)
    else
        self:setPosY(self._yPos - self._scrollStep * ratio, ani)
    end

end

function M:scrollDown(ratio, ani)
    if ratio == nil then
        ratio = 1
    end

    if ani == nil then
        ani = false
    end

    if (self._pageMode == true) then
        self:setPosY(self._yPos + self._pageSize.height * ratio, ani)
    else
        self:setPosY(self._yPos + self._scrollStep * ratio, ani)
    end
end

function M:scrollTop(ani)
    if ani == nil then
        ani = false
    end
    self:setPercY(0, ani)
end

function M:scrollBottom(ani)
    if ani == nil then
        ani = false
    end
    self:setPercY(1, ani)
end

function M:scrollToView(rect_or_obj, ani, setFirst)
    if not ani then
        ani = false
    end

    if not setFirst then
        setFirst = false
    end

    self._owner:ensureBoundsCorrect();
    if (self._needRefresh) then
        self:refresh();
    end

    local rect
    if iskindof(rect_or_obj, "GObject") then
        local obj = rect_or_obj
        rect = cc.rect(obj:getX(), obj:getY(), obj:getWidth(), obj:getHeight())
        if (obj:getParent() ~= self._owner) then
            rect = obj:getParent():transformRect(rect, self._owner);
        end
    else
        rect = rect_or_obj
    end

    if (self._overlapSize.height > 0) then
        local bottom = self._yPos + self._viewSize.height;
        if (setFirst or rect.y <= self._yPos or rect.height >= self._viewSize.height) then
            if (self._pageMode) then
                self:setPosY(math.floor(rect.y / self._pageSize.height) * self._pageSize.height, ani);
            else
                self:setPosY(rect.y, ani);
            end
        elseif ((rect.y + rect.height) > bottom) then
            if (self._pageMode) then
                self:setPosY(math.floor(rect.y / self._pageSize.height) * self._pageSize.height, ani);
            elseif (rect.height <= self._viewSize.height / 2) then
                self:setPosY(rect.y + rect.height * 2 - self._viewSize.height, ani);
            else
                self:setPosY((rect.y + rect.height) - self._viewSize.height, ani);
            end
        end
    end

    if (self._overlapSize.width > 0) then
        local right = self._xPos + self._viewSize.width
        if (setFirst or rect.x <= self._xPos or rect.width >= self._viewSize.width) then
            if (self._pageMode) then
                self:setPosX(math.floor(rect.x / self._pageSize.width) * self._pageSize.width, ani);
            else
                self:setPosX(rect.x, ani);
            end

        elseif ((rect.x + rect.width) > right) then
            if (self._pageMode) then
                self:setPosX(math.floor(rect.x / self._pageSize.width) * self._pageSize.width, ani);
            elseif (rect.width <= self._viewSize.width / 2) then
                self:setPosX(rect.x + rect.width * 2 - self._viewSize.width, ani);
            else
                self:setPosX((rect.x + rect.width) - self._viewSize.width, ani);
            end
        end

    end

    if (ani == false and self._needRefresh) then
        self:refresh();
    end

end

function M:isChildInView(obj)
    if (self._overlapSize.height > 0) then
        local dist = obj:getY() + self._container:getPositionY2();
        if (dist <= -obj:getHeight() or dist >= self._viewSize.height) then
            return false;
        end
    end

    if (self._overlapSize.width > 0) then
        local dist = obj:getX() + self._container:getPositionX();
        if (dist <= -obj:getWidth() or dist >= self._viewSize.width) then
            return false;
        end
    end

    return true

end

function M:getPageX()
    if self._pageMode == false then
        return 1
    end

    local page = math.floor(self._xPos / self._pageSize.width)
    if (self._xPos - page * self._pageSize.width) > self._pageSize.width * 0.5 then
        page = page + 1
    end

    return page + 1
end

function M:setPageX(value, has_ani)
    if self._pageMode == false then
        return
    end

    if self._overlapSize.width > 0 then
        self:setPosX((value - 1) * self._pageSize.width, has_ani)
    end
end

function M:getPageY()
    if self._pageMode == false then
        return 1
    end

    local page = math.floor(self._yPos / self._pageSize.height)
    if (self._yPos - page * self._pageSize.height) > self._pageSize.height * 0.5 then
        page = page + 1
    end

    return page + 1
end

function M:setPageY(value, has_ani)
    if self._overlapSize.height > 0 then
        self:setPosY((value - 1) * self._pageSize.height, has_ani)
    end
end

function M:getScrollingPosX()
    return math.clamp(-self._container:getPositionX(), 0, self._overlapSize.width);
end

function M:getScrollingPosY()
    return math.clamp(-self._container:getPositionY2(), 0, self._overlapSize.height);
end

function M:getContentSize()
    return self._contentSize
end

function M:getViewSize()
    return self._viewSize
end

function M:setViewWidth(value)
    value = value + self._owner._margin.left + self._owner._margin.right;
    if (self._vtScrollBar) then
        value = value + self._vtScrollBar:getWidth();
    end
    self._owner:setWidth(value);
end

function M:setViewHeight(value)
    value = value + self._owner._margin.top + self._owner._margin.bottom;
    if (self._hzScrollBar) then
        value = value + self._hzScrollBar:getHeight();
    end
    self._owner:setHeight(value);
end

function M:lockHeader(size)
    if (self._headerLockedSize == size) then
        return ;
    end

    local cpos = clone(self._container:getPosition2())
    self._headerLockedSize = size;

    if false == self._owner:isDispatchingEvent(T.UIEventType.PullDownRelease)
            and sp_getField(cpos, self._refreshBarAxis) >= 0 then
        self._tweenStart = cpos;
        self._tweenChange = cc.p(0, 0);
        sp_setField(self._tweenChange, self._refreshBarAxis, self._headerLockedSize - sp_getField(self._tweenStart, self._refreshBarAxis));
        self._tweenDuration = cc.p(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT);
        self.tweenTime = cc.p(0, 0);
        self._tweening = 2;

        self._maskContainer:unscheduleUpdate()
        self._maskContainer:scheduleUpdateWithPriorityLua(handler(self, self.tweenUpdate), 0)
    end
end

function M:lockFooter(size)
    if (self._footerLockedSize == size) then
        return ;
    end

    local cpos = clone(self._container:getPosition2())
    self._footerLockedSize = size;

    if false == self._owner:isDispatchingEvent(T.UIEventType.PullUpRelease)
            and sp_getField(cpos, self._refreshBarAxis) >= 0 then

        self._tweenStart = cpos;
        self._tweenChange = cc.p(0, 0);

        local max = sp_getField(self._overlapSize, self._refreshBarAxis);
        if max == 0 then
            max = math.max(sp_getField(self._contentSize, self._refreshBarAxis) + self._footerLockedSize - sp_getField(self._viewSize, self._refreshBarAxis), 0);
        else
            max = max + self._footerLockedSize;
        end

        sp_setField(self._tweenChange, self._refreshBarAxis, -max - sp_getField(self._tweenStart, self._refreshBarAxis));
        self._tweenDuration = cc.p(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT);
        self.tweenTime = cc.p(0, 0);
        self._tweening = 2;

        self._maskContainer:unscheduleUpdate()
        self._maskContainer:scheduleUpdateWithPriorityLua(handler(self, self.tweenUpdate), 0)
    end
end

function M:cancelDragging()
    if (self._draggingPane == self) then
        self._draggingPane = nil;
    end

    self._gestureFlag = 0;
    self._isMouseMoved = false;
end

M.getDraggingPane = function()
    return __draggingPane
end

function M:handleControllerChanged(c)
    if (self._pageController == c) then
        if (self._scrollType == T.ScrollType.HORIZONTAL) then
            self:setPageX(c:getSelectedIndex());
        else
            self:setPageY(c:getSelectedIndex());
        end
    end
end

function M:updatePageController()
    if (self._pageController and false == self._pageController.changing) then
        local index;
        if (self._scrollType == T.ScrollType.HORIZONTAL) then
            index = self:getPageX();
        else
            index = self:getPageY();
        end

        if (index <= self._pageController:getPageCount()) then
            local c = self._pageController;
            self._pageController = nil; --avoid calling handleControllerChanged
            c:setSelectedIndex(index);
            self._pageController = c;
        end
    end
end

function M:adjustMaskContainer()
    local mx, my
    if self._displayOnLeft == true and self._vtScrollBar ~= nil then
        mx = math.floor(self._owner._margin.left + self._vtScrollBar:getWidth())
    else
        mx = math.floor(self._owner._margin.left)
    end

    my = math.floor(self._owner._margin.top)
    mx = mx + self._owner._alignOffset.x
    my = my + self._owner._alignOffset.y

    self._maskContainer:setPosition(cc.p(mx, self._owner:getHeight() - self._viewSize.height - my))
end

function M:onOwnerSizeChanged()
    self:setSize(self._owner:getWidth(), self._owner:getHeight())
    self:posChanged(false)
end

function M:setSize(wv, hv)

    if self._hzScrollBar then
        self._hzScrollBar:setY(hv - self._hzScrollBar:getHeight())
        if self._vtScrollBar then
            local w = wv - self._vtScrollBar:getWidth() - self._scrollBarMargin.left - self._scrollBarMargin.right
            self._hzScrollBar:setWidth(w)
            if self._displayOnLeft == true then
                self._hzScrollBar:setX(self._scrollBarMargin.left + self._vtScrollBar:getWidth())
            else
                self._hzScrollBar:setX(self._scrollBarMargin.left)
            end
        else
            local w = wv - self._scrollBarMargin.left - self._scrollBarMargin.right
            self._hzScrollBar:setWidth(w)
            self._hzScrollBar:setX(self._scrollBarMargin.left)
        end
    end

    if self._vtScrollBar then
        if self._displayOnLeft == false then
            self._vtScrollBar:setX(wv - self._vtScrollBar:getWidth())
        end
        if self._hzScrollBar then
            self._vtScrollBar:setHeight(hv - self._hzScrollBar:getHeight() - self._scrollBarMargin.top - self._scrollBarMargin.bottom)
        else
            self._vtScrollBar:setHeight(hv - self._scrollBarMargin.top - self._scrollBarMargin.bottom)
        end
        self._vtScrollBar:setY(self._scrollBarMargin.top)
    end

    self._viewSize.width = wv
    self._viewSize.height = hv

    if self._hzScrollBar and self._hScrollNone == false then
        self._viewSize.height = self._viewSize.height - self._hzScrollBar:getHeight()
    end

    if self._vtScrollBar and self._vScrollNone == false then
        self._viewSize.width = self._viewSize.width - self._vtScrollBar:getWidth()
    end

    self._viewSize.width = self._viewSize.width - (self._owner._margin.left + self._owner._margin.right)
    self._viewSize.height = self._viewSize.height - (self._owner._margin.top + self._owner._margin.bottom)

    self._viewSize.width = math.max(1, self._viewSize.width)
    self._viewSize.height = math.max(1, self._viewSize.height)

    self._pageSize = clone(self._viewSize)

    self:adjustMaskContainer()
    self:handleSizeChanged()
end

function M:setContentSize(wv, hv)
    if self._contentSize.width == wv and self._contentSize.height == hv then
        return
    end

    self._contentSize.width = wv
    self._contentSize.height = hv

    self:handleSizeChanged()
end

function M:changeContentSizeOnScrolling(deltaWidth, deltaHeight, deltaPosX, deltaPosY)
    --[[
    bool isRightmost = _xPos == _overlapSize.width;
    bool isBottom = _yPos == _overlapSize.height;

    _contentSize.width += deltaWidth;
    _contentSize.height += deltaHeight;
    handleSizeChanged();

    if (_tweening == 1)
    {
        if (deltaWidth != 0 && isRightmost && _tweenChange.x < 0)
        {
            _xPos = _overlapSize.width;
            _tweenChange.x = -_xPos - _tweenStart.x;
        }

        if (deltaHeight != 0 && isBottom && _tweenChange.y < 0)
        {
            _yPos = _overlapSize.height;
            _tweenChange.y = -_yPos - _tweenStart.y;
        }
    }
    else if (_tweening == 2)
    {
        if (deltaPosX != 0)
        {
            _container->setPositionX(_container->getPositionX() - deltaPosX);
            _tweenStart.x -= deltaPosX;
            _xPos = -_container->getPositionX();
        }
        if (deltaPosY != 0)
        {
            _container->setPositionY2(_container->getPositionY2() - deltaPosY);
            _tweenStart.y -= deltaPosY;
            _yPos = -_container->getPositionY2();
        }
    }
    else if (_isMouseMoved)
    {
        if (deltaPosX != 0)
        {
            _container->setPositionX(_container->getPositionX() - deltaPosX);
            _containerPos.x -= deltaPosX;
            _xPos = -_container->getPositionX();
        }
        if (deltaPosY != 0)
        {
            _container->setPositionY2(_container->getPositionY2() - deltaPosY);
            _containerPos.y -= deltaPosY;
            _yPos = -_container->getPositionY2();
        }
    }
    else
    {
        if (deltaWidth != 0 && isRightmost)
        {
            _xPos = _overlapSize.width;
            _container->setPositionX(_container->getPositionX() - _xPos);
        }

        if (deltaHeight != 0 && isBottom)
        {
            _yPos = _overlapSize.height;
            _container->setPositionY2(_container->getPositionY2() - _yPos);
        }
    }

    if (_pageMode)
        updatePageController();
    --]]
end

function M:handleSizeChanged()
    if self._displayInDemand == true then
        if self._vtScrollBar then
            if self._contentSize.height <= self._viewSize.height then
                if self._vScrollNone == false then
                    self._vScrollNone = true
                    self._viewSize.width = self._viewSize.width + self._vtScrollBar:getWidth()
                end
            else
                if self._vScrollNone == true then
                    self._vScrollNone = false
                    self._viewSize.width = self._viewSize.width - self._vtScrollBar:getWidth()
                end
            end
        end

        if self._hzScrollBar then
            if self._contentSize.width <= self._viewSize.width then
                if self._hScrollNone == false then
                    self._hScrollNone = true
                    self._viewSize.height = self._viewSize.height + self._hzScrollBar:getHeight()
                end
            else
                if self._hScrollNone == true then
                    self._hScrollNone = false
                    self._viewSize.height = self._viewSize.height - self._hzScrollBar:getHeight()
                end
            end
        end

    end

    if self._vtScrollBar then
        if self._viewSize.height < self._vtScrollBar:getMinSize() then
            self._vtScrollBar:setVisible(false)
        else
            self._vtScrollBar:setVisible(self._scrollBarVisible and self._vScrollNone == false)
            if self._contentSize.height == 0 then
                self._vtScrollBar:setDisplayPerc(0)
            else
                self._vtScrollBar:setDisplayPerc(math.min(1, self._viewSize.height / self._contentSize.height))
            end
        end
    end

    if self._hzScrollBar then
        if self._viewSize.width < self._hzScrollBar:getMinSize() then
            self._hzScrollBar:setVisible(false)
        else
            self._hzScrollBar:setVisible(self._scrollBarVisible and self._hScrollNone == false)
            if self._contentSize.width == 0 then
                self._hzScrollBar:setDisplayPerc(0)
            else
                self._hzScrollBar:setDisplayPerc(math.min(1, self._viewSize.width / self._contentSize.width))
            end
        end
    end

    self._maskContainer:setContentSize(self._viewSize)
    self._maskContainer:setClippingRegion(cc.rect(0, 0, self._viewSize.width, self._viewSize.height))

    if self._vtScrollBar then
        self._vtScrollBar:handlePositionChanged()
    end
    if self._hzScrollBar then
        self._hzScrollBar:handlePositionChanged()
    end
    if self._header then
        self._header:handlePositionChanged()
    end
    if self._footer then
        self._footer:handlePositionChanged()
    end

    if self._scrollType == T.ScrollType.HORIZONTAL or self._scrollType == T.ScrollType.BOTH then
        self._overlapSize.width = math.ceil(math.max(0, self._contentSize.width - self._viewSize.width))
    else
        self._overlapSize.width = 0
    end

    if self._scrollType == T.ScrollType.VERTICAL or self._scrollType == T.ScrollType.BOTH then
        self._overlapSize.height = math.ceil(math.max(0, self._contentSize.height - self._viewSize.height))
    else
        self._overlapSize.height = 0
    end

    self._xPos = math.clamp(self._xPos, 0, self._overlapSize.width)
    self._yPos = math.clamp(self._yPos, 0, self._overlapSize.height)

    local max = sp_getField(self._overlapSize, self._refreshBarAxis)

    if max == 0 then
        local xx = sp_getField(self._contentSize, self._refreshBarAxis) + self._footerLockedSize - sp_getField(self._viewSize, self._refreshBarAxis)
        max = math.max(xx, 0)
    else
        max = max + self._footerLockedSize
    end

    if self._refreshBarAxis == 0 then

        local x = math.clamp(self._container:getPositionX(), -max, self._headerLockedSize)

        local y = math.clamp(self._container:getPositionY2(), -self._overlapSize.height, 0)

        self._container:setPosition2(x, y)
    else
        local x = math.clamp(self._container:getPositionX(), -self._overlapSize.width, 0)

        local y = math.clamp(self._container:getPositionY2(), -max, self._headerLockedSize)

        self._container:setPosition2(x, y)
    end

    if self._header then
        if self._refreshBarAxis == 0 then
            self._header:setHeight(self._viewSize.height)
        else
            self._header:setWidth(self._viewSize.width)
        end
    end

    if self._footer then
        if self._refreshBarAxis == 0 then
            self._footer:setHeight(self._viewSize.height)
        else
            self._footer:setWidth(self._viewSize.width)
        end
    end

    self:syncScrollBar()

    self:checkRefreshBar()

    if self._pageMode == true then
        self:updatePageController()
    end
end

function M:hitTest(pt)
    local target
    if self._vtScrollBar then
        target = self._vtScrollBar:hitTest(pt)
        if target then
            return target
        end
    end

    if self._hzScrollBar then
        target = self._hzScrollBar:hitTest(pt)
        if target then
            return target
        end
    end

    if self._header and self._header:displayObject():getParent() ~= nil then
        target = self._header:hitTest(pt)
        if target then
            return target
        end
    end

    if self._footer and self._footer:displayObject():getParent() ~= nil then
        target = self._footer:hitTest(pt)
        if target then
            return target
        end
    end

    if self._maskContainer:isClippingEnabled() then
        local localPoint = self._maskContainer:convertToNodeSpace(pt)
        if cc.rectContainsPoint(self._maskContainer:getClippingRegion(), localPoint) == true then
            return self._owner
        else
            return nil
        end
    else
        return self._owner
    end
end

function M:posChanged(ani)
    if self._aniFlag == 0 then
        self._aniFlag = (ani == true) and 1 or -1
    elseif self._aniFlag == 1 and ani == false then
        self._aniFlag = -1
    end

    self._needRefresh = true

    CALL_LATER(self, self.refresh)
end

function M:refresh()

    CALL_LATER_CANCEL(self, self.refresh)

    self._needRefresh = false

    if self._pageMode == true or self._snapToItem == true then
        local p = cc.p(-self._xPos, -self._yPos)
        self:alignPosition(p, false)
        self._xPos = -p.x
        self._yPos = -p.y
    end

    self:refresh2()

    self._owner:dispatchEvent(T.UIEventType.Scroll)

    if self._needRefresh == true then
        --pos may change in onScroll
        self._needRefresh = false
        CALL_LATER_CANCEL(self, self.refresh)

        self:refresh2()
    end

    self:syncScrollBar()

    self._aniFlag = 0

end

function M:refresh2()
    if self._aniFlag == 1 and self._isMouseMoved == false then
        local pos = cc.p(0, 0)
        if self._overlapSize.width > 0 then
            pos.x = checkint(-self._xPos)
        else
            if self._container:getPositionX() ~= 0 then
                self._container:setPositionX(0)
            end
            pos.x = 0
        end

        if self._overlapSize.height > 0 then
            pos.y = checkint(-self._yPos)
        else
            if self._container:getPositionY2() ~= 0 then
                self._container:setPositionY2(0)
            end
            pos.y = 0
        end

        if pos.x ~= self._container:getPositionX() or pos.y ~= self._container:getPositionY2() then
            self._tweening = 1
            self._tweenTime = cc.p(0, 0)
            self._tweenDuration = cc.p(TWEEN_TIME_GO, TWEEN_TIME_GO)
            self._tweenStart = self._container:getPosition2()
            self._tweenChange = cc.pSub(pos, self._tweenStart);
            self._maskContainer:unscheduleUpdate()
            self._maskContainer:scheduleUpdateWithPriorityLua(handler(self, self.tweenUpdate), 0)
        elseif (self._tweening ~= 0) then
            self:killTween()
        end
    else
        if self._tweening ~= 0 then
            self:killTween()
        end

        self._container:setPosition2(cc.p(checkint(-self._xPos), checkint(-self._yPos)))

        self:loopCheckingCurrent()
    end

    if self._pageMode == true then
        self:updatePageController()
    end
end

function M:syncScrollBar(ended)
    if self._vtScrollBar then
        local xx = math.clamp(-self._container:getPositionY2(), 0, self._overlapSize.height) / self._overlapSize.height
        self._vtScrollBar:setScrollPerc(self._overlapSize.height == 0 and 0 or xx)
        if self._scrollBarDisplayAuto == true then
            self:showScrollBar(ended == false)
        end
    end

    if self._hzScrollBar then
        local xx = math.clamp(-self._container:getPositionX(), 0, self._overlapSize.width) / self._overlapSize.width
        self._hzScrollBar:setScrollPerc(self._overlapSize.width == 0 and 0 or xx)
        if self._scrollBarDisplayAuto == true then
            self:showScrollBar(not ended)
        end
    end
end

function M:showScrollBar(show)
    self._scrollBarVisible = show and self._viewSize.width > 0 and self._viewSize.height > 0

    if show == true then
        self:onShowScrollBar()
        CALL_LATER_CANCEL(self, self.onShowScrollBar);
    else
        CALL_LATER(self, self.onShowScrollBar, 0.5)
    end
end

function M:onShowScrollBar()
    if self._vtScrollBar then
        self._vtScrollBar:setVisible(self._scrollBarVisible and self._vScrollNone == false)
    end
    if self._hzScrollBar then
        self._hzScrollBar:setVisible(self._scrollBarVisible and self._vScrollNone == false)
    end
end

function M:getLoopPartSize(division, axis)
    return (sp_getField(self._contentSize, axis) + (axis == 0 and self._owner:getColumnGap() or self._owner:getLineGap())) / division;
end

function M:loopCheckingCurrent()
    local changed = false;
    if (self._loop == 1 and self._overlapSize.width > 0) then
        if (self._xPos < 0.001) then
            self._xPos = self._xPos + self:getLoopPartSize(2, 0);
            changed = true;
        elseif (self._xPos >= self._overlapSize.width) then
            self._xPos = self._xPos - self:getLoopPartSize(2, 0);
            changed = true;
        end
    elseif (self._loop == 2 and self._overlapSize.height > 0) then
        if (self._yPos < 0.001) then
            self._yPos = self._yPos + self:getLoopPartSize(2, 1);
            changed = true;
        elseif (self._yPos >= self._overlapSize.height) then
            self._yPos = self._yPos - self:getLoopPartSize(2, 1);
            changed = true;
        end
    end

    if (changed) then
        self._container:setPosition2(cc.p(checkint(-self._xPos), checkint(-self._yPos)));

    end

    return changed;
end

function M:loopCheckingTarget(endPos, axis)
    if axis == nil then
        if self._loop == 1 then
            axis = 0
        end

        if self._loop == 2 then
            axis = 1
        end
    end

    if axis == nil then
        return
    end

    if sp_getField(endPos, axis) > 0 then
        local halfSize = self:getLoopPartSize(2, axis)
        local tmp = sp_getField(self._tweenStart, axis) - halfSize
        if tmp <= 0 and tmp >= -sp_getField(self._overlapSize, axis) then
            sp_incField(endPos, axis, -halfSize)
            sp_setField(self._tweenStart, axis, tmp)
        end
    elseif (sp_getField(endPos, axis) < -sp_getField(self._overlapSize, axis)) then
        local halfSize = self:getLoopPartSize(2, axis)
        local tmp = sp_getField(self._tweenStart, axis) + halfSize
        if tmp <= 0 and tmp >= -sp_getField(self._overlapSize, axis) then
            sp_incField(endPos, axis, halfSize)
            sp_setField(self._tweenStart, axis, tmp)
        end
    end

end

function M:loopCheckingNewPos(value, axis)
    local overlapSize = sp_getField(self._overlapSize, axis);
    if (overlapSize == 0) then
        return value;
    end

    local pos = axis == 0 and self._xPos or self._yPos;
    local changed = false;
    if (value < 0.001) then
        value = value + self:getLoopPartSize(2, axis);
        if (value > pos) then
            local v = self:getLoopPartSize(6, axis);
            v = math.ceil((value - pos) / v) * v;
            pos = math.clamp(pos + v, 0, overlapSize);
            changed = true;
        end
    elseif (value >= overlapSize) then
        value = value - self:getLoopPartSize(2, axis);
        if (value < pos) then
            local v = self:getLoopPartSize(6, axis);
            v = math.ceil((pos - value) / v) * v;
            pos = math.clamp(pos - v, 0, overlapSize);
            changed = true;
        end
    end

    if (changed) then
        if (axis == 0) then
            self._container:setPositionX(-checkint(pos));
        else
            self._container:setPositionY2(-checkint(pos));
        end
    end

    return value
end

function M:alignPosition(pos, inertialScrolling)
    if (self._pageMode) then
        pos.x = self:alignByPage(pos.x, 0, inertialScrolling);
        pos.y = self:alignByPage(pos.y, 1, inertialScrolling);
    elseif (self._snapToItem) then
        local tmp = cc.p(-pos.x, -pos.y)
        tmp = self._owner:getSnappingPosition(tmp);
        if (pos.x < 0 and pos.x > -self._overlapSize.width) then
            pos.x = -tmp.x;
        end
        if (pos.y < 0 and pos.y > -self._overlapSize.height) then
            pos.y = -tmp.y;
        end
    end
end

function M:alignByPage(pos, axis, inertialScrolling)
    local page;
    local pageSize = sp_getField(self._pageSize, axis);
    local overlapSize = sp_getField(self._overlapSize, axis);
    local contentSize = sp_getField(self._contentSize, axis);

    if (pos > 0) then
        page = 0;
    elseif (pos < -overlapSize) then
        page = math.ceil(contentSize / pageSize) - 1;
    else
        page = math.floor(-pos / pageSize);
        local change = inertialScrolling and (pos - sp_getField(self._containerPos, axis)) or (pos - sp_getField(self._container:getPosition2(), axis));
        local testPageSize = math.min(pageSize, contentSize - (page + 1) * pageSize);
        local delta = -pos - page * pageSize;

        if (math.abs(change) > pageSize) then
            if (delta > testPageSize * 0.5) then
                page = page + 1;
            end
        else
            if (delta > testPageSize * (change < 0 and 0.3 or 0.7)) then
                page = page + 1;
            end
        end

        pos = -page * pageSize;
        if (pos < -overlapSize) then
            pos = -overlapSize;
        end
    end

    if (inertialScrolling) then
        local oldPos = sp_getField(self._tweenStart, axis);
        local oldPage;

        if (oldPos > 0) then
            oldPage = 0;
        elseif (oldPos < -overlapSize) then
            oldPage = math.ceil(contentSize / pageSize) - 1;
        else
            oldPage = math.floor(-oldPos / pageSize);
        end

        local startPage = math.floor(-sp_getField(self._containerPos, axis) / pageSize);

        if (math.abs(page - startPage) > 1 and math.abs(oldPage - startPage) <= 1) then
            if (page > startPage) then
                page = startPage + 1;
            else
                page = startPage - 1;
            end
            pos = -page * pageSize;
        end
    end

    return pos;
end

function M:updateTargetAndDuration(pos, axis)
    if type(pos) == "table" then
        local ret = cc.p(0, 0)
        ret.x = self:updateTargetAndDuration(pos.x, 0)
        ret.y = self:updateTargetAndDuration(pos.y, 1)
        return ret
    end

    local v = sp_getField(self._velocity, axis)
    local duration = 0

    if pos > 0 then
        pos = 0
    elseif pos < -sp_getField(self._overlapSize, axis) then
        pos = -sp_getField(self._overlapSize, axis)
    else
        local v2 = math.abs(v) * self._velocityScale
        local ratio = 0

        local winSize = cc.Director:getInstance():getWinSizeInPixels()
        v2 = v2 * (1136 / (math.max(winSize.width, winSize.height)))

        if self._pageMode == true then
            if (v2 > 500) then
                ratio = math.pow((v2 - 500) / 500, 2)
            end
        else
            if (v2 > 1000) then
                ratio = math.pow((v2 - 1000) / 1000, 2)
            end
        end

        if ratio ~= 0 then
            if ratio > 1 then
                ratio = 1
            end

            v2 = v2 * ratio
            v = v * ratio

            sp_setField(self._velocity, axis, v)

            duration = math.log(60 / v2) / math.log(self._decelerationRate) / 60
            local change = checkint(v * duration * 0.4)
            pos = pos + change

        end

    end

    if duration < TWEEN_TIME_DEFAULT then
        duration = TWEEN_TIME_DEFAULT
    end

    sp_setField(self._tweenDuration, axis, duration)

    return pos
end

function M:fixDuration(axis, oldChange)
    local tweenChange = sp_getField(self._tweenChange, axis);
    if (tweenChange == 0 or math.abs(tweenChange) >= math.abs(oldChange)) then
        return ;
    end

    local newDuration = math.abs(tweenChange / oldChange) * sp_getField(self._tweenDuration, axis);
    if (newDuration < TWEEN_TIME_DEFAULT) then
        newDuration = TWEEN_TIME_DEFAULT;
    end

    sp_setField(self._tweenDuration, axis, newDuration);

end

function M:killTween()
    if self._tweening == 1 then
        local t = cc.pAdd(self._tweenStart, self._tweenChange)
        self._container:setPosition2(t)
        self._owner:dispatchEvent(T.UIEventType.Scroll)
    end

    self._tweening = 0
    self._maskContainer:unscheduleUpdate()
    self._owner:dispatchEvent(T.UIEventType.ScrollEnd)
end

function M:checkRefreshBar()

    if self._header == nil and self._footer == nil then
        return
    end

    local pos = sp_getField(self._container:getPosition2(), self._refreshBarAxis)

    if self._header then
        if pos > 0 then
            self._header:setVisible(true)
            local x = clone(self._header:getSize())
            sp_setField(x, self._refreshBarAxis, pos)
            self._header:setSize(x.width, x.height)
        else
            self._header:setVisible(false)
        end
    end

    if self._footer then
        local max = sp_getField(self._overlapSize, self._refreshBarAxis)
        if pos < -max or (max == 0 and self._footerLockedSize > 0) then
            self._footer:setVisible(true)

            local vec = clone(self._footer:getPosition())
            if max > 0 then
                sp_setField(vec, self._refreshBarAxis, pos + sp_getField(self._contentSize, self._refreshBarAxis))
            else
                local min = math.min(pos + sp_getField(self._viewSize, self._refreshBarAxis),
                        sp_getField(self._viewSize, self._refreshBarAxis) - self._footerLockedSize)
                local max = math.max(min, sp_getField(self._viewSize, self._refreshBarAxis) - sp_getField(self._contentSize, self._refreshBarAxis))
                sp_setField(vec, self._refreshBarAxis, max)
            end
            self._footer:setPosition(vec.x, vec.y)

            local size = clone(self._footer:getSize())
            if max > 0 then
                sp_setField(size, self._refreshBarAxis, -max - pos)
            else
                sp_setField(size, self._refreshBarAxis, sp_getField(self._viewSize, self._refreshBarAxis) - sp_getField(self._footer:getPosition(), self._refreshBarAxis))
            end
            self._footer:setSize(size.width, size.height)
        else
            self._footer:setVisible(false)
        end
    end
end

function M:tweenUpdate(dt)

    local nx = self:runTween(0, dt)
    local ny = self:runTween(1, dt)

    self._container:setPosition2(nx, ny)

    if self._tweening == 2 then
        if self._overlapSize.width > 0 then
            self._xPos = math.clamp(-nx, 0, self._overlapSize.width)
        end

        if self._overlapSize.height > 0 then
            self._yPos = math.clamp(-ny, 0, self._overlapSize.height)
        end

        if self._pageMode == true then
            self:updatePageController()
        end
    end

    if (self._tweenChange.x == 0 and self._tweenChange.y == 0) then
        self._tweening = 0
        self._maskContainer:unscheduleUpdate()

        self:loopCheckingCurrent()

        self:syncScrollBar(true)
        self:checkRefreshBar()
        self._owner:dispatchEvent(T.UIEventType.Scroll)
        self._owner:dispatchEvent(T.UIEventType.ScrollEnd)
    else
        self:syncScrollBar(false)
        self:checkRefreshBar()
        self._owner:dispatchEvent(T.UIEventType.Scroll)
    end
end

function M:runTween(axis, dt)
    local newValue
    if sp_getField(self._tweenChange, axis) ~= 0 then
        sp_incField(self._tweenTime, axis, dt)
        if sp_getField(self._tweenTime, axis) >= sp_getField(self._tweenDuration, axis) then
            newValue = sp_getField(self._tweenStart, axis) + sp_getField(self._tweenChange, axis)
            sp_setField(self._tweenChange, axis, 0)
        else
            local ratio = sp_EaseFunc(
                    sp_getField(self._tweenTime, axis),
                    sp_getField(self._tweenDuration, axis))

            local a = sp_getField(self._tweenStart, axis)
            local b = checkint(sp_getField(self._tweenChange, axis) * ratio)
            newValue = a + b
        end

        local threshold1 = 0
        local threshold2 = -sp_getField(self._overlapSize, axis)

        if self._headerLockedSize > 0 and self._refreshBarAxis == axis then
            threshold1 = self._headerLockedSize
        end

        if self._footerLockedSize > 0 and self._refreshBarAxis == axis then
            local max = sp_getField(self._overlapSize, self._refreshBarAxis)
            if max == 0 then
                local xx = sp_getField(self._contentSize, self._refreshBarAxis) + self._footerLockedSize - sp_getField(self._viewSize, self._refreshBarAxis)
                max = math.max(xx, 0)
            else
                max = max + self._footerLockedSize
            end

            threshold2 = -max
        end

        if self._tweening == 2 and self._bouncebackEffect == true then

            if ((newValue > 20 + threshold1) and sp_getField(self._tweenChange, axis) > 0)
                    or ((newValue > threshold1) and sp_getField(self._tweenChange, axis) == 0) then
                sp_setField(self._tweenTime, axis, 0);
                sp_setField(self._tweenDuration, axis, TWEEN_TIME_DEFAULT);
                sp_setField(self._tweenChange, axis, -newValue + threshold1);
                sp_setField(self._tweenStart, axis, newValue);
            elseif ((newValue < threshold2 - 20) and sp_getField(self._tweenChange, axis) < 0)
                    or ((newValue < threshold2) and sp_getField(self._tweenChange, axis) == 0) then
                sp_setField(self._tweenTime, axis, 0);
                sp_setField(self._tweenDuration, axis, TWEEN_TIME_DEFAULT);
                sp_setField(self._tweenChange, axis, threshold2 - newValue);
                sp_setField(self._tweenStart, axis, newValue);
            end
        else
            if (newValue > threshold1) then
                newValue = threshold1
                sp_setField(self._tweenChange, axis, 0)
            elseif (newValue < threshold2) then
                newValue = threshold2
                sp_setField(self._tweenChange, axis, 0)
            end
        end

    else
        newValue = sp_getField(self._container:getPosition2(), axis)
    end
    --if isnan(newValue) then
    --    newValue = 0
    --end
    return newValue
end

function M:onTouchBegin(context)
    if self._touchEffect == false then
        return
    end

    context:captureTouch()

    local evt = context:getInput()
    local pt_global = evt:getPosition()
    local pt = self._owner:globalToLocal(evt:getPosition())

    if self._tweening ~= 0 then
        self:killTween()
        evt:getProcessor():cancelClick(evt:getTouchId())
        self._isMouseMoved = true
    else
        self._isMouseMoved = false
    end

    self._containerPos = self._container:getPosition2()
    self._beginTouchPos = clone(pt)
    self._lastTouchPos = clone(pt)
    self._lastTouchGlobalPos = clone(pt_global)
    self._isHoldAreaDone = false
    self._velocity = cc.p(0, 0)
    self._velocityScale = 1
    self._lastMoveTime = ToolSet.getCurrentTime()
end

function M:onTouchMove(context)
    --print("ScrollPane onTouchMove(context)")

    if self._touchEffect == false then
        return
    end

    if (__draggingPane ~= nil and __draggingPane ~= self) or GObject.getDraggingObject() ~= nil then
        return
    end

    local evt = context:getInput()
    local pt_global = clone(evt:getPosition())
    local pt = self._owner:globalToLocal(evt:getPosition())

    local sensitivity = UIConfig.touchScrollSensitivity
    local diff
    local sv = false
    local sh = false

    if self._scrollType == T.ScrollType.VERTICAL then
        if self._isHoldAreaDone == false then

            --表示正在监测垂直方向的手势
            __gestureFlag = bit.bor(__gestureFlag, 1)

            diff = math.abs(self._beginTouchPos.y - pt.y)

            if diff < sensitivity then
                return
            end

            if bit.band(__gestureFlag, 2) ~= 0 then
                --已经有水平方向的手势在监测，那么我们用严格的方式检查是不是按垂直方向移动，避免冲突
                local diff2 = math.abs(self._beginTouchPos.x - pt.x)
                if diff < diff2 then
                    --不通过则不允许滚动了
                    return
                end
            end

        end

        sv = true
    elseif self._scrollType == T.ScrollType.HORIZONTAL then
        if self._isHoldAreaDone == false then
            __gestureFlag = bit.bor(__gestureFlag, 2)

            diff = math.abs(self._beginTouchPos.x - pt.x)

            if diff < sensitivity then
                return
            end

            if bit.band(__gestureFlag, 1) ~= 0 then
                local diff2 = math.abs(self._beginTouchPos.y - pt.y)
                if diff < diff2 then
                    return
                end
            end

        end

        sh = true
    else
        __gestureFlag = 3
        if self._isHoldAreaDone ~= false then
            diff = math.abs(self._beginTouchPos.y - pt.y)
            if diff < sensitivity then
                diff = math.abs(self._beginTouchPos.x - pt.x);
                return
            end
        end

        sv = true
        sh = true
    end

    local newPos = cc.pSub(cc.pAdd(self._containerPos, pt), self._beginTouchPos)
    newPos.x = checkint(newPos.x)
    newPos.y = checkint(newPos.y)

    if sv == true then
        if newPos.y > 0 then
            if self._bouncebackEffect == false then
                self._container:setPositionY2(0)
            elseif self._header and self._header.maxSize.height ~= 0 then
                self._container:setPositionY2(
                        checkint(math.min(
                                newPos.y * 0.5,
                                self._header.maxSize.height))
                )
            else
                self._container:setPositionY2(
                        checkint(math.min(
                                newPos.y * 0.5,
                                self._viewSize.height * PULL_RATIO))
                )
            end
        elseif newPos.y < -self._overlapSize.height then
            if self._bouncebackEffect == false then
                self._container:setPositionY2(-self._overlapSize.height)
            elseif self._footer and self._footer.maxSize.height > 0 then
                local xx = checkint(math.max(
                        (newPos.y + self._overlapSize.height) * 0.5,
                        self._footer.maxSize.height
                ))
                self._container:setPositionY2(xx - self._overlapSize.height)
            else
                local xx = checkint(math.max(
                        (newPos.y + self._overlapSize.height) * 0.5,
                        -self._viewSize.height * PULL_RATIO
                ))
                self._container:setPositionY2(xx - self._overlapSize.height)
            end
        else
            self._container:setPositionY2(newPos.y)
        end
    end

    if sh == true then
        if newPos.x > 0 then
            if self._bouncebackEffect == false then
                self._container:setPositionX(0)
            elseif self._header and self._header.maxSize.width ~= 0 then
                self._container:setPositionX(
                        checkint(math.min(
                                newPos.x * 0.5,
                                self._header.maxSize.width))
                )
            else
                self._container:setPositionX(
                        checkint(math.min(
                                newPos.x * 0.5,
                                self._viewSize.width * PULL_RATIO))
                )
            end
        elseif newPos.x < -self._overlapSize.width then
            if self._bouncebackEffect == false then
                self._container:setPositionX(-self._overlapSize.width)
            elseif self._footer and self._footer.maxSize.width > 0 then
                local xx = checkint(math.max(
                        (newPos.x + self._overlapSize.width) * 0.5,
                        self._footer.maxSize.width
                ))
                self._container:setPositionX(xx - self._overlapSize.width)
            else
                local xx = checkint(math.max(
                        (newPos.x + self._overlapSize.width) * 0.5,
                        -self._viewSize.width * PULL_RATIO
                ))
                self._container:setPositionX(xx - self._overlapSize.width)
            end
        else
            self._container:setPositionX(newPos.x)
        end
    end


    --更新速度
    local deltaTime = cc.Director:getInstance():getDeltaTime()

    local elapsed = ToolSet.getCurrentTime() - self._lastMoveTime

    elapsed = elapsed * 60 - 1

    if elapsed > 1 then
        -- 速度衰减
        self._velocity = cc.pMul(self._velocity, math.pow(0.833, elapsed))
    end

    local deltaPosition = cc.pSub(pt, self._lastTouchPos)
    if sh == false then
        deltaPosition.x = 0
    end
    if sv == false then
        deltaPosition.y = 0
    end

    local p = cc.pMul(deltaPosition, 1 / deltaTime)
    self._velocity = cc.pLerp(self._velocity, p, deltaTime * 10)

    --速度计算使用的是本地位移，但在后续的惯性滚动判断中需要用到屏幕位移，所以这里要记录一个位移的比例。
    local deltaGlobalPosition = cc.pSub(self._lastTouchGlobalPos, pt_global)
    if deltaPosition.x ~= 0 then
        self._velocityScale = math.abs(deltaGlobalPosition.x / deltaPosition.x)
    elseif deltaPosition.y ~= 0 then
        self._velocityScale = math.abs(deltaGlobalPosition.y / deltaPosition.y)
    end

    self._lastTouchPos = clone(pt)
    self._lastTouchGlobalPos = clone(pt_global)
    self._lastMoveTime = ToolSet.getCurrentTime()

    --同步更新pos值
    if self._overlapSize.width > 0 then
        self._xPos = math.clamp(-self._container:getPositionX(), 0, self._overlapSize.width)
    end

    if self._overlapSize.height > 0 then
        self._yPos = math.clamp(-self._container:getPositionY2(), 0, self._overlapSize.height)
    end

    --循环滚动特别检查
    if self._loop ~= 0 then
        newPos = self._container:getPosition2()
        if self:loopCheckingCurrent() == true then
            local ppp = cc.pSub(self._container:getPosition2(), newPos)
            self._containerPos = cc.pAdd(self._containerPos, ppp)
        end
    end

    __draggingPane = self
    self._isHoldAreaDone = true
    self._isMouseMoved = true

    self:syncScrollBar()
    self:checkRefreshBar()

    if self._pageMode == true then
        self:updatePageController()
    end

    self._owner:dispatchEvent(T.UIEventType.Scroll)

end

function M:onTouchEnd(context)

    if __draggingPane == self then
        __draggingPane = nil
    end

    __gestureFlag = 0

    if self._isMouseMoved == false or self._touchEffect == false then
        self._isMouseMoved = false
        return
    end

    self._isMouseMoved = false
    self._tweenStart = self._container:getPosition2()

    local endPos = clone(self._tweenStart)
    local flag = false
    if self._container:getPositionX() > 0 then
        endPos.x = 0
        flag = true
    elseif self._container:getPositionX() < -self._overlapSize.width then
        endPos.x = -self._overlapSize.width
        flag = true
    end

    if self._container:getPositionY2() > 0 then
        endPos.y = 0
        flag = true
    elseif self._container:getPositionY2() < -self._overlapSize.height then
        endPos.y = -self._overlapSize.height
        flag = true
    end

    if flag == true then
        self._tweenChange = cc.pSub(endPos, self._tweenStart)

        if self._tweenChange.x < -UIConfig.touchDragSensitivity or self._tweenChange.y < -UIConfig.touchDragSensitivity then
            self._owner:dispatchEvent(T.UIEventType.PullDownRelease)
        elseif self._tweenChange.x > UIConfig.touchDragSensitivity or self._tweenChange.y > UIConfig.touchDragSensitivity then
            self._owner:dispatchEvent(T.UIEventType.PullUpRelease)
        end

        if self._headerLockedSize > 0 and sp_getField(endPos, self._refreshBarAxis) == 0 then
            sp_setField(endPos, self._refreshBarAxis, self._headerLockedSize)
            self._tweenChange = cc.pSub(endPos, self._tweenStart)
        elseif self._footerLockedSize > 0 and (sp_getField(endPos, self._refreshBarAxis) == -sp_getField(self._overlapSize, self._refreshBarAxis)) then
            local max = sp_getField(self._overlapSize, self._refreshBarAxis)
            if max == 0 then
                local xx = sp_getField(self._contentSize, self._refreshBarAxis) + self._footerLockedSize - sp_getField(self._viewSize, self._refreshBarAxis)
                max = math.max(xx, 0)
            else
                max = max + self._footerLockedSize
            end

            sp_setField(endPos, self._refreshBarAxis, -max)
            self._tweenChange = cc.pSub(endPos, self._tweenStart)
        end

        self._tweenDuration = cc.p(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT)
    else
        if self._inertiaDisabled == false then
            local elapsed = ToolSet.getCurrentTime() - self._lastMoveTime
            elapsed = elapsed * 60 - 1
            if elapsed > 1 then
                self._velocity = cc.pMul(self._velocity, math.pow(0.833, elapsed))
            end

            endPos = self:updateTargetAndDuration(self._tweenStart)
        else
            self._tweenDuration = cc.p(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT)
        end

        local oldChange = cc.pSub(endPos, self._tweenStart)
        self:loopCheckingTarget(endPos)

        if self._pageMode == true or self._snapToItem == true then
            self:alignPosition(endPos, true)
        end

        self._tweenChange = cc.pSub(endPos, self._tweenStart)

        if self._tweenChange.x == 0 and self._tweenChange.y == 0 then
            return
        end

        if self._pageMode == true or self._snapToItem == true then
            self:fixDuration(0, oldChange.x)
            self:fixDuration(1, oldChange.y)
        end

    end

    self._tweening = 2
    self._tweenTime = cc.p(0, 0)

    self._maskContainer:unscheduleUpdate()
    self._maskContainer:scheduleUpdateWithPriorityLua(handler(self, self.tweenUpdate), 0)
end

function M:onMouseWheel(context)
    print("ScrollPane onMouseWheel(context)")
    --[[
    if (!_mouseWheelEnabled)
        return;

    InputEvent* evt = context->getInput();
    int delta = evt->getMouseWheelDelta();
    delta = delta > 0 ? 1 : -1;
    if (_overlapSize.width > 0 && _overlapSize.height == 0)
    {
        if (_pageMode)
            setPosX(_xPos + _pageSize.width * delta, false);
        else
            setPosX(_xPos + _mouseWheelStep * delta, false);
    }
    else
    {
        if (_pageMode)
            setPosY(_yPos + _pageSize.height * delta, false);
        else
            setPosY(_yPos + _mouseWheelStep * delta, false);
    }
    --]]
end

function M:onRollOver(context)
    self:showScrollBar(true)
end

function M:onRollOut(context)
    self:showScrollBar(false)
end

return M
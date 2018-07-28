local GComponent = require("app.fui.GComponent")

---@class GScrollBar:GComponent
local M = class("GScrollBar", GComponent)

function M:ctor()
    M.super.ctor(self)

    self._grip = nil
    self._arrowButton1 = nil
    self._arrowButton2 = nil
    self._bar = nil
    self._target = nil
    self._vertical = false
    self._scrollPerc = 0
    self._fixedGripSize = false

    self._dragOffset = cc.p(0, 0)

end

function M:setScrollPane(target, vertical)
    self._target = target
    self._vertical = vertical
end

function M:setDisplayPerc(value)
    if self._vertical == true then
        if self._fixedGripSize == false then
            self._grip:setHeight(value * self._bar:getHeight())
        end
        self._grip:setY(math.round(self._bar:getY() + self._scrollPerc * (self._bar:getHeight() - self._grip:getHeight())))
    else
        if self._fixedGripSize == false then
            self._grip:setWidth(value * self._bar:getWidth())
        end
        self._grip:setX(math.round(self._bar:getX() + self._scrollPerc * (self._bar:getWidth() - self._grip:getWidth())))
    end
end

function M:setScrollPerc(value)
    self._scrollPerc = value
    if self._vertical == true then
        self._grip:setY(math.round(self._bar:getY() + self._scrollPerc * (self._bar:getHeight() - self._grip:getHeight())))
    else
        self._grip:setX(math.round(self._bar:getX() + self._scrollPerc * (self._bar:getWidth() - self._grip:getWidth())))
    end
end

function M:getMinSize()
    if self._vertical == true then
        local h1 = 0
        if self._arrowButton1 then
            h1 = self._arrowButton1:getHeight()
        end

        local h2 = 0
        if self._arrowButton2 then
            h2 = self._arrowButton2:getHeight()
        end

        return h1 + h2
    else
        local h1 = 0
        if self._arrowButton1 then
            h1 = self._arrowButton1:getWidth()
        end

        local h2 = 0
        if self._arrowButton2 then
            h2 = self._arrowButton2:getWidth()
        end

        return h1 + h2
    end
end

function M:constructFromXML(xml)
    xml = xml.ScrollBar
    if xml then
        self._fixedGripSize = (xml["@fixedGripSize"] == "true")
    end

    self._grip = self:getChild("grip")
    self._bar = self:getChild("bar")

    self._arrowButton1 = self:getChild("arrow1")
    self._arrowButton2 = self:getChild("arrow2")

    self._grip:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onGripTouchBegin))
    self._grip:addEventListener(T.UIEventType.TouchMove, handler(self, self.onGripTouchMove))
    self:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onTouchBegin))

    if self._arrowButton1 then
        self._arrowButton1:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onArrowButton1Click))
    end

    if self._arrowButton2 then
        self._arrowButton2:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onArrowButton2Click))
    end

end

---@param context EventContext
function M:onTouchBegin(context)
    context:stopPropagation()
    local evt = context:getInput()
    local pt = self._grip:globalToLocal(evt:getPosition())
    if self._vertical == true then
        if pt.y < 0 then
            self._target:scrollUp(4, false)
        else
            self._target:scrollDown(4, false)
        end
    else
        if pt.x < 0 then
            self._target:scrollLeft(4, false)
        else
            self._target:scrollRight(4, false)
        end
    end
end

---@param context EventContext
function M:onGripTouchBegin(context)
    if self._bar == nil then
        return
    end

    context:stopPropagation()
    context:captureTouch()

    local p1 = context:getInput():getPosition()
    local p2 = self._grip:getPosition()
    self._dragOffset = self:globalToLocal(cc.pSub(p1, p2))
end

---@param context EventContext
function M:onGripTouchMove(context)
    local pt = self:globalToLocal(context:getInput():getPosition())
    if self._vertical == true then
        local curY = pt.y - self._dragOffset.y
        local diff = self._bar:getHeight() - self._grip:getHeight()
        if diff == 0 then
            self._target:setPercY(0)
        else
            self._target:setPercY((curY - self._bar:getY()) / diff)
        end
    else
        local curX = pt.x - self._dragOffset.x
        local diff = self._bar:getWidth() - self._grip:getWidth()
        if diff == 0 then
            self._target:setPercX(0)
        else
            self._target:setPercX((curX - self._bar:getX()) / diff)
        end
    end
end

---@param context EventContext
function M:onArrowButton1Click(context)
    context:stopPropagation()
    if self._vertical == true then
        self._target:scrollUp()
    else
        self._target:scrollLeft()
    end
end

---@param context EventContext
function M:onArrowButton2Click(context)
    context:stopPropagation()
    if self._vertical == true then
        self._target:scrollDown()
    else
        self._target:scrollRight()
    end
end


return M
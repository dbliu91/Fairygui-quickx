local GComponent = require("app.fui.GComponent")

---@class GSlider:GComponent
local M = class("GSlider", GComponent)

function M:ctor()

    M.super.ctor(self)

    self._max = 100
    self._value = 0
    self._titleType = T.ProgressTitleType.PERCENT
    self._reverse = false
    self._titleObject = nil
    self._barObjectH = nil
    self._barObjectV = nil

    self._barMaxWidth = 0
    self._barMaxHeight = 0
    self._barMaxWidthDelta = 0
    self._barMaxHeightDelta = 0

    self._gripObject = nil
    self._clickPos = cc.p(0, 0)
    self._clickPercent = 0
    self._barStartX = 0
    self._barStartY = 0

    self.changeOnClick = false
    self.canDrag = false

end

function M:getTitleType()
    return self._titleType
end

function M:getTitleType(value)
    if self._titleType ~= value then
        self._titleType = value
        self:update()
    end
end

function M:getMax()
    return self._max
end

function M:getMax(value)
    if self._max ~= value then
        self._max = value
        self:update()
    end
end

function M:getValue()
    return self._value
end

function M:setValue(value)
    if self._value ~= value then
        self._value = value
        self:update()
    end
end

function M:update()
    local percent = math.min(self._value / self._max, 1)
    self:updateWidthPercent(percent)
end

function M:updateWidthPercent(percent)
    if self._titleObject then
        local oss
        if self._titleType == T.ProgressTitleType.PERCENT then
            oss = string.format("%d%%", checkint(percent * 100))
        elseif self._titleType == T.ProgressTitleType.VALUE_MAX then
            oss = string.format("%d/%d", checkint(self._value), checkint(self._max))
        elseif self._titleType == T.ProgressTitleType.VALUE then
            oss = string.format("%d", checkint(checkint(self._value)))
        elseif self._titleType == T.ProgressTitleType.MAX then
            oss = string.format("%d", checkint(checkint(self._max)))
        end
        self._titleObject:setText(oss)
    end

    local fullWidth = self:getWidth() - self._barMaxWidthDelta
    local fullHeight = self:getHeight() - self._barMaxHeightDelta

    if self._reverse == false then
        if self._barObjectH then
            self._barObjectH:setWidth(math.round(fullWidth * percent))
        end
        if self._barObjectV then
            self._barObjectV:setHeight(math.round(fullHeight * percent))
        end
    else
        if self._barObjectH then
            self._barObjectH:setWidth(math.round(fullWidth * percent))
            self._barObjectH:setX(self._barStartX + (fullWidth - self._barObjectH:getWidth()))
        end
        if self._barObjectV then
            self._barObjectV:setHeight(math.round(fullHeight * percent))
            self._barObjectV:setY(self._barStartY + (fullHeight - self._barObjectV:getHeight()))
        end
    end

end

function M:handleSizeChanged()
    M.super.handleSizeChanged(self)

    if self._barObjectH then
        self._barMaxWidth = self:getWidth() - self._barMaxWidthDelta
    end

    if self._barObjectV then
        self._barMaxHeight = self:getHeight() - self._barMaxHeightDelta
    end

    if self._underConstruct == false then
        self:update()
    end
end

function M:constructFromXML(xml)
    xml = xml.Slider

    if not xml then
        return
    end

    local p

    p = xml["@titleType"]
    if p then
        self._titleType = p
    end

    self._reverse = (xml["reverse"] == "true")

    self._titleObject = self:getChild("title")
    self._barObjectH = self:getChild("bar")
    self._barObjectV = self:getChild("bar_v")
    self._gripObject = self:getChild("grip")

    if self._barObjectH then
        self._barMaxWidth = self._barObjectH:getWidth()
        self._barMaxWidthDelta = self:getWidth() - self._barMaxWidth
        self._barStartX = self._barObjectH:getX()
    end

    if self._barObjectV then
        self._barMaxHeight = self._barObjectV:getHeight()
        self._barMaxHeightDelta = self:getHeight() - self._barMaxHeight
        self._barStartY = self._barObjectV:getY()
    end

    if self._gripObject then
        self._gripObject:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onGripTouchBegin), self)
        self._gripObject:addEventListener(T.UIEventType.TouchMove, handler(self, self.onGripTouchMove), self)
    end

    self:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onTouchBegin), self)

end

function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self, xml)

    xml = xml.Slider
    if xml then
        local p = xml["@value"]
        if p then
            self._value = checkint(p)
        end

        p = xml["@max"]
        if p then
            self._max = checkint(p)
        end
    end

    self:update()
end

---@param context EventContext
function M:onTouchBegin(context)
    if self.changeOnClick == false then
        return
    end

    local evt = context:getInput()

    local pt = self._gripObject:globalToLocal(evt:getPosition())
    local percent = self._value / self._max

    local delta = 0

    if self._barObjectH then
        delta = (pt.x - self._gripObject:getWidth() / 2) / self._barMaxWidth
    end

    if self._barObjectV then
        delta = (pt.y - self._gripObject:getHeight() / 2) / self._barMaxHeight
    end

    if self._reverse == true then
        percent = percent - delta
    else
        percent = percent + delta
    end

    percent = math.clamp(percent, 0, 1)

    local newValue = percent * self._max
    if newValue ~= self._value then
        self._value = newValue
        self:dispatchEvent(T.UIEventType.Changed)
    end

    self:updateWidthPercent(percent)
end

---@param context EventContext
function M:onGripTouchBegin(context)
    self.canDrag = true
    context:stopPropagation()
    context:captureTouch()

    self._clickPos = self:globalToLocal(context:getInput():getPosition())
    self._clickPercent = self._value / self._max
end

---@param context EventContext
function M:onGripTouchMove(context)
    if self.canDrag == false then
        return
    end

    local pt = self:globalToLocal(context:getInput():getPosition())
    local deltaX = pt.x - self._clickPos.x
    local deltaY = pt.y - self._clickPos.y

    if self._reverse == true then
        deltaX = -deltaX
        deltaY = -deltaY
    end

    local percent
    if self._barObjectH then
        percent = self._clickPercent + deltaX / self._barMaxWidth
    else
        percent = self._clickPercent + deltaY / self._barMaxHeight
    end

    percent = math.clamp(percent, 0, 1)


    local newValue = percent * self._max
    if newValue ~= self._value then
        self._value = newValue
        self:dispatchEvent(T.UIEventType.Changed)
    end

    self:updateWidthPercent(percent)
end

return M
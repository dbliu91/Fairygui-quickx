local GComponent = require("app.fui.GComponent")

local GActionInterval = require("app.fui.action.GActionInterval")

---@class GProgressBar:GComponent
local M = class("GProgressBar", GComponent)

function M:ctor()
    M.super.ctor(self)

    self._max = 100
    self._value = 0
    self._titleType = T.ProgressTitleType.PERCENT
    self._titleObject = nil
    self._barObjectH = nil
    self._barObjectV = nil

    self._reverse = false

    self._barMaxWidth = 0
    self._barMaxHeight = 0
    self._barMaxWidthDelta = 0
    self._barMaxHeightDelta = 0
    self._barStartX = 0
    self._barStartY = 0
end

function M:getTitleType()
    return self._titleType
end

function M:setTitleType(value)
    if (self._titleType ~= value) then
        self._titleType = value
        self:update(self._value)
    end
end

function M:getMax()
    return self._max
end

function M:setMax(value)
    if (self._max ~= value) then
        self._max = value
        self:update(self._value)
    end
end

function M:getValue()
    return self._value
end

function M:setValue(value)
    if (self._value ~= value) then
        self._value = value
        self:update(self._value)
    end
end

function M:tweenValue(value, duration)
    if self._value ~= value then
        UIRoot:getActionManager():removeActionByTag(T.ActionTag.PROGRESS_ACTION, self)

        local oldValue = self._value
        self._value = value

        local action = GActionInterval.new()
        action:setDuration(duration)
        action._from = { oldValue }
        action._to = { value }
        action:reset_delta()
        action.update = function(action, delta)
            local v = action._to[1] - action._delta[1] * (1 - delta)
            self:update(v)
        end

        action:setTag(T.ActionTag.PROGRESS_ACTION)

        UIRoot:getActionManager():addAction(action, self, false)

    end
end

--------------------------------------------------------------------------------

function M:update(newValue)
    local percent = (self._max~=0) and math.min(newValue / self._max, 1) or 0

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
        self:update(self._value)
    end
end


function M:constructFromXML(xml)
    xml = xml.ProgressBar

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

end

function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self, xml)

    xml = xml.ProgressBar
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

    self:update(self._value)
end

--[[



protected:
    virtual void constructFromXML(TXMLElement* xml) override;
    virtual void setup_AfterAdd(TXMLElement* xml) override;

--]]

return M
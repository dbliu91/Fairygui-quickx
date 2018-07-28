---@class FUIInnerContainer
local M = class("FUIInnerContainer",display.newNode)

function M:getPosition2()
    local x,y =  self:getPosition()
    y = self:getParent():getContentSize().height - y
    return cc.p(x,y)
end

function M:setPosition2(x, y)
    if type(x)=="table" then
        x, y = x.x, x.y
    end
    y = self:getParent():getContentSize().height - y
    self:setPosition(cc.p(x, y))
end

function M:getPositionY2()
    local y =  self:getPositionY()
    y = self:getParent():getContentSize().height - y
    return y
end

function M:setPositionY2(y)
    y = self:getParent():getContentSize().height - y
    self:setPositionY(y)
end

return M
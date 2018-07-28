---@class GAction
local M = class("GAction")

function M:ctor()
    self._originalTarget = nil
    self._target = nil
    self._tag = 0
    self._flag = 0
end

function M:startWithTarget(target)
    self._originalTarget = target
    self._target = target
end

function M:stop()
    self._target = nil
end

function M:getTarget()
    return self._target
end

function M:setTarget(target)
    self._target = target
end

function M:getOriginalTarget()
    return self._originalTarget
end

function M:setOriginalTarget(target)
    self._originalTarget = target
end

function M:getTag()
    return self._tag
end

function M:setTag(tag)
    self._tag = tag
end

return M
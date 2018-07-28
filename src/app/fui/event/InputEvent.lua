---@class InputEvent
local M = class("InputEvent")

function M:ctor()
    self._target = nil
    self._touch = nil
    self._inputProcessor = nil
    self._touchId = -1
    self._clickCount = 0
    self._mouseWheelDelta = 0
    self._keyCode = 0
    self._keyModifiers = 0

    self._pos = cc.p(0,0)
end

function M:getTarget()
    return self._target
end

function M:getX()
    return self._pos.x
end

function M:getY()
    return self._pos.y
end

function M:getPosition()
    return self._pos
end

function M:getTouch()
    return self._touch
end

function M:getTouchId()
    return self._touchId
end

function M:isDoubleClick()
    return self._clickCount==2
end

function M:getButton()
    return self._keyCode
end

function M:getKeyCode()
    return self._touch
end

function M:isCtrlDown()
    return bit.band(self._keyModifiers,1)
end

function M:isAltDown()
    return bit.band(self._keyModifiers,2)
end

function M:isShiftDown()
    return bit.band(self._keyModifiers,4)
end

function M:getMouseWheelDelta()
    return self._mouseWheelDelta
end

function M:getProcessor()
    return self._inputProcessor
end

return M
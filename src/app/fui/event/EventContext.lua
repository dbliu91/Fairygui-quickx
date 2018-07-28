---@class EventContext
local M = class("EventContext")

function M:ctor()
    self._sender = nil
    self._data = nil
    self._inputEvent = nil
    self._isStopped = nil
    self._defaultPrevented = false
    self._touchCapture = 0
    self._type = 0

    self._dataValue = nil
end

function M:getType()
    return self._type
end
function M:getSender()
    return self._sender
end
function M:getInput()
    return self._inputEvent
end
function M:isDefaultPrevented()
    return self._defaultPrevented
end
function M:getDataValue()
    return self._dataValue
end
function M:getData()
    return self._data
end

function M:stopPropagation()
    self._isStopped=true
end

function M:preventDefault()
    self._defaultPrevented=true
end

function M:captureTouch()
    self._touchCapture=1
end

function M:uncaptureTouch()
    self._touchCapture=2
end

return M
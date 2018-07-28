local EventCallbackItem = require("app.fui.event.EventCallbackItem")
local EventContext = require("app.fui.event.EventContext")

---@class UIEventDispatcher
local M = class("UIEventDispatcher")

function M:ctor()
    self._dispatching = 0
    self._callbacks = {}
end

function M:doDestory()
    self._dispatching = 0
    self:removeEventListeners()
end

function M:addEventListener(eventType, callback, tag)

    if type(tag)=="table" then
        tag = tostring(tag)
    end

    if tag then
        for i, v in ipairs(self._callbacks) do
            if v.eventType == eventType and v.tag == tag then
                v.callback = callback
                return
            end
        end
    end

    local item = EventCallbackItem.new()
    item.callback = callback
    item.eventType = eventType
    item.tag = tag
    item.dispatching = 0
    table.insert(self._callbacks, item)
end

function M:removeEventListener(eventType, tag)
    if #self._callbacks == 0 then
        return
    end

    if type(tag)=="table" then
        tag = tostring(tag)
    end

    --for i, v in ipairs(self._callbacks) do
    for i = #self._callbacks, 1, -1 do
        local v = self._callbacks[i]
        if v.eventType == eventType and (tag == nil or v.tag == tag) then
            if (self._dispatching > 0) then
                v.callback = nil
            else
                table.remove(self._callbacks, i)
            end
        end
    end
end

function M:removeEventListeners()
    if #self._callbacks == 0 then
        return false
    end

    if self._dispatching > 0 then
        for i, v in ipairs(self._callbacks) do
            v.callback = nil
        end
    else
        self._callbacks = {}
    end
end

function M:hasEventListener(eventType, tag)
    if #self._callbacks == 0 then
        return false
    end

    if type(tag)=="table" then
        tag = tostring(tag)
    end

    for i, v in ipairs(self._callbacks) do
        if v.eventType == eventType and (v.tag == tag or v.tag == nil) and v.callback ~= nil then
            return true
        end
    end

    return false
end

function M:dispatchEvent(eventType, data, dataValue)
    if #self._callbacks == 0 then
        return false
    end

    local context = EventContext.new()
    context._sender = self
    context._type = eventType

    if InputProcessor_activeProcessor then
        context._inputEvent = InputProcessor_activeProcessor:getRecentInput()
    end

    context._dataValue = dataValue
    context._data = data

    self:_doDispatch(eventType, context)

    return context._defaultPrevented

end

function M:bubbleEvent(eventType, data, dataValue)
    local context = EventContext.new()

    if InputProcessor_activeProcessor then
        context._inputEvent = InputProcessor_activeProcessor:getRecentInput()
    end

    context._type = eventType
    context._dataValue = dataValue
    context._data = data

    self:_doBubble(eventType, context)

    return context._defaultPrevented
end

function M:isDispatchingEvent(eventType)
    for i, v in ipairs(self._callbacks) do
        if v.eventType == eventType then
            return v.dispatching > 0
        end
    end
    return false
end

---

---@param context EventContext
function M:_doDispatch(eventType, context)
    self._dispatching = self._dispatching + 1
    context._sender = self
    local hasDeletedItems = false

    local cnt = #self._callbacks
    for i = 1, cnt do
        while true do
            ---@type EventCallbackItem
            local ci = self._callbacks[i]
            if ci.callback == nil then
                hasDeletedItems = true
                break
            end
            if ci.eventType == eventType then
                ci.dispatching = ci.dispatching + 1
                context._touchCapture = 0
                ci.callback(context)
                ci.dispatching = ci.dispatching - 1
                if context._touchCapture ~= 0 and iskindof(self, "GObject") then
                    if context._touchCapture == 1 and eventType == T.UIEventType.TouchBegin then
                        context:getInput():getProcessor():addTouchMonitor(context:getInput():getTouchId(), self)
                    elseif context._touchCapture == 2 then
                        context:getInput():getProcessor():removeTouchMonitor(self)
                    end
                end
            end
            break
        end
    end

    self._dispatching = self._dispatching - 1

    if hasDeletedItems and self._dispatching == 0 then
        for i = #self._callbacks, 1, -1 do
            local v = self._callbacks[i]
            if v.callback == nil then
                table.remove(self._callbacks, i)
            end
        end
    end

end

---@param context EventContext
function M:_doBubble(eventType, context)
    if #self._callbacks > 0 then
        context._isStopped = false
        self:_doDispatch(eventType, context)
        if context._isStopped == true then
            return
        end
    end

    local p = self:getParent()
    if p then
        p:_doBubble(eventType, context)
    end

end

return M
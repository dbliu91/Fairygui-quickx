local InputEvent = require("app.fui.event.InputEvent")

local TouchInfo = require("app.fui.event.TouchInfo")

---@class InputProcessor
---@field public _owner GComponent
local M = class("InputProcessor")

function M:ctor(owner)

    self._touches = {}

    self._recentInput = InputEvent.new()
    self._recentInput._inputProcessor = self

    self._owner = owner

    self._touchListener = self._owner._displayObject:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)

        --print("cc.NODE_TOUCH_EVENT:", event.name)

        if event.name == "began" then
            return self:onTouchBegan(event)
        elseif event.name == "moved" then
            self:onTouchMoved(event)
        elseif event.name == "ended" then
            self:onTouchEnded(event)
        elseif event.name == "cancelled" then
            self:onTouchCancelled(event)
        else
            print("not imp", event.name)
        end
    end)

    self._owner._displayObject:setTouchEnabled(true)
end

function M:doDestory()
    if self._touchListener then
        self._owner._displayObject:removeNodeEventListener(self._touchListener)
        self._touchListener = nil
    end

    self._touches = {}
end

---@param  tiTouchInfo
function M:setBegin(ti, target)
    ti.began = true
    ti.clickCancelled = false
    ti.downPos = clone(ti.pos)

    ti.downTargets = {}

    local obj = target
    while obj ~= nil do
        table.insert(ti.downTargets, obj)
        obj = obj:getParent()
    end
end

---@param ti TouchInfo
function M:setEnd(ti, target)
    ti.began = false

    local now = ToolSet.getCurrentTime()
    local elapsed = now - ti.lastClickTime

    if elapsed < 0.45 then
        if ti.clickCount == 2 then
            ti.clickCount = 1
        else
            ti.clickCount = ti.clickCount + 1
        end
    else
        ti.clickCount = 1
    end

    ti.lastClickTime = now

end

---鼠标 单点触摸------------------------------------------
function M:onTouchBegan(event)

    local pt = cc.p(event.x, event.y)
    local target = self._owner:hitTest(pt)

    if not target then
        target = self._owner
    end

    self._owner._displayObject:setTouchSwallowEnabled(target ~= self._owner)

    --print(target.name)

    local ti = self:getTouch(1)
    ti.pos = cc.p(pt.x, UIRoot:getHeight() - pt.y)
    ti.button = 0
    ti.touch = event
    self:setBegin(ti, target)

    self:updateRecentInput(ti, target)

    InputProcessor_activeProcessor = self

    if self._captureCallback then
        self._captureCallback(T.UIEventType.TouchBegin)
    end

    target:bubbleEvent(T.UIEventType.TouchBegin)

    self:handleRollOver(ti, target)

    InputProcessor_activeProcessor = nil

    return true
end

function M:onTouchMoved(event)

    local pt = cc.p(event.x, event.y)
    local target = self._owner:hitTest(pt)
    if target == nil then
        target = self._owner
    end

    local ti = self:getTouch(1)
    ti.pos = cc.p(pt.x, UIRoot:getHeight() - pt.y)
    ti.button = 0
    ti.touch = event

    self:updateRecentInput(ti, target)

    InputProcessor_activeProcessor = self

    if self._captureCallback then
        self._captureCallback(T.UIEventType.TouchMove)
    end

    self:handleRollOver(ti, target)

    if ti.began == true then
        local done = false

        for i, v in ipairs(ti.touchMonitors) do
            v:dispatchEvent(T.UIEventType.TouchMove)
            if v == self._owner then
                done = true
            end
        end

        if done ~= true then
            self._owner:dispatchEvent(T.UIEventType.TouchMove)
        end
    end

    InputProcessor_activeProcessor = nil
end

function M:onTouchEnded(event)
    local pt = cc.p(event.x, event.y)

    local target = self._owner:hitTest(pt)

    if not target then
        target = self._owner
    end

    local ti = self:getTouch(1)
    ti.pos = cc.p(pt.x, UIRoot:getHeight() - pt.y)
    ti.button = 0
    ti.touch = event
    self:setEnd(ti, target)

    self:updateRecentInput(ti, target)
    InputProcessor_activeProcessor = self

    if self._captureCallback then
        self._captureCallback(T.UIEventType.TouchEnd)
    end

    for i, v in ipairs(ti.touchMonitors) do
        if v ~= target and
                (iskindof(v, "GComponent") == false or v:isAncestorOf(target)==false) then
            v:dispatchEvent(T.UIEventType.TouchEnd)
        end
    end
    ti.touchMonitors = {}

    if target then
        target:bubbleEvent(T.UIEventType.TouchEnd)
    end

    target = self:clickTest(ti, target)
    if target then
        self:updateRecentInput(ti, target)

        --[[
        GRichTextField* tf = dynamic_cast<GRichTextField*>(target);
        if (tf)
        {
            const char* linkHref = dynamic_cast<FUIRichText*>(tf->displayObject())->hitTestLink(pt);
            if (linkHref)
            {
                tf->bubbleEvent(UIEventType::ClickLink, nullptr, Value(linkHref));
                target = wptr.ptr();
            }
        }
        --]]

        target:bubbleEvent(T.UIEventType.Click)
    end

    self:handleRollOver(ti, nil)

    InputProcessor_activeProcessor = nil
end

function M:onTouchCancelled(event)
    local ti = self:getTouch(1)
    if ti == nil then
        return
    end

    ti.touch = event
    self:updateRecentInput(ti, self._owner)

    InputProcessor_activeProcessor = self

    if self._captureCallback then
        self._captureCallback(T.UIEventType.TouchEnd)
    end

    for i, v in ipairs(ti.touchMonitors) do
        v:dispatchEvent(T.UIEventType.TouchEnd)
    end
    ti.touchMonitors = {}

    self._owner:dispatchEvent(T.UIEventType.TouchEnd)

    self:handleRollOver(ti,nil)

    ti.touchId = -1
    ti.button = 0

    InputProcessor_activeProcessor = nil
end

function M:handleRollOver(ti, target)
    if ti.lastRollOver == target then
        return
    end

    local rollOutChain = {}
    local rollOverChain = {}

    local element = ti.lastRollOver
    while (element ~= nil) do
        table.insert(rollOutChain, element)
        element = element:getParent()
    end

    element = target
    while (element ~= nil) do
        local idx = table.indexof(rollOutChain, element)
        if idx ~= false then
            table.remove(rollOutChain, idx)
            break
        end
        table.insert(rollOverChain, element)
        element = element:getParent()
    end

    ti.lastRollOver = target

    for i, v in ipairs(rollOutChain) do
        if tolua.isnull(v) == false and element:onStage() then
            element:dispatchEvent(T.UIEventType.RollOut)
        end
    end

    for i, v in ipairs(rollOverChain) do
        if tolua.isnull(v) == false and element:onStage() then
            element:dispatchEvent(T.UIEventType.RollOver)
        end
    end
end

function M:clickTest(ti, target)
    if #ti.downTargets == 0
            or ti.clickCancelled == true
            or math.abs(ti.pos.x - ti.downPos.x) > 50
            or math.abs(ti.pos.y - ti.downPos.y) > 50
    then
        return nil
    end

    local obj = ti.downTargets[1]
    if obj and obj:onStage() == true then
        return obj
    end

    obj = target

    while obj ~= nil do
        local idx = table.indexof(ti.downTargets, obj)
        if idx ~= false and ti.downTargets[idx]:onStage() == true then
            obj = ti.downTargets[idx]
            break
        end
        obj = obj:getParent()
    end

    return obj
end

function M:getRecentInput()
    return self._recentInput
end

function M:addTouchMonitor(touchId, target)
    local ti = self:getTouch(touchId, false)
    if ti == nil then
        return
    end

    if table.indexof(ti.touchMonitors, target) == false then
        table.insert(ti.touchMonitors, target)
    end
end

function M:removeTouchMonitor(target)
    for i, ti in ipairs(self._touches) do
        table.removebyvalue(ti.touchMonitors, target)
    end
end

function M:getTouchPosition(touchId)
    for i, v in ipairs(self._touches) do
        if v.touchId == touchId then
            return v.pos
        end
    end
    return self._recentInput:getPosition()
end

function M:getTouch(touchId, createIfNotExisits)

    if createIfNotExisits == nil then
        createIfNotExisits = true
    end

    local ret
    for i, v in ipairs(self._touches) do
        if v.touchId == touchId then
            return v
        elseif v.touchId == -1 then
            ret = v
        end
    end

    if ret == nil then
        if createIfNotExisits == false then
            return nil
        end

        ret = TouchInfo.new()
        table.insert(self._touches, ret)
    end

    ret.touchId = touchId
    return ret
end

function M:cancelClick(touchId)
    local ti = self:getTouch(touchId, false)
    if ti then
        ti.clickCancelled = true
    end
end

function M:updateRecentInput(ti, target)
    self._recentInput._pos.x = checkint(ti.pos.x)
    self._recentInput._pos.y = checkint(ti.pos.y)
    self._recentInput._target = target
    self._recentInput._clickCount = ti.clickCount
    self._button = ti.button
    self._recentInput._mouseWheelDelta = ti.mouseWheelDelta
    self._recentInput._touch = ti.touch
    self._recentInput._touchId = ti.touch and ti.touchId or -1

    local curFrame = cc.Director:getInstance():getTotalFrames()
    local flag = (target ~= self._owner)
    if curFrame ~= self._touchOnUIFlagFrameId then
        self._touchOnUI = false
    elseif (flag == true) then
        self._touchOnUI = true
    end

    self._touchOnUIFlagFrameId = curFrame

end

function M:setCaptureCallback(cb)
    self._captureCallback = cb
end

return M
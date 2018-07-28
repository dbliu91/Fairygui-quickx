local TransitionItem = require("app.fui.TransitionItem")

local GActionInterval = require("app.fui.action.GActionInterval")
local GSequence = require("app.fui.action.GSequence")

local FRAME_RATE = 24
local OPTION_IGNORE_DISPLAY_CONTROLLER = 1
local OPTION_AUTO_STOP_DISABLED = 2
local OPTION_AUTO_STOP_AT_END = 4

---@class Transition
---@field _items [TransitionItem]
local M = class("Transition")

function M:ctor(owner, index)
    self._owner = owner
    self._actionTag = T.ActionTag.TRANSITION_ACTION + index

    self.autoPlayRepeat = 1
    self.autoPlayDelay = 0
    self._totalTimes = 0
    self._totalTasks = 0
    self._playing = false
    self._ownerBaseX = 0
    self._ownerBaseY = 0
    self._onComplete = nil
    self._options = 0
    self._reversed = false
    self._maxTime = 0
    self._autoPlay = false
    self._items = {}
end

function M:getOwner()
    return self._owner
end

function M:isAutoPlay()
    return self._autoPlay
end

function M:setAutoPlay(value)
    if self._autoPlay ~= value then
        self._autoPlay = value

        if self._autoPlay == true then
            if self._owner:onStage() then
                self:play(self.autoPlayRepeat, self.autoPlayDelay, nil)
            end
        else
            if self._owner:onStage() then
                self:stop(false, true)
            end
        end

    end
end

function M:isPlaying()
    return self._playing
end

function M:play(...)

    local times, delay, callback, reverse

    local args = { ... }
    if #args == 0 then
        times = 1
        delay = 0
    elseif #args == 1 then
        if type(args[1]) == "function" then
            callback = args[1]
            times = 1
            delay = 0
        end
    else
        times, delay, callback, reverse = args[1], args[2], args[3], args[4]
    end

    if reverse == nil then
        reverse = false
    end

    self:stop(true, true)

    self._totalTimes = times
    self._reversed = reverse

    self:internalPlay(delay)

    self._playing = (self._totalTasks > 0)
    if self._playing == true then
        self._onComplete = callback

        if bit.band(self._options, OPTION_IGNORE_DISPLAY_CONTROLLER) ~= 0 then
            for i, v in ipairs(self._items) do
                if v.target and v.target ~= self._owner then
                    v.displayLockToken = v.target:addDisplayLock()
                end
            end
        end
    elseif callback then
        callback()
    end

end

function M:playReverse(times, delay, callback)
    self:play(times, delay, callback, true)
end

function M:stop(setToComplete, processCallback)
    if setToComplete == nil and processCallback == nil then
        setToComplete = true
        processCallback = false
    end

    if self._playing == true then
        self._playing = false
        self._totalTimes = 0
        self._totalTasks = 0
        local func = self._onComplete
        self._onComplete = nil
        self._owner:displayObject():stopAllActionsByTag(self._actionTag)

        local cnt = #self._items
        if self._reversed == true then
            for i = cnt, 1, -1 do
                ---@type TransitionItem
                local item = self._items[i]
                if item.target then
                    self:stopItem(item, setToComplete)
                end
            end
        else
            for i = 1, cnt, 1 do
                ---@type TransitionItem
                local item = self._items[i]
                if item.target then
                    self:stopItem(item, setToComplete)
                end
            end
        end

        if processCallback and func ~= nil then
            func()
        end

    end

end

function M:changeRepeat(value)
    self._totalTimes = value
end
--[=[
function M:setValue(label, values)
    for i, v in ipairs(self._items) do
        if v.label == label then
            if v.item.tween == true then
                self:_setValue(v, v.startValue, values)
            else
                self:_setValue(v, v.value, values)
            end
        elseif v.label2 == label then
            self:_setValue(v, v.endValue, values)
        end
    end
end

---@param value TransitionValue
function M:_setValue(item, value, values)
    if item.type == T.TransitionActionType.XY
            or item.type == T.TransitionActionType.Size
            or item.type == T.TransitionActionType.Pivot
            or item.type == T.TransitionActionType.Scale
            or item.type == T.TransitionActionType.Skew
    then
        value.b1 = true
        value.b2 = true
        value.f1 = checknumber(values[1]) or 0
        value.f2 = checknumber(values[2]) or 0
    elseif item.type == T.TransitionActionType.Alpha then
        value.f1 = checknumber(values[1]) or 0
    elseif item.type == T.TransitionActionType.Rotation then
        value.f1 = checknumber(values[1]) or 0
    elseif item.type == T.TransitionActionType.Color then
        --[[
        uint32_t v = values[0].asUnsignedInt();
        value.c = Color4B((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF, (v >> 24) & 0xFF);
        break;
        --]]
    elseif item.type == T.TransitionActionType.Animation then
        value.i = checkint(values[1])
        if #values > 1 then
            value.b = checkbool(values[2])
        end
    elseif item.type == T.TransitionActionType.Visible then
        value.b = checkbool(values[1])
    elseif item.type == T.TransitionActionType.Sound then
        value.s = tostring(values[1])
        if #values > 1 then
            value.f1 = checknumber(values[2]) or 0
        end
    elseif item.type == T.TransitionActionType.Transition then
        value.s = tostring(values[1])
        if #values > 1 then
            value.i = checkint(values[2]) or 0
        end
    elseif item.type == T.TransitionActionType.Shake then
        value.s = checknumber(values[1]) or 0
        if #values > 1 then
            value.i = checknumber(values[2]) or 0
        end
    elseif item.type == T.TransitionActionType.ColorFilter then
        value.f1 = checknumber(values[2]) or 0
        value.f2 = checknumber(values[3]) or 0
        value.f3 = checknumber(values[4]) or 0
        value.f4 = checknumber(values[5]) or 0
    end
end
--]=]
function M:setHook(label, callback)
    for i, v in ipairs(self._items) do
        if v.label == label then
            v.hook = callback
            break
        elseif v.label2 == label then
            v.hook2 = callback
            break
        end
    end
end

function M:clearHooks()
    for i, v in ipairs(self._items) do
        v.hook = nil
        v.hook2 = nil
    end
end

function M:setTarget(label, newTarget)
    for i, v in ipairs(self._items) do
        if v.label == label then
            v.targetId = newTarget.id
        end
    end
end

function M:setDuration(label, value)
    for i, v in ipairs(self._items) do
        if v.tween == true and v.label == label then
            v.duration = value
        end
    end
end

function M:updateFromRelations(targetId, dx, dy)
    for i, v in ipairs(self._items) do
        if v.type == T.TransitionActionType.XY and v.targetId == targetId then
            if v.tween == true then
                v.startValue.f1 = v.startValue.f1 + dx
                v.startValue.f2 = v.startValue.f2 + dy
                v.endValue.f1 = v.endValue.f1 + dx
                v.endValue.f2 = v.endValue.f2 + dy
            else
                v.value.f1 = v.value.f1 + dx
                v.value.f2 = v.value.f2 + dy
            end
        end
    end
end

function M:OnOwnerRemovedFromStage()
    if bit.band(self._options, OPTION_AUTO_STOP_DISABLED) == 0 then
        local b = bit.band(self._options, OPTION_AUTO_STOP_AT_END) ~= 0 and true or false
        self:stop(b, false)
    end
end

function M:internalPlay(delay)
    self._ownerBaseX = self._owner:getX()
    self._ownerBaseY = self._owner:getY()

    self._totalTasks = 0

    for i, v in ipairs(self._items) do
        while true do
            if not (v.targetId == nil or v.targetId == "") then
                v.target = self._owner:getChildById(v.targetId)
            else
                v.target = self._owner
            end

            if v.target == nil then
                break
            end

            if v.tween == true then
                local startTime = delay
                if self._reversed == true then
                    startTime = startTime + (self._maxTime - v.time - v.duration)
                else
                    startTime = startTime + v.time
                end

                if startTime > 0 and (v.type == T.TransitionActionType.XY or v.type == T.TransitionActionType.Size) then
                    self._totalTasks = self._totalTasks + 1
                    v.completed = false

                    local action = cc.Sequence:create(
                            cc.DelayTime:create(startTime),
                            cc.CallFunc:create(function()
                                self._totalTasks = self._totalTasks - 1
                                self:startTween(v, 0)
                            end)
                    )

                    action:setTag(T.ActionTag.TRANSITION_ACTION)
                    self._owner:displayObject():runAction(action)
                else
                    self:startTween(v, startTime)
                end
            else
                local startTime = delay
                if self._reversed == true then
                    startTime = startTime + (self._maxTime - v.time)
                else
                    startTime = startTime + v.time
                end

                if startTime == 0 then
                    self:applyValue(v, v.value)
                else
                    v.completed = false
                    self._totalTasks = self._totalTasks + 1

                    local action = cc.Sequence:create(
                            cc.DelayTime:create(startTime),
                            cc.CallFunc:create(function()
                                v.completed = true
                                self._totalTasks = self._totalTasks - 1

                                self:applyValue(v, v.value)

                                if v.hook then
                                    v.hook()
                                end

                                self:checkAllComplete()

                            end)
                    )

                    action:setTag(T.ActionTag.TRANSITION_ACTION)
                    self._owner:displayObject():runAction(action)

                end

            end

            break
        end

    end
end

function M:setup(xml)
    local p
    self.name = xml["@name"]

    p = xml["@options"]
    if p then
        self._options = checkint(p)
    end

    self._autoPlay = xml["@autoPlay"] == "true"
    if self._autoPlay == true then
        p = xml["@autoPlayRepeat"]
        if p then
            self.autoPlayRepeat = checkint(p)
        end
        self.autoPlayDelay = checknumber(xml["@autoPlayDelay"]) or 0
    end

    for i, v in ipairs(xml:children()) do
        if v:name() == "item" then
            local cxml = v
            local item = TransitionItem.new()
            table.insert(self._items, item)

            item.time = checkint(cxml["@time"]) / FRAME_RATE

            p = cxml["@target"]
            if p then
                item.targetId = p
            end

            p = cxml["@type"]
            if p then
                item.type = p
            end

            item.tween = cxml["@tween"] == "true"

            p = cxml["@label"]
            if p then
                item.label = p
            end

            if item.tween == true then
                item.duration = checkint(cxml["@duration"]) / FRAME_RATE
                if (item.time + item.duration) > self._maxTime then
                    self._maxTime = item.time + item.duration
                end

                p = cxml["@ease"]
                if p then
                    item.easeType = p
                end

                item.repeat_time = checkint(cxml["@repeat"])
                item.yoyo = cxml["@yoyo"] == "true"

                p = cxml["@label2"]
                if p then
                    item.label2 = p
                end

                p = cxml["@endValue"]
                if p then
                    self:decodeValue(item.type, cxml["@startValue"], item.startValue)
                    self:decodeValue(item.type, p, item.endValue)
                else
                    item.tween = false
                    self:decodeValue(item.type, cxml["@startValue"], item.value)
                end
            else
                if item.time > self._maxTime then
                    self._maxTime = item.time
                end
                self:decodeValue(item.type, cxml["@value"], item.value)
            end

        end
    end

end

---@param item TransitionItem
function M:tweenComplete(item)
    item.completed = true
    self._totalTasks = self._totalTasks - 1
    if item.hook2 then
        item.hook2()
    end

    self:checkAllComplete()
end

function M:playTransComplete(item)
    self._totalTasks = self._totalTasks - 1
    item.completed = true
    self:checkAllComplete()
end

function M:checkAllComplete()
    if self._playing == true and self._totalTasks == 0 then
        if self._totalTasks < 0 then
            self:internalPlay(0)
        else
            self._totalTimes = self._totalTimes - 1
            if self._totalTimes > 0 then
                self:internalPlay(0)
            else
                self._playing = false

                for i, v in ipairs(self._items) do
                    ---@type TransitionItem
                    local item = v
                    if item.target then
                        if item.displayLockToken ~= 0 then
                            item.target:releaseDisplayLock(item.displayLockToken)
                            item.displayLockToken = 0
                        end
                    end
                end

                if self._onComplete then
                    local func = self._onComplete
                    self._onComplete = nil
                    func()
                end

            end
        end
    end
end

---@param type TransitionActionType
---@param value TransitionItem
function M:decodeValue(type, pValue, value)
    local str = pValue or ""
    if type == T.TransitionActionType.XY
            or type == T.TransitionActionType.Size
            or type == T.TransitionActionType.Pivot
            or type == T.TransitionActionType.Skew
    then
        local v2 = string.split(str, ",")
        if v2[1] == "-" then
            value.b1 = false
        else
            value.f1 = checknumber(v2[1]) or 0
            value.b1 = true
        end

        if v2[2] == "-" then
            value.b2 = false
        else
            value.f2 = checknumber(v2[2]) or 0
            value.b2 = true
        end
    elseif type == T.TransitionActionType.Alpha then
        value.f1 = checknumber(str) or 0
    elseif type == T.TransitionActionType.Rotation then
        value.f1 = checkint(str)
    elseif type == T.TransitionActionType.Scale then
        local v2 = string.split(str, ",")
        value.f1 = checknumber(v2[1]) or 0
        value.f2 = checknumber(v2[2]) or 0
    elseif type == T.TransitionActionType.Color then
        value.c = ToolSet.convertFromHtmlColor(str)
    elseif type == T.TransitionActionType.Animation then
        local v2 = string.split(str, ",")
        if v2[1] == "-" then
            value.b1 = false
        else
            value.i = checkint(v2[1])
            value.b1 = true
        end
        value.b = (v2[2] == "p")
    elseif type == T.TransitionActionType.Visible then
        value.b = (str == "true")
    elseif type == T.TransitionActionType.Sound then
        local v2 = string.split(str, ",")
        value.s = v2[1]
        if v2[2] and v2[2] ~= "" then
            local intv = checkint(v2[2])
            if intv == 100 or intv == 0 then
                value.f1 = 1
            else
                value.f1 = intv / 100
            end
        else
            value.f1 = 1
        end
    elseif type == T.TransitionActionType.Transition then
        local v2 = string.split(str, ",")
        value.s = v2[1]
        if v2[2] and v2[2] ~= "" then
            value.i = checkint(v2[2])
        else
            value.i = 1
        end
    elseif type == T.TransitionActionType.Shake then
        local v2 = string.split(str, ",")
        value.f1 = checknumber(v2[1]) or 0
        value.f2 = checknumber(v2[2]) or 0
    elseif type == T.TransitionActionType.ColorFilter then
        local v4 = string.split(str, ",")
        value.f1 = checknumber(v4[1]) or 0
        value.f2 = checknumber(v4[2]) or 0
        value.f3 = checknumber(v4[3]) or 0
        value.f4 = checknumber(v4[4]) or 0
    end
end

---@param item TransitionItem
---@param value TransitionValue
function M:applyValue(item, value)
    item.target._gearLocked = true

    if item.type == T.TransitionActionType.XY then
        if item.target == self._owner then
            local f1, f2
            if value.b1 == false then
                f1 = item.target:getX()
            else
                f1 = value.f1 + self._ownerBaseX
            end

            if value.b2 == false then
                f2 = item.target:getY()
            else
                f2 = value.f2 + self._ownerBaseY
            end
            item.target:setPosition(f1, f2)
        else
            if value.b1 == false then
                value.f1 = item.target:getX()
            end

            if value.b2 == false then
                value.f2 = item.target:getY()
            end
            item.target:setPosition(value.f1, value.f2)
        end
    elseif item.type == T.TransitionActionType.Size then
        if value.b1 == false then
            value.f1 = item.target:getWidth()
        end

        if value.b2 == false then
            value.f2 = item.target:getHeight()
        end

        item.target:setSize(value.f1, value.f2)
    elseif item.type == T.TransitionActionType.Pivot then
        item.target:setPivot(value.f1, value.f2)
    elseif item.type == T.TransitionActionType.Alpha then
        item.target:setAlpha(value.f1)
    elseif item.type == T.TransitionActionType.Rotation then
        item.target:setRotation(value.f1)
    elseif item.type == T.TransitionActionType.Scale then
        item.target:setScale(value.f1, value.f2)
    elseif item.type == T.TransitionActionType.Skew then
        item.target:setSkewX(value.f1)
        item.target:setSkewY(value.f2)
    elseif item.type == T.TransitionActionType.Color then
        if item.target.cg_setColor then
            item.target:cg_setColor(value.c)
        end
    elseif item.type == T.TransitionActionType.Animation then
        local ag = item.target
        if ag.setPlaying then
            --if value.b1==false then
            --    value.i = ag:getCurrentFrame()
            --end
            --ag:setCurrentFrame(value.i+1)
            print("帧动画还不支持设置帧数")
            ag:setPlaying(value.b)
        end

    elseif item.type == T.TransitionActionType.Visible then
        item.target:setVisible(value.b)
    elseif item.type == T.TransitionActionType.Transition then
        local trans = item.target:getTransition(value.s)
        if trans then
            if value.i == 0 then
                trans:stop(false, true)
            elseif trans:isPlaying() == true then
                trans._totalTimes = value.i
            else
                item.completed = false
                self._totalTasks = self._totalTasks + 1
                if self._reversed == true then
                    trans:playReverse(value.i, 0, function()
                        self:playTransComplete(item)
                    end)
                else
                    trans:play(value.i, 0, function()
                        self:playTransComplete(item)
                    end)
                end
            end
        end
    elseif item.type == T.TransitionActionType.Sound then
        UIRoot:playSound(value.s, value.f1)
    elseif item.type == T.TransitionActionType.Shake then
        item.startValue.f1 = 0 --offsetX
        item.startValue.f2 = 0 --offsetY
        item.startValue.f3 = item.value.f2 --shakePeriod
        --TODO
        --Director::getInstance()->getScheduler()->schedule(CC_CALLBACK_1(Transition::shakeItem, this, item), item, 0, false, "-");
        local q = UIRoot:getCoroutine()
        self._q_shake = q:PlayRoutine(function ()
            while true do
                q:WaitTime(1/24)
                local stop = self:shakeItem(1/24,item)
                if stop==true then
                    break
                end
            end
        end)
        self._totalTasks = self._totalTasks + 1
        item.completed = false
    end

    item.target._gearLocked = false
end

---@return boolean 是否停止
function M:shakeItem(dt, item)
    local r = math.ceil(item.value.f1 * item.startValue.f3 / item.value.f2);
    local x1 = (1 - math.random() * 2) * r;
    local y1 = (1 - math.random() * 2) * r;
    x1 = x1 > 0 and math.ceil(x1) or math.floor(x1);
    y1 = y1 > 0 and math.ceil(y1) or math.floor(y1);

    item.target._gearLocked = true;
    item.target:setPosition(item.target:getX() - item.startValue.f1 + x1, item.target:getY() - item.startValue.f2 + y1);
    item.target._gearLocked = false;

    item.startValue.f1 = x1;
    item.startValue.f2 = y1;
    item.startValue.f3 = item.startValue.f3 - dt;

    if (item.startValue.f3 <= 0) then
        item.target._gearLocked = true;
        item.target:setPosition(item.target:getX() - item.startValue.f1, item.target:getY() - item.startValue.f2);
        item.target._gearLocked = false;

        item.completed = true;
        self._totalTasks = self._totalTasks - 1
        self:checkAllComplete();

        ---Director::getInstance()->getScheduler()->unschedule("-", item);
        return true
    end

    return false
end

local get_delta = function(action)
    local delta = {}
    for i = 1, #action._from do
        delta[i] = action._to[i] - action._from[i]
    end
    return delta
end

---@param item TransitionItem
---@param startValue TransitionValue
---@param endValue TransitionValue
function M:startTween(item, delay, startValue, endValue)
    if startValue == nil and endValue == nil then
        if self._reversed == true then
            startValue = item.endValue
            endValue = item.startValue
        else
            startValue = item.startValue
            endValue = item.endValue
        end
    end

    local mainAction
    if item.type == T.TransitionActionType.XY
            or item.type == T.TransitionActionType.Size
    then
        if item.type == T.TransitionActionType.XY then
            if item.target == self._owner then
                if startValue.b1 == false then
                    startValue.f1 = 0
                end
                if startValue.b2 == false then
                    startValue.f2 = 0
                end
            else
                if startValue.b1 == false then
                    startValue.f1 = item.target:getX()
                end
                if startValue.b2 == false then
                    startValue.f2 = item.target:getY()
                end
            end
        else
            if startValue.b1 == false then
                startValue.f1 = item.target:getWidth()
            end
            if startValue.b2 == false then
                startValue.f2 = item.target:getHeight()
            end
        end

        item.value.f1 = startValue.f1
        item.value.f2 = startValue.f2

        if endValue.b1 == false then
            endValue.f1 = item.value.f1
        end
        if endValue.b2 == false then
            endValue.f2 = item.value.f2
        end

        item.value.b1 = startValue.b1 or endValue.b1
        item.value.b2 = startValue.b2 or endValue.b2

        mainAction = GActionInterval.new()
        mainAction:setDuration(item.duration)
        mainAction._from = { startValue.f1, startValue.f2 }
        mainAction._to = { endValue.f1, endValue.f2 }
        mainAction._delta = get_delta(mainAction)
        mainAction.update = function(action, delta)
            local x = mainAction._to[1] - mainAction._delta[1] * (1 - delta)
            local y = mainAction._to[2] - mainAction._delta[2] * (1 - delta)
            item.value.f1 = x
            item.value.f2 = y
            self:applyValue(item, item.value)
        end

    elseif item.type == T.TransitionActionType.Scale
            or item.type == T.TransitionActionType.Skew
    then
        item.value.f1 = startValue.f1
        item.value.f2 = startValue.f2

        mainAction = GActionInterval.new()
        mainAction:setDuration(item.duration)
        mainAction._from = { startValue.f1, startValue.f2 }
        mainAction._to = { endValue.f1, endValue.f2 }
        mainAction._delta = get_delta(mainAction)
        mainAction.update = function(action, delta)
            local x = mainAction._to[1] - mainAction._delta[1] * (1 - delta)
            local y = mainAction._to[2] - mainAction._delta[2] * (1 - delta)

            item.value.f1 = x
            item.value.f2 = y

            self:applyValue(item, item.value)
        end
    elseif item.type == T.TransitionActionType.Alpha
            or item.type == T.TransitionActionType.Rotation
    then
        item.value.f1 = startValue.f1

        mainAction = GActionInterval.new()
        mainAction:setDuration(item.duration)
        mainAction._from = { startValue.f1 }
        mainAction._to = { endValue.f1 }
        mainAction._delta = get_delta(mainAction)
        mainAction.update = function(action, delta)
            local x = action._to[1] - action._delta[1] * (1 - delta)
            item.value.f1 = x
            self:applyValue(item, item.value)
        end
    elseif item.type == T.TransitionActionType.Color then
        item.value.c = startValue.c

        mainAction = GActionInterval.new()
        mainAction:setDuration(item.duration)
        mainAction._from = {
            item.value.c.r,
            item.value.c.g,
            item.value.c.b,
            item.value.c.a,
        }
        mainAction._to = {
            endValue.c.r,
            endValue.c.g,
            endValue.c.b,
            endValue.c.a,
        }

        mainAction._delta = get_delta(mainAction)
        mainAction.update = function(action, delta)
            local v1 = mainAction._to[1] - mainAction._delta[1] * (1 - delta)
            local v2 = mainAction._to[2] - mainAction._delta[2] * (1 - delta)
            local v3 = mainAction._to[3] - mainAction._delta[3] * (1 - delta)
            local v4 = mainAction._to[4] - mainAction._delta[4] * (1 - delta)

            item.value.c.r = v1
            item.value.c.g = v2
            item.value.c.b = v3
            item.value.c.a = v4
            self:applyValue(item, item.value)
        end

    elseif item.type == T.TransitionActionType.ColorFilter then
        item.value.f1 = startValue.f1
        item.value.f2 = startValue.f2
        item.value.f3 = startValue.f3
        item.value.f4 = startValue.f4

        mainAction = GActionInterval.new()
        mainAction:setDuration(item.duration)
        mainAction._from = {
            startValue.f1,
            startValue.f2,
            startValue.f3,
            startValue.f4,
        }
        mainAction._to = {
            endValue.f1,
            endValue.f2,
            endValue.f3,
            endValue.f4,
        }

        mainAction._delta = get_delta(mainAction)
        mainAction.update = function(action, delta)
            local v1 = mainAction._to[1] - mainAction._delta[1] * (1 - delta)
            local v2 = mainAction._to[2] - mainAction._delta[2] * (1 - delta)
            local v3 = mainAction._to[3] - mainAction._delta[3] * (1 - delta)
            local v4 = mainAction._to[4] - mainAction._delta[4] * (1 - delta)

            item.value.f1 = v1
            item.value.f2 = v2
            item.value.f3 = v3
            item.value.f4 = v4
            self:applyValue(item, item.value)
        end
    end


    --[[
    mainAction = createEaseAction(item->easeType, mainAction);
    if (item->repeat != 0)
        mainAction = RepeatYoyo::create(mainAction, item->repeat == -1 ? INT_MAX : (item->repeat + 1), item->yoyo);
    --]]

    --[[
    FiniteTimeAction* completeAction = CallFunc::create([this, item]() { tweenComplete(item); });
    if (delay > 0)
    {
        FiniteTimeAction* delayAction = DelayTime::create(delay);
        if (item->hook)
            mainAction = Sequence::create({ delayAction, CallFunc::create(item->hook), mainAction, completeAction });
        else
            mainAction = Sequence::create({ delayAction, mainAction, completeAction });
    }
    else
    {
        applyValue(item, item->value);
        if (item->hook)
            item->hook();

        mainAction = Sequence::createWithTwoActions(mainAction, completeAction);
    }
    --]]
    ---[[

    if delay > 0 then
        local seq = GSequence.new()

        local delayAction = GActionInterval.new()
        delayAction:setDuration(delay)
        delayAction.update = function()
        end
        delayAction.completeAction = function()
            if (item.hook) then
                item.hook()
            end
        end

        seq:setActions({ delayAction, mainAction })

        mainAction = seq

        mainAction.completeAction = function()
            self:tweenComplete(item)
        end
    else
        self:applyValue(item, item.value)
        if item.hook then
            item.hook()
        end

        mainAction.completeAction = function()
            self:tweenComplete(item)
        end
    end



    --]]

    --[[
    mainAction->setTag(ActionTag::TRANSITION_ACTION);
    _owner->displayObject()->runAction(mainAction);
    _totalTasks++;
    item->completed = false;
    --]]
    ---[[
    mainAction:setTag(T.ActionTag.TRANSITION_ACTION)
    UIRoot:getActionManager():addAction(mainAction, self._owner, false)
    self._totalTasks = self._totalTasks + 1
    item.completed = false
    --]]

end

---@param item TransitionItem
function M:stopItem(item, setToComplete)
    if item.displayLockToken ~= 0 then
        item.target:releaseDisplayLock(item.displayLockToken)
        item.displayLockToken = 0
    end

    if item.completed then
        return
    end

    if item.type == T.TransitionActionType.Transition then
        local trans = item.target:getTransition(item.value.s)
        if trans then
            trans:stop(setToComplete, false)
        end
    elseif item.type == T.TransitionActionType.Shake then
        --[[
        Director::getInstance()->getScheduler()->unschedule("-", item);

        item->target->_gearLocked = true;
        item->target->setPosition(item->target->getX() - item->startValue.f1, item->target->getY() - item->startValue.f2);
        item->target->_gearLocked = false;
        --]]
    else
        if (setToComplete) then
            if (item.tween == true) then
                if (item.yoyo == false or item.repeat_time % 2 == 0) then
                    self:applyValue(item, self._reversed and item.startValue or item.endValue)
                else
                    self:applyValue(item, self._reversed and item.endValue or item.startValue)
                end
            elseif (item.type ~= T.TransitionActionType.Sound) then
                self:applyValue(item, item.value)
            end

        end

    end

end

return M
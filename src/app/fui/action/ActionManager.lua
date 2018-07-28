local ActionHashElement = require("app.fui.action.ActionHashElement")

---@class ActionManager
---@field _currentTarget ActionHashElement
---@field _currentTargetSalvaged boolean
local M = class("ActionManager")

function M:ctor()
    self._targets = {}
    self._currentTarget = nil
    self._currentTargetSalvaged = false
end

function M:doDdoDestory()
    self:removeAllActions()
end


function M:update(dt)
    if #self._targets==0 then
        return
    end
    for i, v in ipairs(self._targets) do
        self._currentTarget = v
        self._currentTargetSalvaged = false

        if self._currentTarget.paused == false then
            for i, action in ipairs(self._currentTarget.actions) do
                self._currentTarget.currentAction = action

                self._currentTarget.currentActionSalvaged = false
                self._currentTarget.currentAction:step(dt)

                if self._currentTarget.currentActionSalvaged == true then
                elseif self._currentTarget.currentAction:isDone() then
                    self._currentTarget.currentAction:stop()
                    self:removeAction(self._currentTarget.currentAction)
                    self._currentTarget.currentAction = nil
                end
            end
        end

    end

    self._currentTarget = nil

end

local f = function(tb, target)
    for i = 1, #tb do
        if tb[i].target == target then
            return i
        end
    end
    return false
end

function M:removeAction(action)
    local target = action:getOriginalTarget()
    local ele
    local idx = f(self._targets, target)
    if idx == false then
        return
    else
        ele = self._targets[idx]
    end

    local actions = ele.actions
    table.removebyvalue(actions,action)
    if #actions==0 then
        table.remove(self._targets,idx)
    end
end

function M:removeActionByTag(tag,target)
    local ele
    local idx = f(self._targets, target)
    if idx == false then
        return
    else
        ele = self._targets[idx]
    end
    local actions = ele.actions

    local action
    for i, v in ipairs(actions) do
        if v:getTag()==tag then
            action = v
            break
        end
    end

    if action then
        table.removebyvalue(actions,action)
        if #actions==0 then
            table.remove(self._targets,idx)
        end
    end
end

function M:addAction(action, target, paused)
    local ele
    local idx = f(self._targets, target)
    if idx == false then
        ele = ActionHashElement.new()
        ele.target = target
        ele.paused = paused

        table.insert(self._targets, ele)
    else
        ele = self._targets[idx]
    end

    local actions = ele.actions
    table.insert(actions,action)

    action:startWithTarget(target)
end

--[[

---@param element ActionHashElement
function M:_deleteHashElement(element)

end

---@param element ActionHashElement
function M:_actionAllocWithHashElement(element)
    element.target:release()
end

---@param element ActionHashElement
function M:_removeActionAtIndex(index, element)
    local action = element.actions[index]

    if action == element.currentAction and element.currentActionSalvaged == false then
        element.currentActionSalvaged = true
    end

    table.remove(element.actions, index)

    -- update actionIndex in case we are in tick. looping over the actions
    if element.actionIndex >= index then
        element.actionIndex = element.actionIndex - 1
    end

    if #element.actions == 0 then
        if self._currentTarget == element then
            self._currentTargetSalvaged = true
        else
            self._deleteHashElement(element)
        end
    end

end
--]]

return M
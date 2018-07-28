local GActionInterval = require("app.fui.action.GActionInterval")

---@class GSequence:GActionInterval
local M = class("GSequence", GActionInterval)

function M:ctor()
    GActionInterval.ctor(self)
    self._actions = {}
    self._index = 1
end

function M:setActions(actions)
    self._actions = actions

    self._duration = 0
    for i, v in ipairs(self._actions) do
        self._duration = self._duration+v:getDuration()
    end
    self._index = 1
end

function M:step(dt)
    if self._firstTick == true then
        self._firstTick = false
        self._elapsed = 0
    else
        self._elapsed = self._elapsed + dt
    end

    local current_acton = self._actions[self._index]
    if current_acton._done == true and current_acton._firstTick==false then
        self._index = self._index + 1
    end

    current_acton:step(dt)

    self._done = (self._index>#self._actions)

    if self._done == true then
        if self.completeAction then
            self.completeAction()
        end
    end

end

return M
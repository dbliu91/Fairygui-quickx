local GFiniteTimeAction = require("app.fui.action.GFiniteTimeAction")

---@class GActionInterval:GFiniteTimeAction
local M = class("GActionInterval", GFiniteTimeAction)

function M:ctor()
    GFiniteTimeAction.ctor(self)
    self._elapsed = 0
    self._firstTick = true
    self._done = false
end

function M:isDone()
    return self._done
end

function M:startWithTarget(target)
    GFiniteTimeAction.startWithTarget(self, target)
    self._elapsed = 0
    self._firstTick = true
    self._done = false
end

function M:step(dt)
    if self._firstTick == true then
        self._firstTick = false
        self._elapsed = 0
    else
        self._elapsed = self._elapsed + dt
    end

    local updateDt = math.max(0, math.min(1, self._elapsed / self._duration))

    self:update(updateDt)

    self._done = (self._elapsed>=self._duration)

    if self._done == true then
        if self.completeAction then
            self.completeAction()
        end
    end

end

function M:reset_delta()
    local delta = {}
    for i = 1, #self._from do
        delta[i] = self._to[i] - self._from[i]
    end
    self._delta = delta
end

return M
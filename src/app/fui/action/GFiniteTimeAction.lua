local GAction = require("app.fui.action.GAction")

---@class GFiniteTimeAction:GAction
local M = class("GFiniteTimeAction",GAction)

function M:ctor()
    GAction.ctor(self)
    self._duration = 0
end

function M:getDuration()
    return self._duration
end

function M:setDuration(duration)
    self._duration = duration
end

return M
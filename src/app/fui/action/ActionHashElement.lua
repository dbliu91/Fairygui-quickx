---@class ActionHashElement
local M = class("ActionHashElement")

function M:ctor()
    self.actions = {}
    self.target = nil
    self.actionIndex = 0
    self.currentAction = nil
    self.currentActionSalvaged = false
    self.paused = false
end

return M
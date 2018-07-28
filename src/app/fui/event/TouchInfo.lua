---@class TouchInfo
local M = class("TouchInfo")

function M:ctor()
    self:reset()
end

function M:reset()
    self.downTargets = {}
    self.touchMonitors = {}

    self.touch = nil
    self.clickCount = 0

    self.touchId = 0
    self.mouseWheelDelta = 0
    self.button = 0
    self.pos = cc.p(0,0)
    self.downPos =  cc.p(0,0)
    self.lastClickTime = 0
    self.began = 0
    self.lastRollOver = nil
    self.clickCancelled = false

end



return M
local TransitionValue = require("app.fui.TransitionValue")

---@class TransitionItem
local M = class("TransitionItem")

function M:ctor()

    self.time = 0
    self.targetId = ""
    self.type = T.TransitionActionType.XY
    self.duration = 0
    self.value = TransitionValue.new()
    self.startValue = TransitionValue.new()
    self.endValue = TransitionValue.new()
    self.easeType = T.TweenType.Quad_EaseOut
    self.repeat_time = 0
    self.yoyo = false
    self.tween = false

    self.hook = nil
    self.hook2 = nil

    self.completed = false
    self.target = nil
    self.filterCreated = false
    self.displayLockToken = 0
end

return M
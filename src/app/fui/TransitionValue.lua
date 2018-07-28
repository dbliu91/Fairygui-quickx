---@class TransitionValue
local M = class("TransitionValue")

function M:ctor()
    self.f1 = 0
    self.f2 = 0
    self.f3 = 0
    self.f4 = 0
    self.i = 0
    self.b = false
    self.b1 = false
    self.b2 = false
    self.c = cc.c4b(0,0,0,255)
    self.s = ""
end

return M
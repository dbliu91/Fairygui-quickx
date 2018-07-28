---@class Margin
local M = class("Margin")

function M:ctor()
    self.left = 0
    self.top = 0
    self.right = 0
    self.bottom = 0
end

function M:setMargin(l, t, r, b)
    self.left = l
    self.top = t
    self.right = r
    self.bottom = b
end

return M
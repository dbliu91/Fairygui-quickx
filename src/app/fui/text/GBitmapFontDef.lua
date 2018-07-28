---@class GBitmapFontDef
local M = class("GBitmapFontDef")

function M:ctor()
    self.U = 0;
    self.V = 0;
    self.width = 0;
    self.height = 0;
    self.offsetX = 0;
    self.offsetY = 0;
    self.validDefinition = false;
    self.xAdvance = 0;
end

return M

---@class ItemInfo
---@field obj GObject
local ItemInfo = class("ItemInfo")

function ItemInfo:ctor()
    self.size = cc.p(0, 0)
    self.obj = nil
    self.updateFlag = 0
    self.selected = false
end

return ItemInfo
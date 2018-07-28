local GearBase = require("app.fui.gears.GearBase")

---@class GearText
local M = class("GearText",GearBase)

function M:ctor(...)
    M.super.ctor(self,...)

    self._storage = {}
    self._default = ""
end

function M:init()
    self._default = self._owner:getText()
    self._storage = {}
end

function M:addStatus(pageId,value)
    if not pageId or pageId=="" then
        self._default = value
    else
        self._storage[pageId]=value
    end
end

function M:apply()
    self._owner._gearLocked = true
    local v =  self._storage[self._controller:getSelectedPageId()]
    if v then
        self._owner:setText(v)
    else
        self._owner:setText(self._default)
    end
    self._owner._gearLocked = false
end

function M:updateState()
    self._storage[self._controller:getSelectedPageId()] = self._owner:getText()
end

return M
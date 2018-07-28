local GearBase = require("app.fui.gears.GearBase")

---@class GearIcon
local M = class("GearIcon",GearBase)

function M:ctor(...)
    M.super.ctor(self,...)

    self._storage = {}
    self._default = ""
end

function M:init()
    self._default = self._owner:getIcon()
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
        self._owner:setIcon(v)
    else
        self._owner:setIcon(self._default)
    end
    self._owner._gearLocked = false
end

function M:updateState()
    self._storage[self._controller:getSelectedPageId()] = self._owner:getIcon()
end





return M
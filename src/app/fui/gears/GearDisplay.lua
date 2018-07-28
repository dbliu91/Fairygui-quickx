local GearBase = require("app.fui.gears.GearBase")

---@class GearDisplay
---@field protected _visible number
local M = class("GearDisplay", GearBase)

function M:ctor(...)
    M.super.ctor(self,...)
    self._displayLockToken = 1
    self.pages = {}
    self._visible = 0
end

function M:apply()
    self._displayLockToken = self._displayLockToken + 1
    if self._displayLockToken == 0 then
        self._displayLockToken = 1
    end

    if #self.pages == 0
            or
            table.indexof(self.pages, self._controller:getSelectedPageId())~=false
    then
        self._visible = 1
    else
        self._visible = 0
    end
end

function M:updateState()

end

function M:addStatus(pageId,value)

end

function M:init()
    self.pages = {}
end

function M:addLock()
    self._visible = self._visible + 1
    return self._displayLockToken
end

function M:releaseLock(token)
    if token == self._displayLockToken then
        self._visible = self._visible - 1
    end
end

function M:isConnected()
    return self._controller==nil or self._visible>0
end

return M
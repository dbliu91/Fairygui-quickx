---@class GearBase
---@field protected _owner GObject
---@field protected _controller GController
---@field protected _displayLockToken number
local M = class("GearBase")

disableAllTweenEffect = false

function M:ctor(owner)
    self._owner = owner

    self.tweenTime = 0.3
    self.tween = false
    self.delay = 0
    self.easeType = T.TweenType.Quad_EaseOut
end

function M:getController()
    return self._controller
end

---@param value GController
function M:setController(value)
    if value ~= self._controller then
        self._controller = value
        if self._controller then
            self:init()
        end
    end
end

function M:init()

end

---@param pageId string
---@param value string
function M:addStatus(pageId,value)

end

function M:apply()

end

function M:updateState()

end

function M:updateFromRelations(dx,dy)

end

function M:setup(xml)
    local p = xml["@controller"]
    if p then
        self._controller = self._owner:getParent():getController(p)
        if not self._controller then
            return
        end
    end

    self:init()

    self.tween = (xml["@tween"]=="true")

    p = xml["@ease"]
    if p then
        self.easeType = p --TODO easeType = ToolSet::parseEaseType(p);
    end

    p = xml["@duration"]
    if p then
        self.tweenTime = checknumber(p)
    end

    p = xml["@delay"]
    if p then
        self.delay = checknumber(p)
    end

    local pages = {}
    p = xml["@pages"]
    if p then
        pages = string.split(p,",")
    end

    if iskindof(self,"GearDisplay") then
        self.pages = pages
    else
        if #pages>0 then
            local values = {}
            p = xml["@values"]
            if p then
                values = string.split(p,"|")

                local cnt1 = #pages
                local cnt2 = #values

                local str

                for i = 1, cnt1 do
                    if i<=cnt2 then
                        str = values[i]
                    else
                        str = ""
                    end
                    self:addStatus(pages[i],str)
                end

            end
        end

        p = xml["@default"]
        if p then
            self:addStatus("",p)
        end
    end

end

return M
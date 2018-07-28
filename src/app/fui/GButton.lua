local GComponent = require("app.fui.GComponent")

---@class GButton:GComponent
---@field protected _title string
---@field protected _selectedTitle string
---@field protected _icon string
---@field protected _selectedIcon string
local M = class("GButton", GComponent)

M.UP = "up";
M.DOWN = "down";
M.OVER = "over";
M.SELECTED_OVER = "selectedOver";
M.DISABLED = "disabled";
M.SELECTED_DISABLED = "selectedDisabled";

function M:ctor()

    M.super.ctor(self)

    self._mode = T.ButtonMode.COMMON

    self._titleObject = nil
    self._iconObject = nil
    self._buttonController = nil
    self._relatedController = nil
    self._selected = false
    self._over = false
    self._downEffect = 0
    self._downScaled = false
    self._downEffectValue = 0.8
    self._changeStateOnClick = true

    self._sound = UIConfig.buttonSound
    self._soundVolumeScale = UIConfig.buttonSoundVolumeScale

    self._title = ""
    self._selectedTitle = ""
    self._icon = ""
    self._selectedIcon = ""

end

---set-------------------------------------------

function M:setTitle(value)
    self._title = value
    if self._titleObject then
        local txt = (self._selected and self._selectedTitle and self._selectedTitle~="") and self._selectedTitle or self._title
        self._titleObject:setText(txt)
    end
    self:updateGear("gearText")
end

function M:setIcon(value)
    self._icon = value
    if self._iconObject then
        local icon = (self._selected and self._selectedIcon and self._selectedIcon~="") and self._selectedIcon or self._icon
        self._iconObject:setIcon(icon)
    end
    self:updateGear("gearIcon")
end

function M:setSelectedTitle(value)
    self._selectedTitle = value
    if self._titleObject then
        local txt = (self._selected and self._selectedTitle and self._selectedTitle~="") and self._selectedTitle or self._title
        self._titleObject:setText(txt)
    end
end

function M:setSelectedIcon(value)
    self._selectedIcon = value
    if self._iconObject then
        local icon = (self._selected and self._selectedIcon and self._selectedIcon~="") and self._selectedIcon or self._icon
        self._iconObject:setIcon(icon)
    end
end

function M:getTitleColor()
    if iskindof(self._titleObject, "GTextField") then
        return self._titleObject:getColor()
    elseif iskindof(self._titleObject, "GLabel") then
        return self._titleObject:getTitleColor()
    elseif iskindof(self._titleObject, "GButton") then
        return self._titleObject:getTitleColor()
    else
        return cc.c3b(0, 0, 0)
    end
end

---@param value Color3B
function M:setTitleColor(value)
    if iskindof(self._titleObject, "GTextField") then
        self._titleObject:setColor(value)
    elseif iskindof(self._titleObject, "GLabel") then
        self._titleObject:setTitleColor(value)
    elseif iskindof(self._titleObject, "GButton") then
        self._titleObject:setTitleColor(value)
    end
end

function M:getTitleFontSize()
    if iskindof(self._titleObject, "GTextField") then
        return self._titleObject:getFontSize()
    elseif iskindof(self._titleObject, "GLabel") then
        return self._titleObject:getTitleFontSize()
    elseif iskindof(self._titleObject, "GButton") then
        return self._titleObject:getTitleFontSize()
    else
        return 0
    end
end

function M:isSelected()
    return self._selected
end

function M:getRelatedController()
    return self._relatedController
end

function M:isChangeStateOnClick()
    return self._changeStateOnClick
end

function M:setChangeStateOnClick(value)
    self._changeStateOnClick = value
end

---@param value number
function M:setTitleFontSize(value)
    if iskindof(self._titleObject, "GTextField") then
        return self._titleObject:setFontSize(value)
    elseif iskindof(self._titleObject, "GLabel") then
        return self._titleObject:setTitleFontSize(value)
    elseif iskindof(self._titleObject, "GButton") then
        return self._titleObject:setTitleFontSize(value)
    end
end

---@param value boolean selected
function M:setSelected(value)
    if self._mode == T.ButtonMode.COMMON then
        return
    end

    if self._selected ~= value then
        self._selected = value

        self:setCurrentState()

        if self._selectedTitle ~= "" and self._titleObject then
            self._titleObject:setText(self._selected == true and self._selectedTitle or self._title)
        end

        if self._selectedIcon ~= "" then
            local str = self._selected and self._selectedIcon or self._icon
            if self._iconObject then
                self._iconObject:setIcon(str)
            end
        end

        if self._relatedController
                and self:getParent()
                and self:getParent()._buildingDisplayList == false then
            if self._selected == true then
                self._relatedController:setSelectedPageId(self._relatedPageId)
                if self._relatedController.autoRadioGroupDepth == true then
                    self:getParent():adjustRadioGroupDepth(self, self._relatedController)
                end
            elseif self._mode == T.ButtonMode.CHECK
                    and self._relatedController:getSelectedPageId() == self._relatedPageId then
                self._relatedController:setOppositePageId(self._relatedPageId)
            end
        end

    end

end

---@param c GController
function M:setRelatedController(c)
    self._relatedController = c
end

---@param value string
function M:setState(value)
    if self._buttonController then
        self._buttonController:setSelectedPage(value)
    end

    if self._downEffect == 1 then
    elseif self._downEffect == 2 then
        if value == M.DOWN or value == M.SELECTED_OVER or value == M.SELECTED_DISABLED then
            if self._downScaled == false then
                self._downScaled = true
                self:setScale(self:getScaleX() * self._downEffectValue, self:getScaleY() * self._downEffectValue)
            end
        else
            if self._downScaled == true then
                self._downScaled = false
                self:setScale(self:getScaleX() / self._downEffectValue, self:getScaleY() / self._downEffectValue)
            end
        end
    end
end

function M:setCurrentState()
    if self:isGrayed() == true and self._buttonController and self._buttonController:hasPage(M.DISABLED) then
        if self._selected then
            self:setState(M.SELECTED_DISABLED)
        else
            self:setState(M.DISABLED)
        end
    else
        if self._selected then
            self:setState((self._over == true) and M.SELECTED_OVER or M.DOWN)
        else
            self:setState((self._over == true) and M.OVER or M.UP)
        end
    end
end

function M:constructFromXML(xml)
    M.super.constructFromXML(self, xml)

    local x = xml.Button
    if x then
        local p = x["@mode"]
        if p then
            self._mode = p
        end

        local p = x["@sound"]
        if p then
            self._sound = p
        end

        local p = x["@volume"]
        if p then
            self._soundVolumeScale = checknumber(p) / 100
        end

        local p = x["@downEffect"]
        if p then
            if p == "dark" then
                self._downEffect = 1
            elseif p == "scale" then
                self._downEffect = 2
            else
                self._downEffect = 0
            end

            self._downEffectValue = checknumber(x["@downEffectValue"])

            if self._downEffect == 2 then
                self:setPivot(0.5, 0.5)
            end
        end

        self._buttonController = self:getController("button")
        self._titleObject = self:getChild("title")
        self._iconObject = self:getChild("icon")

        if self._titleObject then
            self._title = self._titleObject:getText()
        end
        if self._iconObject then
            self._icon = self._iconObject:getIcon()
        end

        if (self._mode == T.ButtonMode.COMMON) then
            self:setState(M.UP)
        end

        self:addEventListener(T.UIEventType.RollOver, handler(self, self.onRollOver))
        self:addEventListener(T.UIEventType.RollOut, handler(self, self.onRollOut))
        self:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onTouchBegin))
        self:addEventListener(T.UIEventType.TouchEnd, handler(self, self.onTouchEnd))
        self:addEventListener(T.UIEventType.Click, handler(self, self.onClick))
        self:addEventListener(T.UIEventType.Exit, handler(self, self.onExit))

    end
end

function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self, xml)

    local x = xml.Button
    if not x then
        return
    end

    local p = x["@title"]
    if p then
        self:setTitle(p)
    end

    p = x["@icon"]
    if p then
        self:setIcon(p)
    end

    p = x["@selectedTitle"]
    if p then
        self:setSelectedTitle(p)
    end

    p = x["@selectedIcon"]
    if p then
        self:setSelectedIcon(p)
    end

    p = x["@titleColor"]
    if p then
        local c = ToolSet.convertFromHtmlColor()
        self:setTitleColor(c)
    end

    p = x["@titleFontSize"]
    if p then
        self:setTitleFontSize(checkint(p))
    end

    p = x["@controller"]
    if p then
        self._relatedController = self:getParent():getController(p)
    end

    p = x["@page"]
    if p then
        self._relatedPageId = p
    end

    self:setSelected(x["@checked"] == "true")

    p = x["@sound"]
    if p then
        self._sound = p
    end

    p = x["@volume"]
    if p then
        self._soundVolumeScale = checknumber(p) / 100
    end
end

function M:handleControllerChanged(c)
    M.super.handleControllerChanged(self, c)

    if self._relatedController == c then
        self:setSelected(self._relatedPageId == c:getSelectedPageId())
    end
end

function M:onRollOver()
    if self._buttonController == nil or self._buttonController:hasPage(M.OVER) == false then
        return
    end

    self._over = true
    if self._down == true then
        return
    end

    if self:isGrayed() and self._buttonController:hasPage(M.DISABLED) then
        return
    end

    self:setState(self._selected == true and M.SELECTED_OVER or M.OVER)
end

function M:onRollOut()
    if self._buttonController == nil or self._buttonController:hasPage(M.OVER) == false then
        return
    end

    self._over = false
    if self._down == true then
        return
    end

    if self:isGrayed() and self._buttonController:hasPage(M.DISABLED) then
        return
    end

    self:setState(self._selected == true and M.DOWN or M.UP)
end

function M:onTouchBegin(context)

    self._down = true

    context:captureTouch();

    if self._mode == T.ButtonMode.COMMON then
        if self:isGrayed() == true and self._buttonController ~= nil and self._buttonController:hasPage(M.DISABLED) then
            self:setState(M.SELECTED_DISABLED)
        else
            self:setState(M.DOWN)
        end
    end
end

function M:onTouchEnd()
    if self._down == true then
        self._down = false
        if self._mode == T.ButtonMode.COMMON then
            if self:isGrayed() and self._buttonController ~= nil and self._buttonController:hasPage(M.DISABLED) then
                self:setState(M.DISABLED)
            elseif self._over == true then
                self:setState(M.OVER)
            else
                self:setState(M.UP)
            end
        else
            if self._over == false
                    and self._buttonController ~= nil
                    and (self._buttonController:getSelectedPage() == M.OVER
                    or self._buttonController:getSelectedPage() == M.SELECTED_OVER) then
                self:setCurrentState()
            end
        end
    end
end

function M:onClick()

    if self._sound and self._sound ~= "" then
        UIRoot:playSound(self._sound, self._soundVolumeScale)
    end

    if self._mode == T.ButtonMode.CHECK then
        if self._changeStateOnClick == true then
            self:setSelected(not self._selected)
            self:dispatchEvent(T.UIEventType.Changed)
        end
    elseif self._mode == T.ButtonMode.RADIO then
        if self._changeStateOnClick == true and self._selected == false then
            self:setSelected(true)
            self:dispatchEvent(T.UIEventType.Changed)
        end
    else
        if self._relatedController ~= nil then
            self._relatedController:setSelectedPageId(self._relatedPageId)
        end
    end

end

function M:onExit()
    if self._over == true then
        self:onRollOut()
    end
end

function M:getTitle()
    return self._title
end

function M:getText()
    return self._title
end

function M:setText(value)
    self:setTitle(value)
end

function M:getIcon()
    return self._icon
end

function M:getSelectedTitle()
    return self._selectedTitle
end

function M:getSelectedIcon()
    return self._selectedIcon
end

return M
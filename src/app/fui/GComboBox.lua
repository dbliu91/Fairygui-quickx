local GButton = require("app.fui.GButton")

local GComponent = require("app.fui.GComponent")

---@class GComboBox:GComponent
local M = class("GComboBox", GComponent)

function M:ctor()

    M.super.ctor(self)

    self._dropdown = nil
    self._titleObject = nil
    self._iconObject = nil
    self._list = nil
    self._selectionController = nil
    self._itemsUpdated = true
    self._selectedIndex = -1
    self.popupDirection = T.PopupDirection.AUTO
    self.visibleItemCount = UIConfig.defaultComboBoxVisibleItemCount

    self._items = {}
    self._icons = {}
    self._values = {}

    self._selectionController = nil
    self._buttonController = nil

    self._down = false
    self._over = false

end

function M:doDestory()
    M.super.doDestory(self)

    if self._dropdown then
        self._dropdown:doDestory()
    end
end

function M:getTitle()
    if self._titleObject then
        return self._titleObject:getText()
    else
        return ""
    end
end

function M:setTitle(value)
    if self._titleObject then
        self._titleObject:setText(value)
    end
    self:updateGear("gearText")
end

function M:getText()
    return self:getTitle()
end

function M:setText(value)
    self:setTitle(value)
end

function M:getIcon()
    if self._iconObject then
        return self._iconObject:getIcon()
    else
        return ""
    end
end

function M:setIcon(value)
    if self._iconObject then
        self._iconObject:setIcon(value)
    end
    self:updateGear("gearIcon")
end

function M:getValue()
    if self._selectedIndex > 0 and self._selectedIndex <= #self._values then
        return self._values[self._selectedIndex]
    end
    return ""
end

function M:setValue(value)
    local idx = table.indexof(self._values, value)
    if idx then
        self:setSelectedIndex(idx)
    end
end

function M:getSelectedIndex()
    return self._selectedIndex
end

function M:setSelectedIndex(value)
    if self._selectedIndex == value then
        return
    end

    self._selectedIndex = value

    if self._selectedIndex > 0 and self._selectedIndex <= #self._items then
        self:setText(self._items[self._selectedIndex])
        if #self._icons > 0 and self._selectedIndex ~= -1 and self._selectedIndex <= #self._icons then
            self:setIcon(self._icons[self._selectedIndex])
        end
    else
        self:setTitle("")
        if #self._icons > 0 then
            self:setIcon("")
        end
    end

    self:updateSelectionController()

end

function M:getSelectionController()
    return self._selectionController
end

function M:setSelectionController(value)
    self._selectionController = value
end

function M:getItems()
    return self._items
end

function M:getIcons()
    return self._icons
end

function M:getValues()
    return self._values
end

function M:refresh()
    if #self._items > 0 then
        if self._selectedIndex > #self._items then
            self._selectedIndex = #self._items
        elseif self._selectedIndex == -1 then
            self._selectedIndex = 1
        end

        self:setTitle(self._items[self._selectedIndex])
    else
        self:setTitle("")
        self._selectedIndex = -1
    end

    if #self._icons > 0 then
        if self._selectedIndex ~= -1 and self._selectedIndex <= self._icons then
            self:setIcon(self._icons[self._selectedIndex])
        else
            self:setIcon("")
        end
    end

    self._itemsUpdated = true

end

function M:constructFromXML(xml)
    M.super.ctor(xml)

    self._buttonController = self:getController("button")
    self._titleObject = self:getChild("title")
    self._iconObject = self:getChild("icon")

    xml = xml.ComboBox

    local p

    p = xml["@dropdown"]
    if p then
        self._dropdown = UIPackage.createObjectFromURL(p)
        if self._dropdown == nil then
            print("FairyGUI: should be a component.")
        end

        self._list = self._dropdown:getChild("list")
        if self._list == nil then
            print("FairyGUI: should container a list component named list.")
        end

        self._list:addEventListener(T.UIEventType.ClickItem, handler(self, self.onClickItem))

        self._list:addRelation(self._dropdown, T.RelationType.Width)
        self._list:removeRelation(self._dropdown, T.RelationType.Height)

        self._dropdown:addRelation(self._list, T.RelationType.Height)
        self._dropdown:removeRelation(self._list, T.RelationType.Width)

        self._dropdown:addEventListener(T.UIEventType.Exit, handler(self, self.onPopupWinClosed))

    end

    self:addEventListener(T.UIEventType.RollOver, handler(self, self.onRollover))
    self:addEventListener(T.UIEventType.RollOut, handler(self, self.onRollout))
    self:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onTouchBegin))
    self:addEventListener(T.UIEventType.TouchEnd, handler(self, self.onTouchEnd))
end

function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self, xml)

    xml = xml.ComboBox

    if xml == nil then
        return
    end

    local p

    local vc = checkint(xml["@visibleItemCount"])
    if vc ~= 0 then
        self.visibleItemCount = vc
    end

    p = xml["@direction"]
    if p then
        self.popupDirection = p
    end

    local hasIcon = false

    for i, v in ipairs(xml:children()) do
        if v:name() == "item" then
            local cxml = v

            p = cxml["@title"] or ""
            table.insert(self._items, p)

            p = cxml["@value"] or ""
            table.insert(self._values, p)

            p = cxml["@icon"] or ""
            table.insert(self._icons, p)
        end
    end

    p = xml["@title"]
    if p and p ~= "" then
        self:setTitle(p)
        self._selectedIndex = table.indexof(self._items, p) or -1
    elseif #self._items > 0 then
        self._selectedIndex = 1
        self:setTitle(self._items[1])
    else
        self._selectedIndex = -1
    end

    p = xml["@icon"]
    if p and p ~= "" then
        self:setIcon(p)
    end

    p = xml["@selectionController"]
    if p then
        self._selectionController = self._parent:getController(p)
    end

end

function M:handleControllerChanged(c)
    M.super.handleControllerChanged(self, c)
    if self._selectionController == c then
        self:setSelectedIndex(c:getSelectedIndex())
    end
end

function M:handleGrayedChanged()
    if self._buttonController and self._buttonController:hasPage(GButton.DISABLED) then
        if self:isGrayed() then
            self:setState(GButton.DISABLED)
        else
            self:setState(GButton.UP)
        end
    else
        M.super.handleGrayedChanged()
    end
end

function M:setState(value)
    if self._buttonController then
        self._buttonController:setSelectedPage(value)
    end
end

function M:setCurrentState()
    if self:isGrayed() and self._buttonController and self._buttonController:hasPage(GButton.DISABLED) then
        self:setState(GButton.DISABLED)
    elseif self._dropdown and self._dropdown:getParent() then
        self:setState(GButton.DOWN)
    else
        self:setState(self._over == true and GButton.OVER or GButton.UP)
    end
end

function M:updateSelectionController()
    if self._selectionController and self._selectionController.changing == false and self._selectedIndex <= self._selectionController:getParent() then
        local c = self._selectionController
        self._selectionController = nil
        c:setSelectedIndex(self._selectedIndex)
        self._selectionController = c
    end
end

function M:updateDropdownList()
    if self._itemsUpdated==true then
        self._itemsUpdated = false
        self:renderDropdownList()
        self._list:resizeToFit(self.visibleItemCount)
    end
end

function M:showDropdown()
    self:updateDropdownList()
    if self._list:getSelectionMode() == T.ListSelectionMode.SINGLE then
        self._list:setSelectedIndex(-1)
    end
    self._dropdown:setWidth(self._size.width)

    UIRoot:togglePopup(self._dropdown,self,self.popupDirection)

    if self._dropdown:getParent() then
        self:setState(GButton.DOWN)
    end

end

function M:renderDropdownList()
    self._list:removeChildrenToPool()
    local cnt = #self._items
    for i = 1, cnt do
        local item = self._list:addItemFromPool()
        item:setText(self._items[i])
        item:setIcon(self._icons[i])
        item.name = self._values[i]
    end
end

---@param context EventContext
function M:onClickItem(context)
    if iskindof(self._dropdown:getParent(),"GRoot") then
        self._dropdown:getParent():hidePopup(self._dropdown)
    end

    self._selectedIndex = nil
    self:setSelectedIndex(self._list:getChildIndex(context:getData()))

    self:dispatchEvent(T.UIEventType.Changed)

end

---@param context EventContext
function M:onRollover(context)
    self._over = true
    if self._down==true or (self._dropdown and self._dropdown:getParent()) then
        return
    end

    self:setCurrentState()
end

---@param context EventContext
function M:onRollout(context)
    self._over = false
    if self._down==true or (self._dropdown and self._dropdown:getParent()) then
        return
    end

    self:setCurrentState()
end

---@param context EventContext
function M:onTouchBegin(context)
    if iskindof(context:getInput():getTarget(),"GTextInput") then
        return
    end

    self._down = true

    if self._dropdown then
        self:showDropdown()
    end

    context:captureTouch()
end

---@param context EventContext
function M:onTouchEnd(context)
    if self._drop == true then
        self._drop = false
        if self._dropdown and self._dropdown:getParent() then
            self:setCurrentState()
        end
    end
end

function M:onPopupWinClosed(context)
    self:setCurrentState()
end


return M
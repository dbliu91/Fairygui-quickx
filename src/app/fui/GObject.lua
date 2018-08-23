---@type Relation
local Relations = require("app.fui.Relations")

---@type FUINode
local FUINode = require("app.fui.node.FUINode")

local GearDisplay = require("app.fui.gears.GearDisplay")
local GearXY = require("app.fui.gears.GearXY")
local GearSize = require("app.fui.gears.GearSize")
local GearLook = require("app.fui.gears.GearLook")
local GearColor = require("app.fui.gears.GearColor")
local GearAnimation = require("app.fui.gears.GearAnimation")
local GearText = require("app.fui.gears.GearText")
local GearIcon = require("app.fui.gears.GearIcon")

local UIEventDispatcher = require("app.fui.event.UIEventDispatcher")

---@class GObject:UIEventDispatcher
---
---@field public _underConstruct boolean
---
---@field public initSize cocos2d_Size
---@field public minSize cocos2d_Size
---@field public maxSize cocos2d_Size
---@field public sourceSize cocos2d_Size
---
---@field protected _packageItem PackageItem
---@field protected _position cocos2d_Vec2
---@field protected _size cocos2d_Size
---@field protected _rawSize cocos2d_Size
---@field protected _pivot cocos2d_Vec2
---@field protected _scale cocos2d_Vec2
---@field protected _parent GComponent

---@field protected _pivotAsAnchor boolean


---@field protected  _gears GearBase
---@field protected _relations Relations
---@field protected _group GGroup

---@field protected _sortingOrder number
---@field protected _displayObject cocos2d_Node

local M = class("GObject", UIEventDispatcher)

local __gInstanceCounter = 0
local __draggingObject

local __sGlobalDragStart = cc.p(0, 0)
local __sGlobalRect = cc.rect(0, 0, 0, 0)
local __sUpdateInDragging = false

M.getDraggingObject = function()
    return __draggingObject
end

-----init---------------------------------------------------------------------

function M:ctor()
    M.super.ctor(self)
    self._scale = cc.p(1, 1)
    self._sizePercentInGroup = 0
    self._pivotAsAnchor = false
    self._alpha = 1
    self._rotation = 0

    self._visible = true
    self._internalVisible = true
    self._handlingController = false
    self._touchable = true
    self._grayed = false
    self._finalGrayed = false
    self._draggable = false
    self._dragTesting = false
    self._sortingOrder = 0
    self._focusable = false
    self._pixelSnapping = false
    self._group = nil
    self._parent = nil
    self._displayObject = nil
    self._sizeImplType = 0
    self._underConstruct = false
    self._gearLocked = false
    self._gears = {}
    self._packageItem = nil
    self._data = nil
    self._touchDisabled = false
    self._isAdoptiveChild = false
    self._weakPtrRef = 0

    self._rawSize = cc.size(0, 0)

    self.sourceSize = cc.size(0, 0)
    self.initSize = cc.size(0, 0)
    self.minSize = cc.size(0, 0)
    self.maxSize = cc.size(0, 0)

    self._pivot = cc.p(0, 0)

    self._position = cc.p(0, 0)
    self._size = cc.size(0, 0)

    self._tooltips = ""

    self.uid = __gInstanceCounter
    __gInstanceCounter = __gInstanceCounter + 1

    self.id = tostring(self.uid)

    self._relations = Relations.new(self)


end

function M:doDestory()
    M.super.doDestory(self)

    GActionManager.inst():remove(self)

    self:removeFromParent()

    if self._displayObject then
        self._displayObject:removeFromParent()

        if tolua.isnull(self._displayObject) == false then
            self._displayObject:release()
        end

        self._displayObject = nil

    end


end

function M.create(C)
    local obj = C.new()
    return obj
end

function M:init(...)
    self:handleInit(...)

    self:setupDisplayObject()

    self:releaseXMLData()
end

function M:releaseXMLData()
    self._displayListItem = nil
end

function M:setupDisplayObject()
    if self._displayObject then
        self._displayObject:setAnchorPoint(cc.p(0, 1))
        self._displayObject:setCascadeOpacityEnabled(true)
        self._displayObject:setNodeEventEnabled(true)

        self._displayObject:registerScriptHandler(function(event)
            if "enter" == event then
                self:onEnter()
            elseif "exit" == event then
                self:onExit()
            elseif "cleanup" == event then
                self:onCleanup()
            end
        end)
    end
end



----get set------------------------------------------------------------

function M:getX()
    return self._position.x
end
function M:setX(value)
    self:setPosition(value, self._position.y)
end
function M:getY()
    return self._position.y
end
function M:setY(value)
    self:setPosition(self._position.x, value)
end
function M:getPosition()
    return self._position
end
function M:setPosition(xv, yv)
    if self._position.x ~= xv or self._position.y ~= yv then
        local dx = xv - self._position.x
        local dy = yv - self._position.y

        self._position.x = xv
        self._position.y = yv

        self:handlePositionChanged()

        if iskindof(self, "GGroup") then
            self:moveChildren(dx, dy)
        end

        self:updateGear("gearXY")

        if self._parent and iskindof(self._parent, "GList") == false then
            self._parent:setBoundsChangedFlag()

            if self._group then
                self._group:setBoundsChangedFlag()
            end

            self:dispatchEvent(T.UIEventType.PositionChange)

        end

        if __draggingObject == self and __sUpdateInDragging ~= true then
            __sGlobalRect = self:localToGlobal(cc.rect(0, 0, self._size.width, self._size.height))
        end

    end
end

function M:getXMin()
    return (self._pivotAsAnchor==true) and (self._position.x - self._size.width * self._pivot.x) or self._position.x;
end

function M:setXMin(value)
    if (self._pivotAsAnchor==true) then
        self:setPosition(value + self._size.width * self._pivot.x, self._position.y);
    else
        self:setPosition(value, self._position.y);
    end
end

function M:getYMin()
    return (self._pivotAsAnchor==true) and (self._position.y - self._size.height * self._pivot.y) or self._position.y;
end

function M:setYMin(value)
    if (self._pivotAsAnchor==true) then
        self:setPosition(self._position.x, value + self._size.height * self._pivot.y);
    else
        self:setPosition(self._position.x, value);
    end
end

function M:isPixelSnapping()
    return self._pixelSnapping
end

---@param value boolean
function M:setPixelSnapping(value)
    if self._pixelSnapping ~= value then
        self._pixelSnapping = value
        self:handlePositionChanged()
    end
end

function M:getWidth()
    return self._size.width
end
function M:getHeight()
    return self._size.height
end
function M:setWidth(value)
    self:setSize(value, self._rawSize.height)
end
function M:setHeight(value)
    self:setSize(self._rawSize.width, value)
end
function M:getSize()
    return self._size
end

---@param wv number 宽
---@param hv number 高
---@param ignorePivot boolean
function M:setSize(wv, hv, ignorePivot)

    wv = checkint(wv)
    hv = checkint(hv)

    if not ignorePivot then
        ignorePivot = false
    end

    if self._rawSize.width ~= wv or self._rawSize.height ~= hv then
        self._rawSize.width = wv
        self._rawSize.height = hv

        if (wv < self.minSize.width) then
            wv = self.minSize.width
        elseif (self.maxSize.width > 0 and wv > self.maxSize.width) then
            wv = self.maxSize.width
        end

        if (hv < self.minSize.height) then
            hv = self.minSize.height
        elseif (self.maxSize.height > 0 and hv > self.maxSize.height) then
            hv = self.maxSize.height
        end

        local dWidth = wv - self._size.width
        local dHeight = hv - self._size.height
        self._size.width = wv
        self._size.height = hv

        self:handleSizeChanged()

        if (self._pivot.x ~= 0 or self._pivot.y ~= 0) then
            if (self._pivotAsAnchor ~= true) then
                if (self.ignorePivot ~= true) then
                    self:setPosition(self._position.x - self._pivot.x * dWidth, self._position.y - self._pivot.y * dHeight)
                else
                    self:handlePositionChanged()
                end
            else
                self:handlePositionChanged()
            end
        else
            self:handlePositionChanged()
        end

        if iskindof(self, "GGroup") then
            self:resizeChildren(dWidth, dHeight)
        end

        self:updateGear("gearSize")

        if self._parent then
            self._relations:onOwnerSizeChanged(dWidth, dHeight,self._pivotAsAnchor==true or ignorePivot==false)
            self._parent:setBoundsChangedFlag()
            if self._group then
                self._group:setBoundsChangedFlag(true)
            end
        end

        self:dispatchEvent(T.UIEventType.SizeChange)

    end
end

function M:setSizeDirectly(wv, hv)
    self._rawSize.width = wv
    self._rawSize.height = hv
    if (wv < 0) then
        wv = 0

    end
    if (hv < 0) then
        hv = 0

    end
    self._size.width = wv
    self._size.height = hv
end

---@param restraint boolean
function M:center(restraint)
    if not restraint then
        restraint = false
    end

    ---@type GComponent
    local r
    if self._parent then
        r = self._parent
    else
        r = UIRoot
    end

    local x = (r._size.width - self._size.width) / 2
    local y = (r._size.height - self._size.height) / 2
    self:setPosition(checkint(x), checkint(y))
    if restraint == true then
        self:addRelation(r, T.RelationType.Center_Center)
        self:addRelation(r, T.RelationType.Middle_Middle)
    end
end

function M:makeFullScreen()
    self:setSize(UIRoot:getWidth(), UIRoot:getHeight())
end

function M:getPivot()
    return self._pivot
end

---@param asAnchor boolean
function M:setPivot(xv, yv, asAnchor)
    if asAnchor == nil then
        asAnchor = false
    end
    if self._pivot.x ~= xv or self._pivot ~= yv or self._pivotAsAnchor ~= asAnchor then
        self._pivot.x = xv
        self._pivot.y = yv
        self._pivotAsAnchor = asAnchor
        if self._displayObject then
            self._displayObject:setAnchorPoint(cc.p(self._pivot.x, 1 - self._pivot.y))
        end
        self:handlePositionChanged()
    end
end

function M:isPivotAsAnchor()
    return self._pivotAsAnchor
end

function M:getScaleX()
    return self._scale.x
end

function M:getScaleY()
    return self._scale.y
end

function M:setScaleX(value)
    self:setScale(value, self._scale.y)
end

function M:setScaleY(value)
    self:setScale(self._scale.x, value)
end

function M:getScale()
    return self._scale
end

function M:setScale(xv, yv)
    if self._scale.x ~= xv or self._scale.y ~= yv then
        self._scale.x = xv
        self._scale.y = yv
        self:handleScaleChanged()

        self:updateGear("gearSize")
    end
end

function M:getSkewX()
    return self._displayObject:getSkewX()
end

function M:getSkewY()
    return self._displayObject:getSkewY()
end

function M:setSkewX(value)
    self._displayObject:setSkewX(value)
end

function M:setSkewY(value)
    self._displayObject:setSkewY(value)
end

function M:getRotation(value)
    return self._rotation
end

function M:setRotation(value)
    if self._rotation ~= value then
        self._rotation = value
        self._displayObject:setRotation(self._rotation)
        self:updateGear("gearLook")
    end
end

function M:getAlpha()
    return self._alpha
end

function M:setAlpha(value)
    if self._alpha ~= value then
        self._alpha = value
        self:handleAlphaChanged()
        self:updateGear("gearLook")
    end
end

function M:isGrayed()
    return self._grayed
end

function M:setGrayed(value)
    if self._grayed ~= value or self._finalGrayed ~= value then
        self._grayed = value
        self:handleGrayedChanged()
        self:updateGear("gearLook")
    end
end

function M:isVisible()
    return self._visible
end

function M:setVisible(value)
    if self._visible ~= value then
        self._visible = value
        self:handleVisibleChanged()
        if self._parent then
            self._parent:setBoundsChangedFlag()
        end
    end
end

function M:internalVisible()
    return self._internalVisible == true and (self._group == nil or self._group:internalVisible() == true)
end

function M:internalVisible2()
    local v = self._visible == true and (self._group == nil or self._group:internalVisible2() == true)
    return v
end

function M:isTouchable()
    return self._touchable
end

---@param value boolean
function M:setTouchable(value)
    self._touchable = value
end

function M:getSortingOrder()
    return self._sortingOrder
end

function M:setSortingOrder(value)
    if (value < 0) then
        value = 0
    end
    if (self._sortingOrder ~= value) then
        local old = self._sortingOrder
        self._sortingOrder = value
        if (self._parent) then
            self._parent:childSortingOrderChanged(self, old, self._sortingOrder)
        end
    end
end

function M:getGroup()
    return self._group
end

---@param value GGroup
function M:setGroup(value)
    if self._group ~= value then
        if self._group then
            self._group:setBoundsChangedFlag(true)
        end
        self._group = value

        if self._group then
            self._group:setBoundsChangedFlag(true)
        end

        self:handleVisibleChanged()

        if self._parent then
            self._parent:childStateChanged(self)
        end
    end
end

function M:getText()
    return ""
end

---@param value string
function M:setText(value)
end

function M:getIcon()
    return ""
end

---@param value string
function M:setIcon(value)
end

function M:getTooltips()
    return self._tooltips
end

---@param value string
function M:setTooltips(value)
    self._tooltips = value
    if self._tooltips and self._tooltips ~= "" then
        self:addEventListener(T.UIEventType.RollOver, handler(self, self.onRollOver), self)
        self:addEventListener(T.UIEventType.RollOut, handler(self, self.onRollOut), self)
    end
end

function M:onRollOver(context)
    self:getRoot():showTooltips(self._tooltips)
end

function M:onRollOut(context)
    self:getRoot():hideTooltips()
end

function M:getData()
    return self._data
end

function M:setData(value)
    self._data = value
end

function M:getCustomData()
    return self._customData
end

function M:setCustomData(value)
    self._customData = value
end

function M:isDraggable()
    return self._draggable
end

---@param value boolean
function M:setDraggable(value)
    if self._draggable ~= value then
        self._draggable = value
        self:initDrag()
    end
end

function M:getDragBounds()
    return self._dragBounds
end

---@param value Rect
function M:setDragBounds(value)
    if self._dragBounds == nil then
        self._dragBounds = cc.rect(0,0,0,0)
    end

    self._dragBounds = clone(value)
end

---@return string
function M:getResourceURL()
    if self._packageItem then
        return "ui://" .. self._packageItem.owner:getId() .. self._packageItem.id
    else
        return ""
    end
end

---@param di DisplayListItem
function M:setPackageItem(pi,di)
    self._packageItem = pi
    self._displayListItem = di
end

----------------------------------------------------------------


------转换---------------------------------------------------------------------

---@param Vec2orRect Vec2|Rect
function M:localToGlobal(Vec2orRect)
    if Vec2orRect.width then
        local rect = Vec2orRect
        local v = self:localToGlobal(cc.p(rect.x, rect.y))
        local x = v.x
        local y = v.y
        v = self:localToGlobal(cc.p(rect.x + rect.width, rect.y + rect.height))

        local width = v.x - x
        local height = v.y - y
        return cc.rect(x, y, width, height)
    else
        local pt = clone(Vec2orRect)

        if self._pivotAsAnchor == true then
            pt.x = pt.x + self._size.width * self._pivot.x
            pt.y = pt.y + self._size.height * self._pivot.y
        end

        pt.y = self._size.height - pt.y
        pt = self._displayObject:convertToWorldSpace(pt)
        pt.y = UIRoot:getHeight() - pt.y
        return pt
    end
end

---@param Vec2orRect Vec2|Rect
function M:globalToLocal(Vec2orRect)
    if Vec2orRect.width then
        local rect = Vec2orRect
        local v = self:globalToLocal(cc.p(rect.x, rect.y))
        local x = v.x
        local y = v.y

        v = self:globalToLocal(cc.p(rect.x + rect.width, rect.y + rect.height))
        local width = v.x - x
        local height = v.y - y
        return cc.rect(x, y, width, height)
    else
        local pt = clone(Vec2orRect)

        pt.y = UIRoot:getHeight() - pt.y
        pt = self._displayObject:convertToNodeSpace(pt)
        pt.y = self._size.height - pt.y

        if self._pivotAsAnchor == true then
            pt.x = pt.x - self._size.width * self._pivot.x
            pt.y = pt.y - self._size.height * self._pivot.y
        end
        return pt
    end
end

---@param targetSpace GObject
---@param targetSpace GObject
function M:transformRect(rect, targetSpace)
    if targetSpace == self then
        return rect
    end

    if targetSpace == self._parent then
        return cc.rect(
                (self._position.x + rect.x) * self._scale.x,
                (self._position.y + rect.y) * self._scale.y,
                rect.width * self._scale.x,
                rect.height * self._scale.y
        )
    else
        local result = {}
        self:_transformRectPoint(cc.p(rect.x, rect.y), result, targetSpace);
        self:_transformRectPoint(cc.p(rect.x + rect.width, rect.y), result, targetSpace);
        self:_transformRectPoint(cc.p(rect.x, rect.y + rect.height), result, targetSpace);
        self:_transformRectPoint(cc.p(rect.x + rect.width, rect.y + rect.height), result, targetSpace);

        return cc.rect(
                result[1],
                result[2],
                result[3] - result[1],
                result[4] - result[2])
    end
end

---@param targetSpace GObject
---@param targetSpace GObject
function M:_transformRectPoint(pt, rect, targetSpace)

    local v = self:localToGlobal(pt)
    if targetSpace ~= nil then
        v = targetSpace:globalToLocal(v)
    end

    if rect[1] == nil then
        rect[1] = v.x
    end
    if rect[3] == nil then
        rect[3] = v.x
    end
    if rect[2] == nil then
        rect[2] = v.y
    end
    if rect[4] == nil then
        rect[4] = v.y
    end
    --最右上角的点
    rect[1] = math.min(rect[1], v.x)
    rect[2] = math.min(rect[2], v.y)

    --最左下角的点
    rect[3] = math.max(rect[3], v.x)
    rect[4] = math.max(rect[4], v.y)

end


-------------------------------------------------------



-------------------------------------------------------



function M:relations()
    return self._relations
end

function M:addRelation(target, relationType, usePercent)
    self._relations:add(target, relationType, usePercent)
end

function M:removeRelation(target, relationType)
    self._relations:remove(target, relationType)
end

function M:getGear(name)
    local name_GearClass_kv_map = {
        gearDisplay = GearDisplay;
        gearXY = GearXY;
        gearSize = GearSize;
        gearLook = GearLook;
        gearColor = GearColor;
        gearAnimation = GearAnimation;
        gearText = GearText;
        gearIcon = GearIcon;
    }

    local gear = self._gears[name]
    if gear == nil then
        local C = name_GearClass_kv_map[name]
        if C then
            gear = C.new(self)
            self._gears[name] = gear
        end
    end

    return self._gears[name]
end

---@param name string
--- - gearDisplay 0
--- - gearXY 1
--- - gearSize 2
--- - gearLook 3
--- - gearColor 4
--- - gearAni 5
--- - gearText 6
--- - gearIcon 7
function M:updateGear(name)
    if self._underConstruct == true or self._gearLocked == true then
        return
    end

    local gear = self._gears[name]
    if gear and gear:getController() then
        gear:updateState()
    end

end

---@param c GController
function M:checkGearController(name, c)
    if self._gears[name] and self._gears[name]:getController() == c then
        return true
    else
        return false
    end
end

function M:updateGearFromRelations(name, dx, dy)
    if self._gears[name] then
        self._gears[name]:updateFromRelations(dx, dy)
    end
end

function M:addDisplayLock()
    local gearDisplay = self._gears["gearDisplay"]
    if gearDisplay and gearDisplay:getController() then
        local ret = gearDisplay:addLock()
        self:checkGearDisplay()

        return ret
    else

        return 0
    end
end

function M:releaseDisplayLock(token)
    local gearDisplay = self._gears["gearDisplay"]
    if gearDisplay and gearDisplay:getController() then
        gearDisplay:releaseLock(token)
        self:checkGearDisplay()
    end
end

function M:checkGearDisplay()
    if self._handlingController == true then
        return
    end

    local connected = (self._gears["gearDisplay"] == nil) or self._gears["gearDisplay"]:isConnected()
    if connected ~= self._internalVisible then
        self._internalVisible = connected
        if self._parent then
            self._parent:childStateChanged(self)
        end
    end
end

function M:getParent()
    return self._parent
end

function M:displayObject()
    return self._displayObject
end

function M:onStage()
    return self._displayObject and tolua.isnull(self._displayObject)==false and self._displayObject:getScene() ~= nil
end

function M:getRoot()
    local p = self
    while p._parent ~= nil do
        p = p._parent
    end

    if iskindof(p, "GRoot") then
        return p
    else
        return UIRoot
    end
end

function M:removeFromParent()
    if self._parent then
        self._parent:removeChild(self);
    end
end

function M:addClickListener(callback, tag)
    self:addEventListener(T.UIEventType.Click, callback, tag)
end

function M:removeClickListener(tag)
    self:removeEventListener(T.UIEventType.Click, tag)
end

function M:constructFromResource()

end

function M:hitTest(worldPoint)

    if self._touchDisabled == true
            or self._touchable == false
            or self._displayObject:isVisible() == false
            or self._displayObject:getParent() == nil
    then
        return nil
    end

    local rect = cc.rect(0, 0, self._size.width, self._size.height)
    local p = self._displayObject:convertToNodeSpace(worldPoint)
    if cc.rectContainsPoint(rect, p) == true then
        return self
    else
        return nil
    end

end

function M:handleInit()
    self._displayObject = FUINode.new()
    self._displayObject:retain()
    UIPackage.markForRelease(self._displayObject,self.__cname)
end

function M:onEnter()
    self:dispatchEvent(T.UIEventType.Enter)
    GActionManager.inst():resume(self)
end

function M:onExit()
    self:dispatchEvent(T.UIEventType.Exit)
    GActionManager.inst():pause(self)
end

function M:onCleanup()

end


-----handle------------------------------------------------------

function M:handlePositionChanged()

    if self._displayObject then
        local pt = clone(self._position)
        pt.y = -pt.y
        if self._pivotAsAnchor == false then
            pt.x = pt.x + self._size.width * self._pivot.x
            pt.y = pt.y - self._size.height * self._pivot.y
        end

        if (self._isAdoptiveChild == true) then
            if (self._displayObject:getParent()) then
                pt.y = pt.y + self._displayObject:getParent():getContentSize().height
            elseif (self._parent) then
                pt.y = pt.y + self._parent._size.height
            end
        end

        if (self._pixelSnapping == true) then
            pt.x = checkint(pt.x)
            pt.y = checkint(pt.y)
        end
        self._displayObject:setPosition(pt)
    end
end

function M:handleSizeChanged()
    if (self._displayObject) then
        if (self._sizeImplType == 0 or self.sourceSize.width == 0 or self.sourceSize.height == 0) then
            self._displayObject:setContentSize(self._size)
        else
            self._displayObject:setScale(
                    self._scale.x * self._size.width / self.sourceSize.width,
                    self._scale.y * self._size.height / self.sourceSize.height
            )
        end
    end
end

function M:handleScaleChanged()
    if self._sizeImplType == 0 or self.sourceSize.width == 0 or self.sourceSize.height == 0 then
        self._displayObject:setScale(self._scale.x, self._scale.y)
    else
        self._displayObject:setScale(
                self._scale.x * self._size.width / self.sourceSize.width,
                self._scale.y * self._size.height / self.sourceSize.height)
    end
end

function M:handleAlphaChanged()
    self._displayObject:setOpacity(self._alpha * 255)
end

function M:handleGrayedChanged()
    self._finalGrayed = (self._parent and self._parent._finalGrayed) or self._grayed
end

function M:handleVisibleChanged()
    self._displayObject:setVisible(self:internalVisible2())
end

function M:handleControllerChanged(c)
    self._handlingController = true
    for k, gear in pairs(self._gears) do
        if gear:getController() == c then
            gear:apply()
        end
    end
    self._handlingController = false

    self:checkGearDisplay()
end

---@overload
---@param xml XMLSample
function M:setup_BeforeAdd(xml)
    self.id = xml["@id"]
    self.name = xml["@name"]

    local p = xml["@xy"]
    if p then
        local v2 = string.split(p, ',')
        local x = checkint(v2[1])
        local y = checkint(v2[2])
        self:setPosition(x, y)
    end

    p = xml["@size"]
    if p then
        local v2 = string.split(p, ',')
        local x = checkint(v2[1])
        local y = checkint(v2[2])
        self.initSize = cc.size(x, y)
        self:setSize(x, y, true)
    end

    p = xml["@restrictSize"]
    if p then
        local v2 = string.split(p, ',')
        local x = checkint(v2[1])
        local y = checkint(v2[2])
        self.minSize = cc.size(x, y)

        local x = checkint(v2[3])
        local y = checkint(v2[4])
        self.maxSize = cc.size(x, y)
    end

    p = xml["@scale"]
    if p then
        local v2 = string.split(p, ',')
        local x = checknumber(v2[1])
        local y = checknumber(v2[2])
        self:setScale(x, y)
    end

    p = xml["@skew"]
    if p then
        local v2 = string.split(p, ',')
        local x = checkint(v2[1])
        local y = checkint(v2[2])
        self:setSkewX(x)
        self:setSkewY(y)
    end

    p = xml["@rotation"]
    if p then
        local x = checkint(p)
        self:setRotation(x)
    end

    p = xml["@pivot"]
    if p then
        local v2 = string.split(p, ',')
        local x = checknumber(v2[1]) or 0
        local y = checknumber(v2[2]) or 0
        local anchor = (xml["@anchor"] == "true")
        self:setPivot(x, y, anchor)
    end

    p = xml["@alpha"]
    if p then
        local x = checknumber(p)
        self:setAlpha(x)
    end

    p = xml["@touchable"]
    if p then
        local touchable = (p == "true")
        self:setTouchable(touchable)
    end

    p = xml["@visible"]
    if p then
        local visible = (p == "true")
        self:setVisible(visible)
    end

    p = xml["@grayed"]
    if p then
        local grayed = (p == "true")
        self:setGrayed(grayed)
    end

    p = xml["@tooltips"]
    if p then
        self:setTooltips(p)
    end

    p = xml["@customData"]
    if p then
        self._customData = p
    end
end

---@param xml XMLSample
function M:setup_AfterAdd(xml)
    local p = xml["@group"]
    if p then
        self._group = self._parent:getChildById(p)
    end

    for i, exml in ipairs(xml:children()) do
        local gear_name = exml:name()
        local gear = self:getGear(gear_name)
        if gear then
            gear:setup(exml)
        end
    end
end

---拖拽相关---------------------------------------------------

function M:initDrag()
    if self._draggable == true then
        self:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onTouchBeginWhenDrag), self)
        self:addEventListener(T.UIEventType.TouchMove, handler(self, self.onTouchMoveWhenDrag), self)
        self:addEventListener(T.UIEventType.TouchEnd, handler(self, self.onTouchEndWhenDrag), self)
    else
        self:removeEventListener(T.UIEventType.TouchBegin, self)
        self:removeEventListener(T.UIEventType.TouchMove, self)
        self:removeEventListener(T.UIEventType.TouchEnd, self)
    end
end

function M:startDrag(touchId)
    self:dragBegin(touchId)
end

function M:stopDrag()
    self:dragEnd()
end

function M:dragBegin(touchId)

    if (__draggingObject ~= nil) then
        local tmp = __draggingObject;
        __draggingObject:stopDrag()
        __draggingObject = nil
        tmp:dispatchEvent(T.UIEventType.DragEnd)
    end

    __sGlobalDragStart = UIRoot:getTouchPosition(touchId);
    __sGlobalRect= self:localToGlobal(cc.rect(0,0, self._size.width,self._size.height));

    __draggingObject = self;
    self._dragTesting = true;

    UIRoot:getInputProcessor():addTouchMonitor(touchId, self);

    self:addEventListener(T.UIEventType.TouchMove, handler(self,self.onTouchMoveWhenDrag), self);
    self:addEventListener(T.UIEventType.TouchEnd, handler(self,self.onTouchEndWhenDrag), self);

end

function M:dragEnd()
    if __draggingObject == self then
        self._dragTesting = false
        __draggingObject = nil
    end
end

function M:onTouchBeginWhenDrag(context)
    self._dragTouchStartPos = clone(context:getInput():getPosition());
    self._dragTesting = true;
    context:captureTouch();
end

function M:onTouchMoveWhenDrag(context)

    local evt = context:getInput();

    if (__draggingObject ~= self and self._draggable == true and self._dragTesting == true) then
        local sensitivity = UIConfig.touchDragSensitivity;
        --local sensitivity = UIConfig.clickDragSensitivity;

        print(self._dragTouchStartPos.x,self._dragTouchStartPos.y,evt:getPosition().x,evt:getPosition().y)

        if (math.abs(self._dragTouchStartPos.x - evt:getPosition().x) < sensitivity
                and
                math.abs(self._dragTouchStartPos.y - evt:getPosition().y) < sensitivity) then
            return ;
        end

        self._dragTesting = false;

        if (false == self:dispatchEvent(T.UIEventType.DragStart)) then
            self:dragBegin(evt:getTouchId());
        end
    end

    if (__draggingObject == self) then
        local xx = evt:getPosition().x - __sGlobalDragStart.x + __sGlobalRect.x;
        local yy = evt:getPosition().y - __sGlobalDragStart.y + __sGlobalRect.y;

        if (self._dragBounds ~= nil) then
            local rect = UIRoot:localToGlobal(self._dragBounds);
            if xx<rect.x then
                xx = rect.x
            elseif (xx + __sGlobalRect.width > (rect.x+rect.width)) then
                xx = (rect.x+rect.width) - __sGlobalRect.width;
                if (xx < rect.x) then
                    xx = rect.x;
                end
            end

            if yy<rect.y then
                yy = rect.y
            elseif (yy + __sGlobalRect.height > (rect.y+rect.height)) then
                yy = (rect.y+rect.height) - __sGlobalRect.height;
                if (yy < rect.y) then
                    yy = rect.y;
                end
            end

        end

        local pt = self._parent:globalToLocal(cc.p(xx, yy));
        __sUpdateInDragging = true;
        self:setPosition(math.round(pt.x), math.round(pt.y));
        __sUpdateInDragging = false;

        self:dispatchEvent(T.UIEventType.DragMove);

    end

end

function M:onTouchEndWhenDrag(context)
    if (__draggingObject == self) then
        __draggingObject = nil;
        self:dispatchEvent(T.UIEventType.DragEnd);
    end
end

-------------------------------------------------------------------------



return M
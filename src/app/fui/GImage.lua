--TODO scale9的置灰做不了。。。

local GObject = require("app.fui.GObject")

---@type FUISprite
local FUISprite = require("app.fui.node.FUISprite")

---@class GImage:GObject
local M = class("GImage", GObject)

function M:ctor()
    M.super.ctor(self)

    self._content = nil
    self._touchDisabled = true
end

function M:handleInit()

    local SpriteClass = ccui.Scale9Sprite

    if self._packageItem then
        if self._packageItem.scale9Grid then
            SpriteClass = ccui.Scale9Sprite
        elseif self._packageItem.scaleByTile == true then
            SpriteClass = cc.Sprite
        else
            SpriteClass = ccui.Scale9Sprite
        end
    end

    self._SpriteClass = SpriteClass

    self._content = FUISprite.new(self._SpriteClass)
    self._content:retain()
    UIPackage.markForRelease(self._content,self.__cname)

    self._displayObject = self._content
end

function M:getFlip()
    if self._content:isFlippedX() and self._content:isFlippedY() then
        return T.FlipType.BOTH
    elseif self._content:isFlippedX() then
        return T.FlipType.HORIZONTAL
    elseif self._content:isFlippedY() then
        return T.FlipType.VERTICAL
    else
        return T.FlipType.NONE
    end
end

function M:setFlip(value)
    self._content:setFlippedX(value == T.FlipType.HORIZONTAL or value == T.FlipType.BOTH)
    self._content:setFlippedY(value == T.FlipType.VERTICAL or value == T.FlipType.BOTH)

    self:handlePositionChanged()
end

function M:handleSizeChanged()
    if self._packageItem.scaleByTile == true then
        if self._SpriteClass == cc.Sprite then
            self._content:setTextureRect(cc.rect(0, 0, self._size.width, self._size.height))
        else
            --self._content:setContentSize(self._size)
        end
    else
        self._content:setContentSize(self._size)
    end
end

function M:handleGrayedChanged()
    M.super.handleGrayedChanged(self)
    self._content:setGrayed(self._finalGrayed)
end

function M:getColor()
    return self._content:getColor()
end

---@param value Color3B
function M:setColor(value)
    self._content:setColor(value)
end

function M:cg_getColor()
    return self._content:getColor()
end

---@param value Color4B
function M:cg_setColor(value)
    self._content:setColor(value)
end

function M:constructFromResource()
    self.sourceSize.width = self._packageItem.width
    self.sourceSize.height = self._packageItem.height
    self.initSize = self.sourceSize

    self._content:setSpriteFrame(self._packageItem.spriteFrame)
    if self._packageItem.scale9Grid then
        self._content:setScale9Grid(self._packageItem.scale9Grid)
    else
        if self._SpriteClass == ccui.Scale9Sprite then
            self._content:setCapInsets(cc.rect(0, 0, self.sourceSize.width, self.sourceSize.height))
        end
    end

    self:setSize(self.sourceSize.width, self.sourceSize.height)
end

---@overload
function M:setup_BeforeAdd(xml)
    M.super.setup_BeforeAdd(self, xml)

    local p = xml["@flip"]
    if p then
        self:setFlip(p)
    end

    local p = xml["@color"]
    if p then
        self:setColor(ToolSet.convertFromHtmlColor(p))
    end
end

function M:handlePositionChanged()
    M.super.handlePositionChanged(self)

    if self._SpriteClass ~= cc.Sprite then
        --add by liu: 因为ccui.Scale9Sprite的bug，导致flip属性会导致坐标出问题。。。fuck
        if self._content:isFlippedX() == true then
            self._displayObject:setPositionX(self._displayObject:getPositionX() + self._size.width)
        end

        if self._content:isFlippedY() == true then
            self._displayObject:setPositionY(self._displayObject:getPositionY() - self._size.height)
        end
    end

end

return M
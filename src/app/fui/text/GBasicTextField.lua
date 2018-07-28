local FUILabel = require("app.fui.node.FUILabel")

local GTextField = require("app.fui.text.GTextField")

local GBitmapText = require("app.fui.text.GBitmapText")

---@class GBasicTextField:GTextField
---@field protected _label FUILabel
---@field protected _autoSize TextAutoSize
---@field protected _updatingSize boolean
local M = class("GBasicTextField", GTextField)

function M:ctor()
    M.super.ctor(self)
    self._label = nil
    self._autoSize = T.TextAutoSize.BOTH
    self._updatingSize = false
    self._touchDisabled = true
end

function M:handleInit()

    local is_bitmap_font = false
    if self._displayListItem and self._displayListItem.desc["@font"] then
        local x = self._displayListItem.desc["@font"]
        if string.find(x, "ui://") then
            is_bitmap_font = true
        end
    end

    if is_bitmap_font ==false then
        self._label = FUILabel.new()
        self._label:retain()
    else
        self._label = GBitmapText.new()
        self._label:retain()
    end
    UIPackage.markForRelease(self._label,self.__cname)

    self._displayObject = self._label
end

function M:getText()
    return self._label:getString()
end

function M:setText(value)
    self._label:setString(value)
    if self._underConstruct == false then
        self:updateSize()
    end
end

function M:getAutoSize()
    return self._autoSize
end

---@param value TextAutoSize
function M:setAutoSize(value)
    self._autoSize = value

    --TODO
    --[[
    switch (value)
    {
    case TextAutoSize::NONE:
        _label->setOverflow(Label::Overflow::CLAMP);
        break;
    case TextAutoSize::BOTH:
        _label->setOverflow(Label::Overflow::NONE);
        break;
    case TextAutoSize::HEIGHT:
        _label->setOverflow(Label::Overflow::RESIZE_HEIGHT);
        break;
    case TextAutoSize::SHRINK:
        _label->setOverflow(Label::Overflow::SHRINK);
        break;
    }
    --]]

    if self._autoSize == T.TextAutoSize.BOTH then
        self._label:setDimensions(0, 0)
    elseif self._autoSize == T.TextAutoSize.HEIGHT then
        self._label:setDimensions(self._size.width, 0)
    else
        self._label:setDimensions(self._size.width, self._size.height)
    end

    if self._underConstruct == false then
        self:updateSize()
    end
end

function M:isSingleLine()
    return self._label:isWrapEnabled();
end

function M:setSingleLine(value)
    self._label:enableWrap(not value);
    if self._underConstruct == false then
        self:updateSize()
    end
end

function M:updateSize()
    if self._updatingSize == true then
        return
    end

    self._updatingSize = true

    local sz = self._label:getContentSize()
    if self._autoSize == T.TextAutoSize.BOTH then
        self:setSize(sz.width, sz.height)
    elseif self._autoSize == T.TextAutoSize.HEIGHT then
        self:setHeight(sz.height)
    end

    self._updatingSize = false

end

function M:getTextFormat()
    return self._label:getTextFormat()
end

function M:applyTextFormat()
    self._label:applyTextFormat()
    self:updateGear("gearColor")
    if self._underConstruct == false then
        self:updateSize()
    end
end

function M:handleSizeChanged()
    if self._updatingSize == true then
        return
    end

    if self._autoSize ~= T.TextAutoSize.BOTH then
        self._label:setDimensions(self._size.width, self._size.height)

        if self._autoSize == T.TextAutoSize.HEIGHT then
            if string.len(self._label:getString()) > 0 then
                self:setSizeDirectly(self._size.width, self._label:getContentSize().height)
            end
        end
    end
end

--[[

--]]

return M
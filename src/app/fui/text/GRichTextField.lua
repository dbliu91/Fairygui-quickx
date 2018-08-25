local GTextField = require("app.fui.text.GTextField")

local FUIRichText = require("app.fui.node.FUIRichText")

---@class GRichTextField:GTextField
local M = class("GRichTextField",GTextField)

function M:ctor()
    M.super.ctor(self)
    self._richText = nil
    self._updatingSize = false
    self._autoSize = T.TextAutoSize.BOTH
end

function M:getText()
    return self._richText:getText()
end

function M:setText(value)
    self._richText:setText(value);
    if (self._underConstruct==false) then
        self:updateSize();
    end
end

function M:isUBBEnabled()
    return self._richText:isUBBEnabled()
end

function M:setUBBEnabled(value)
    self._richText:setUBBEnabled(value);
end

function M:getAutoSize()
    return self._autoSize
end

function M:setAutoSize(value)
    self._autoSize = value;
    --[[
    switch (value)
    {
    case TextAutoSize::NONE:
        _richText->setOverflow(Label::Overflow::CLAMP);
        break;
    case TextAutoSize::BOTH:
        _richText->setOverflow(Label::Overflow::NONE);
        break;
    case TextAutoSize::HEIGHT:
        _richText->setOverflow(Label::Overflow::RESIZE_HEIGHT);
        break;
    case TextAutoSize::SHRINK:
        _richText->setOverflow(Label::Overflow::SHRINK);
        break;
    }

    --]]
    self._richText:setDimensions(self._size.width, self._size.height);
    if (self._underConstruct==false) then
        self:updateSize();
    end
end

function M:isSingleLine()
    return false
end

function M:setSingleLine()

end

function M:getTextFormat()
    return self._richText:getTextFormat()
end

function M:applyTextFormat()
    self._richText:applyTextFormat()
    self:updateGear("GearColor");
    if (self._underConstruct==false) then
        self:updateSize();
    end
end

function M:handleInit()
    self._richText = FUIRichText.new()
    self._richText:retain()
    self._richText:setCascadeOpacityEnabled(true)

    UIPackage.markForRelease(self._richText,self.__cname)

    self._displayObject = self._richText
end

function M:handleSizeChanged()
    if self._updatingSize==true then
        return
    end

    if (self._autoSize ~= T.TextAutoSize.BOTH) then
        self._richText:setDimensions(self._size.width, self._size.height);

        if (self._autoSize == T.TextAutoSize.HEIGHT) then
            if (string.len(self._richText:getText())>0) then
                self:setSizeDirectly(self._size.width, self._richText:getContentSize().height);
            end
        end
    end
end

function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self,xml)

    self:updateSize()
end

function M:updateSize()
    if self._updatingSize==true then
        return
    end

    self._updatingSize = true

    local sz = self._richText:getContentSize()
    if self._autoSize == T.TextAutoSize.BOTH then
        self:setSize(sz.width, sz.height)
    elseif self._autoSize == T.TextAutoSize.HEIGHT then
        self:setHeight(sz.height)
    end

    self._updatingSize = false
end

--[[
void GRichTextField::updateSize()
{
    if (_updatingSize)
        return;

    _updatingSize = true;

    Size sz = _richText->getContentSize();
    if (_autoSize == TextAutoSize::BOTH)
        setSize(sz.width, sz.height);
    else if (_autoSize == TextAutoSize::HEIGHT)
        setHeight(sz.height);

    _updatingSize = false;
}
--]]

return M
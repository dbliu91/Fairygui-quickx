local GObject = require("app.fui.GObject")

---@class GTextField:GObject
local M = class("GTextField",GObject)

---@overload
function M:setup_BeforeAdd(xml)
    M.super.setup_BeforeAdd(self,xml)

    ---@type TextFormat
    local tf = self:getTextFormat()

    local p = xml["@font"]
    if p then
        tf.face = p
    end

    local p = xml["@fontSize"]
    if p then
        tf.fontSize = checkint(p)
    end

    local p = xml["@color"]
    if p then
        tf.color = ToolSet.convertFromHtmlColor(p)
    end

    local p = xml["@align"]
    if p then
        tf.align = ToolSet.parseAlign(p)
    end

    local p = xml["@vAlign"]
    if p then
        tf.verticalAlign = ToolSet.parseVerticalAlign(p)
    end

    local p = xml["@leading"]
    if p then
        tf.lineSpacing = checkint(p)
    end

    local p = xml["@letterSpacing"]
    if p then
        tf.letterSpacing = checkint(p)
    end

    local p = xml["@ubb"]
    if p then
        self:setUBBEnabled(p=="true")
    end

    local p = xml["@autoSize"]
    if p then
        self:setAutoSize(p)
    end

    local p = xml["@underline"]
    if p then
        tf.underline = (p=="true")
    end

    local p = xml["@italic"]
    if p then
        tf.italics = (p=="true")
    end

    local p = xml["@bold"]
    if p then
        tf.bold = (p=="true")
    end

    local p = xml["@singleLine"]
    if p then
        self:setSingleLine(p=="true")
    end

    local p = xml["@strokeColor"]
    if p then
        tf.outlineColor = ToolSet.convertFromHtmlColor(p)

        p = xml["@strokeSize"]
        tf.outlineSize = p and checkint(p) or 1
        tf:enableEffect(TextFormat.OUTLINE)
    end

    local p = xml["@shadowColor"]
    if p then
        tf.shadowColor = ToolSet.convertFromHtmlColor(p)

        local offset = cc.p(0,0)
        p = xml["@shadowOffset"]
        if p then
            local v2 = string.split(p,",")
            offset.x = checkint(v2[1])
            offset.y = checkint(v2[2])
        end
        offset.y = -offset.y
        tf.shadowOffset = offset
        tf:enableEffect(TextFormat.SHADOW)
    end
end

---@overload
function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self,xml)

    self:applyTextFormat()

    local p = xml["@text"]
    if p and p~="" then
        self:setText(p)
    end
end

function M:getTextFormat()

end



---@param value TextAutoSize
function M:setAutoSize(value)
    self._autoSize = value
    if value == T.TextAutoSize.NONE then
        --TODO
    elseif value == T.TextAutoSize.BOTH then
        --TODO
    elseif value == T.TextAutoSize.HEIGHT then
        --TODO
    elseif value == T.TextAutoSize.SHRINK then
        --TODO
    end

    if self._autoSize == T.TextAutoSize.BOTH then
        self._label:setDimensions(0,0)
    elseif self._autoSize == T.TextAutoSize.HEIGHT then
        self._label:setDimensions(self._size.width,0)
    else
        self._label:setDimensions(self._size.width,self._size.height)
    end

    if self._underConstruct==false then
        self:updateSize()
    end
end

function M:setSingleLine()

end

function M:isUBBEnabled()
    return false
end

function M:setUBBEnabled(value)

end

function M:getAutoSize()
    return T.TextAutoSize.NONE
end

function M:setAutoSize(value)

end

function M:isSingleLine()
    return false
end

function M:setSingleLine(value) end

function M:getTextSize()
    return self._displayObject:getContentSize()
end

function M:getColor()
    return self:getTextFormat().color
end

---@param value Color3B
function M:setColor(value)
    self:getTextFormat().color = value
    self:applyTextFormat()
end

function M:getFontSize()
    return self:getTextFormat().fontSize
end

function M:setFontSize(value)
    self:getTextFormat().fontSize = value
    self:applyTextFormat()
end

function M:cg_getColor()
    return self:getTextFormat().color
end

---@param value Color4B
function M:cg_setColor(value)
    self:getTextFormat().color = value
    self:applyTextFormat()
end

function M:cg_getOutlineColor()
    return self:getTextFormat().outlineColor
end

function M:cg_setOutlineColor(value)
    self:getTextFormat().outlineColor = value
    self:applyTextFormat()
end


return M
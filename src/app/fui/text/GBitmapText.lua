local utf8ToUnicode = require("app.fui.utils.utf8ToUnicode")

---@class GBitmapText
---@field _bitmapFont GBitmapFont
local M = class("GBitmapText", display.newNode)

function M:ctor(bitmapFont)
    self._text = ""
    self._textFieldWidth = nil
    self._bitmapFont = bitmapFont
    self._textFormat = TextFormat.new()
    self.char_sp_lists = {}

    self._char_sp_node = display.newNode():addTo(self)
    self._char_sp_node:setAnchorPoint(0,0)

    self:setCascadeOpacityEnabled(true)
    self._char_sp_node:setCascadeOpacityEnabled(true)
end

function M:setBMFontFilePath(bmfontFilePath,imageOffset,fontSize)
    local pi = UIPackage.getItemByURL(bmfontFilePath)
    self._bitmapFont = pi.bitmapFont
end

function M:getTextFormat()
    return self._textFormat
end

function M:applyTextFormat()
    self._fontName = self._textFormat.face
    self:setBMFontFilePath(self._fontName)
end

function M:setBMFontSize(size)

end

function M:setHorizontalAlignment(x)

end

function M:setVerticalAlignment(x)

end

function M:disableEffect()

end

function M:getString()
    return M:getText()
end

function M:setString(value)
    self:setText(value)
end

function M:getText()
    return self._text
end

function M:enableWrap()
    --TODO
    print("no enableWrap")
end

function M:isWrapEnabled()
    --TODO
    print("no isWrapEnabled")
    return false
end

function M:setGrayed(value)
    --TODO
end

---要显示的文本内容
function M:setText(value)
    if not value then
        value = ""
    else
        value = tostring(value)
    end

    if value == self._text then
        return
    end

    self._text = value

    self:invalidateContentBounds()

    return value

end

function M:invalidateContentBounds()
    self._renderDirty = true;
    self._textLinesChanged = true;
    self:updateRenderNode();
end

function M:updateRenderNode()
    local u32 = utf8ToUnicode.enc_utf8_to_unicode(self._text)

    local width = 0
    local height = 0

    for i, v in ipairs(self.char_sp_lists) do
        v:removeFromParent()
    end
    self.char_sp_lists = {}

    for i, charId in ipairs(u32) do
        ---@type GBitmapFontDef
        local def = self._bitmapFont:getLetterDefinition(charId)
        if def then
            local spriteFrame = cc.SpriteFrame:createWithTexture(
                    self._bitmapFont:getTexture(),
                    cc.rect(def.U, def.V, def.width, def.height),
                    false,
                    cc.p(def.offsetX, def.offsetY),
                    cc.size(def.width, def.height))
            local sp = display.newSprite(spriteFrame)
            sp:setAnchorPoint(cc.p(0, 1))
            sp:pos(width,0)

            sp:setCascadeOpacityEnabled(true)

            width = width + def.xAdvance
            height = math.max(height,def.height)
            self._char_sp_node:addChild(sp)
            table.insert(self.char_sp_lists,sp)
        end

    end

    self.width = width
    self.height = height

    local ap = self:getAnchorPoint()
    self._char_sp_node:setPositionX(-ap.x*self.width)
    self._char_sp_node:setPositionY((1-ap.y)*self.height)

end

function M:getWidth()
    local w = self._textFieldWidth
    return w == nil and self:getContentBounds().width or w
end

function M:setWidth()
end

function M:setDimensions()

end

---测量自身占用的矩形区域，注意：此测量结果并不包括子项占据的区域。
function M:getContentBounds()

end

function M:getTextLines()
    --[[
    if (self._textLinesChanged == false) then
        return self.textLines;
    end
    local textLines = {};
    self.textLines = textLines;
    local textLinesWidth = {}
    self._textLinesWidth = textLinesWidth;
    self._textLinesChanged = false;
    local lineHeights = {};
    self._lineHeights = lineHeights;
    if (self._text == "" or nil == self._font) then
        self._textWidth = 0;
        self._textHeight = 0;
        return textLines;
    end

    local lineSpacing = self._lineSpacing;
    local letterSpacing = self._letterSpacing;
    local textWidth = 0;
    local textHeight = 0;
    local textOffsetX = 0;
    local textOffsetY = 0;
    local hasWidthSet = (nil == self._textFieldWidth);
    local textFieldWidth = self._textFieldWidth;
    local textFieldHeight = self._textFieldHeight;
    local bitmapFont = self._font;
    local emptyHeight = bitmapFont:getFirstCharHeight();
    local emptyWidth = math.ceil(emptyHeight * M.EMPTY_FACTOR);
    local text = self._text;
    local textArr = string.split(text)
    local length = #textArr;
    local isFirstLine = true;
    local isFirstChar;
    local isLastChar;
    local lineHeight;
    local xPos;

    for i = 1, length do
        local line = textArr[i]
        local len = string.utf8len(line)
        lineHeight = 0;
        xPos = 0;
        isFirstChar = true;
        isLastChar = false;

        for j = 1, len do
            while true do
                if (isFirstChar==false) then
                    xPos = xPos + letterSpacing;
                end

                local character = string.utf8sub(line,j,j+1)

                local texureWidth;
                local textureHeight;
                local offsetX = 0;
                local offsetY = 0;

                --local texture = bitmapFont:getTexture(character);
                local utf8ToUnicode
                local texture = bitmapFont:getLetterDefinition(character)

                if not texture then
                    if character == " " then
                        texureWidth = emptyWidth
                        textureHeight = emptyHeight
                    else
                        print("文字没有对应的定义：",character)
                        if isFirstChar==true then
                            isFirstChar = false
                        end
                        break
                    end
                else
                    --texureWidth = texture:getPixelsWide()
                    --textureHeight = texture:getPixelsHigh()

                    texureWidth = texture:getPixelsWide()
                    textureHeight = texture:getPixelsHigh()
                    offsetX = texture.
                end
                break
            end

        end
    end
end



    --[[local texture = bitmapFont.getTexture(character);
    if (!texture) {
    if (character == " ") {
    texureWidth = emptyWidth;
    textureHeight = emptyHeight;
    }
    else {
    egret._warn(1046, character);
    if (isFirstChar) {
    isFirstChar = false;
    }
    continue;
    }
    }
    else {
    texureWidth = texture._getTextureWidth();
    textureHeight = texture._getTextureHeight();
    offsetX = texture._offsetX;
    offsetY = texture._offsetY;
    }
    
    if (isFirstChar) {
    isFirstChar = false;
    textOffsetX = Math.min(offsetX, textOffsetX);
    }
    
    if (isFirstLine) {
    isFirstLine = false;
    textOffsetY = Math.min(offsetY, textOffsetY);
    }
    if (hasWidthSet && j > 0 && xPos + texureWidth > textFieldWidth) {
    if (!setLineData(line.substring(0, j)))
    break;
    line = line.substring(j);
    len = line.length;
    j = 0;
    //最后一个字符要计算纹理宽度，而不是xadvance
    if (j == len - 1) {
    xPos = texureWidth;
    }
    else {
    xPos = bitmapFont.getConfig(character, "xadvance") || texureWidth;
    }
    lineHeight = textureHeight;
    continue;
    }
    //最后一个字符要计算纹理宽度，而不是xadvance
    if (j == len - 1) {
    xPos += texureWidth;
    }
    else {
    xPos += bitmapFont.getConfig(character, "xadvance") || texureWidth;
    }
    lineHeight = Math.max(textureHeight, lineHeight);
    }
    if (textFieldHeight && i > 0 && textHeight > textFieldHeight) {
    break;
    }
    isLastChar = true;
    if (!setLineData(line))
    break;
    }
    function setLineData(str: string): boolean {
    if (textFieldHeight && textLines.length > 0 && textHeight > textFieldHeight) {
    return false;
    }
    textHeight += lineHeight + lineSpacing;
    if (!isFirstChar && !isLastChar) {
    xPos -= letterSpacing;
    }
    textLines.push(str);
    lineHeights.push(lineHeight);
    textLinesWidth.push(xPos);
    textWidth = Math.max(xPos, textWidth);
    return true;
    }
    textHeight -= lineSpacing;
    self._textWidth = textWidth;
    self._textHeight = textHeight;
    this._textOffsetX = textOffsetX;
    this._textOffsetY = textOffsetY;
    this._textStartX = 0;
    this._textStartY = 0;
    local alignType;
    if (textFieldWidth > textWidth) {
    alignType = self._textAlign;
    if (alignType == egret.HorizontalAlign.RIGHT) {
    this._textStartX = textFieldWidth - textWidth;
    } else if (alignType == egret.HorizontalAlign.CENTER) {
    this._textStartX = Math.floor((textFieldWidth - textWidth) / 2);
    }
    }
    if (textFieldHeight > textHeight) {
    alignType = self._verticalAlign;
    if (alignType == egret.VerticalAlign.BOTTOM) {
    this._textStartY = textFieldHeight - textHeight;
    } else if (alignType == egret.VerticalAlign.MIDDLE) {
    this._textStartY = Math.floor((textFieldHeight - textHeight) / 2);
    }
    }
    return textLines;
    }
    --]]
end

return M
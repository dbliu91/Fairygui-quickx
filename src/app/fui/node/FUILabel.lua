---@class FUILabel
---@field _textFormat TextFormat
local M = class("FUILabel",function ()
    return cc.Label:create()
end)

function M:ctor()
    self._fontSize = -1
    self._bmFontCanTint = false
    self._textFormat = TextFormat.new()

    self._fontConfig = {}

    self._currentLabelType = T.LabelType.TTF
end

function M:getText()
    return self:getString()
end

function M:setText(value)

    if self._fontSize<0 then
        self:applyTextFormat()
    end

    self:setString(value)
end

function M:getTextFormat()
    return self._textFormat
end

function M:applyTextFormat()

    if self._fontSize<0  -- first time
            or self._fontName~=self._textFormat.face then
        self._fontName = self._textFormat.face
        local oldType = self._currentLabelType

        if string.find(self._fontName,"ui://") then -- 临时关闭位图
            --self:setBMFontFilePath(self._fontName)
            --self._currentLabelType = T.LabelType.BMFONT
            error("位图字体走GBitmapText")
            return
        else
            local fontName,isTTF = UIConfig.getRealFontName(self._fontName)
            if isTTF==true then
                self._fontConfig.fontFilePath = fontName
                self._fontConfig.fontSize = self._textFormat.fontSize
                self:setTTFConfig(self._fontConfig)
                self._currentLabelType = T.LabelType.TTF
            else
                self:setSystemFontName(fontName)
                self._currentLabelType = T.LabelType.STRING_TEXTURE
            end

            if oldType == T.LabelType.BMFONT then
                self:setTextColor(self._textFormat.color)
            end

        end

        if self._fontSize ~= self._textFormat.fontSize then
            self._fontSize =  self._textFormat.fontSize
            if self._currentLabelType == T.LabelType.STRING_TEXTURE then
                self:setSystemFontSize(self._fontSize)
            elseif self._currentLabelType == T.LabelType.BMFONT then
                self:setBMFontSize(self._fontSize)
            else
                self._fontConfig.fontSize = self._fontSize
                self:setTTFConfig(self._fontConfig)
            end
        end

    end

    if self._currentLabelType ~= T.LabelType.BMFONT or self._bmFontCanTint then
        self:setColor(self._textFormat.color)
    end

    if self._textFormat.underline then
        --TODO enableUnderline();
    else
        --TODO disableEffect(LabelEffect::UNDERLINE);
    end

    if self._textFormat.italics then
        --TODO enableItalics();
    else
        --TODO disableEffect(LabelEffect::ITALICS);
    end

    if self._textFormat.bold then
        --TODO enableBold();
    else
        --TODO disableEffect(LabelEffect::BOLD);
    end

    --TODO setLineSpacing(_textFormat->lineSpacing);

    self:setHorizontalAlignment(self._textFormat.align)
    self:setVerticalAlignment(self._textFormat.verticalAlign)


    self:disableEffect()
    if (self._textFormat:hasEffect(TextFormat.OUTLINE)) then
        self:enableOutline(self._textFormat.outlineColor, self._textFormat.outlineSize);
    end

    if (self._textFormat:hasEffect(TextFormat.SHADOW)) then
        print("貌似不支持阴影")
        self:enableShadow(self._textFormat.shadowColor, self._textFormat.shadowOffset);
    end

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

return M
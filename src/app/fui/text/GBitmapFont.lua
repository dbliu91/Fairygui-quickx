local GBitmapFontDef = require("app.fui.text.GBitmapFontDef")

---位图字体,是一个字体的纹理集，通常作为BitmapText.font属性的值。
---@class GBitmapFont
local M = class("GBitmapFont")

function M:ctor()
    self._textures = {}
    self._chars = {}
end

function M:setTexture(tex)
    self._texture = tex
end

function M:getTexture()
    return self._texture
end

function M:setLineHeight(lineHeight)
    self._lineHeight = lineHeight
end

function M:addLetterDefinition(charId,def)
    self._chars[charId] = def
end

function  M:getFirstCharHeight()
    return self._lineHeight
end

---@return GBitmapFontDef
function M:getLetterDefinition(charId)
    return self._chars[charId]
end

function M:parseFntData(item_id,fntData,package)

    local lines = string.split(fntData, "\n")

    local ttf = false;
    local size = 0;
    local xadvance = 0;
    local resizable = false;
    local canTint = false;
    local lineHeight = 0;
    local mainTexture;
    local mainSprite;



    for idx, line_str in ipairs(lines) do
        local b, e, head = string.find(line_str, "(.-) ")
        local key, value
        if head then
            local line_data = {}
            string.gsub(line_str, "(%w+)=(%S+)", function(k, v)
                line_data[k] = v
            end)

            if head == "info" then
                local p = line_data["face"]
                if p then
                    ttf = true
                    local sp = package._sprites[item_id]
                    if sp then
                        mainSprite = sp
                        local atlasItem = package:getItem(mainSprite.atlas)
                        package:loadItem(atlasItem)
                        mainTexture = atlasItem.texture
                    end
                end

                p = line_data["size"]
                if p then
                    size = checkint(p)
                end

                p = line_data["resizable"]
                if p then
                    resizable = (p == "true")
                end

                p = line_data["colored"]
                if p then
                    canTint = (p == "true")
                end

                if size == 0 then
                    size = lineHeight
                elseif lineHeight == 0 then
                    lineHeight = size
                end
            end

            if head == "common" then
                local p = line_data["lineHeight"]
                if p then
                    lineHeight = checkint(p)
                end

                p = line_data["xadvance"]
                if p then
                    xadvance = checkint(p)
                end
            end

            if head == "char" then
                local def = GBitmapFontDef.new()

                local bx = 0;
                local by = 0;
                local charId = 0;
                local bw = 0;
                local bh = 0;

                local charImg;

                local p = line_data["id"]
                if p then
                    charId = checkint(p)
                end

                p = line_data["x"]
                if p then
                    bx = checkint(p)
                end

                p = line_data["y"]
                if p then
                    by = checkint(p)
                end

                p = line_data["xoffset"]
                if p then
                    def.offsetX = checkint(p)
                end

                p = line_data["yoffset"]
                if p then
                    def.offsetY = checkint(p)
                end

                p = line_data["width"]
                if p then
                    bw = checkint(p)
                end

                p = line_data["height"]
                if p then
                    bh = checkint(p)
                end

                p = line_data["xadvance"]
                if p then
                    def.xAdvance = checkint(p)
                end

                p = line_data["img"]
                if p and ttf==false then
                    charImg = package:getItem(p)
                end

                if ttf then
                    local tempRect = cc.rect(bx + mainSprite.x, by + mainSprite.y, bw, bh);

                    local contentScaleFactor = cc.Director:getInstance():getContentScaleFactor()
                    tempRect = cc.rect(
                            tempRect.x/contentScaleFactor,
                            tempRect.y/contentScaleFactor,
                            tempRect.width/contentScaleFactor,
                            tempRect.height/contentScaleFactor
                    )

                    def.U = tempRect.x;
                    def.V = tempRect.y;
                    def.width = tempRect.width;
                    def.height = tempRect.height;
                    def.validDefinition = true;
                else
                    if charImg then
                        package:loadItem(charImg)

                        local tempRect = charImg.spriteFrame:getRectInPixels();
                        bw = tempRect.width;
                        bh = tempRect.height;

                        local contentScaleFactor = cc.Director:getInstance():getContentScaleFactor()
                        tempRect = cc.rect(
                                tempRect.x/contentScaleFactor,
                                tempRect.y/contentScaleFactor,
                                tempRect.width/contentScaleFactor,
                                tempRect.height/contentScaleFactor
                        )
                        def.U = tempRect.x;
                        def.V = tempRect.y;
                        def.width = tempRect.width;
                        def.height = tempRect.height;
                        if (mainTexture == nil) then
                            mainTexture = charImg.spriteFrame:getTexture();
                            def.validDefinition = true;
                        end

                        if def.xAdvance == 0 then
                            def.xAdvance = xadvance
                        end

                        if def.xAdvance == 0 then
                            def.xAdvance = def.width
                        end

                    end
                end

                self:addLetterDefinition(charId,def)

                if size == 0 then
                    size = bh
                end

                if ttf==false and lineHeight<size then
                    lineHeight = size
                end

            end
        end
    end

    self:setTexture(mainTexture)
    self:setLineHeight(lineHeight)
    self._originalFontSize = size
    self._resizable = resizable
    self._canTint = canTint
end

return M
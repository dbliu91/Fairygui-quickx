

---@class TextFormat
local TextFormat = class("TextFormat")

TextFormat.OUTLINE = 1
TextFormat.SHADOW = 2
TextFormat.GLOW = 4

function TextFormat:ctor()
    self.fontSize = 12
    self.color = cc.c3b(0,0,0)
    self.bold = false
    self.italics = false
    self.underline = false
    self.lineSpacing = 3
    self.letterSpacing = 0
    self.align = T.TextHAlignment.LEFT
    self.verticalAlign = T.TextVAlignment.TOP
    self.effect = 0
    self.outlineSize = 1
    self.shadowBlurRadius = 0
    self._hasColor = false

    self.face = ""
end

function TextFormat:enableEffect(effectFlag)
    self.effect = bit.bor(self.effect,effectFlag)
end

function TextFormat:disableEffect(effectFlag)
    local x = bit.bxor(effectFlag)
    self.effect = bit.band(self.effect,x)
end

function TextFormat:hasEffect(effectFlag)
    return (bit.band(self.effect,effectFlag)~=0)
end

return TextFormat
local ccPositionTextureColor_noMVP_vert = [[

attribute vec4 a_position;
attribute vec2 a_texCoord;
attribute vec4 a_color;

#ifdef GL_ES
varying lowp vec4 v_fragmentColor;
varying mediump vec2 v_texCoord;
#else
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
#endif

void main()
{
    gl_Position = CC_PMatrix * a_position;
    v_fragmentColor = a_color;
    v_texCoord = a_texCoord;
}

]]

local ccPositionTexture_GrayScale_frag= [[
#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main(void)
{
    vec4 c = texture2D(CC_Texture0, v_texCoord);
     c = v_fragmentColor * c;
    gl_FragColor.xyz = vec3(0.2126*c.r + 0.7152*c.g + 0.0722*c.b);
    gl_FragColor.w = c.w;
}
]]

---@class FUISprite
local M = class("FUISprite", function(SpriteClass)
    local r = SpriteClass:create()
    return r
end)

function M:ctor(SpriteClass)
    self._SpriteClass = SpriteClass
end

function M:clearContent()
    self:setTexture(nil)

    if self.setCenterRectNormalized then
        self:setCenterRectNormalized(cc.rect(0, 0, 1, 1))
    end
end

---@param value Rect
function M:setScale9Grid(value)
    if not value then
        self:setCenterRectNormalized(cc.rect(0, 0, 1, 1))
        return
    end

    self:setCapInsets(value)

    --TODO Warning: Sprite::setCenterRect() only works with QUAD and SLICE9 render modes
end

function M:setGrayed(value)

    local sprite = self

    if self._SpriteClass == ccui.Scale9Sprite then
        print("ccui.Scale9Sprite 不支持变灰。。")
    end

    if value == true then
        local glprogram = cc.GLProgramCache:getInstance():getGLProgram("FUI_SHADER_NAME_POSITION_GRAYSCALE")
        if not glprogram then
            glprogram = cc.GLProgram:createWithByteArrays(ccPositionTextureColor_noMVP_vert, ccPositionTexture_GrayScale_frag)
            cc.GLProgramCache:getInstance():addGLProgram(glprogram, "FUI_SHADER_NAME_POSITION_GRAYSCALE")
        end
        local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgram(glprogram)
        sprite:setGLProgramState(glprogramstate)
    else
        local glprogram = cc.GLProgramCache:getInstance():getGLProgram("ShaderPositionTextureColor_noMVP")
        local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgram(glprogram)
        sprite:setGLProgramState(glprogramstate)
    end
end

return M
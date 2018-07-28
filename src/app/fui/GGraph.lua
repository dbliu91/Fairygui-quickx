--TODO
--[[
还未实现的功能：
1.  椭圆
2.  变灰
3. 倾斜X 倾斜Y
--]]

local ToolSet = require("app.fui.utils.ToolSet")

local GObject = require("app.fui.GObject")

---@class GGraph:GObject
---@field protected _type number
---@field protected _shape cocos2d_DrawNode
---@field protected _lineColor cc.c4f
---@field protected _fillColor cc.c4f
---@field protected _lineSize number
local M = class("GGraph", GObject)

function M:ctor()
    M.super.ctor(self)

    self._shape = nil
    self._type = 0
    self._lineSize = 1
    self._lineColor = cc.c4f(0, 0, 0, 1)
    self._fillColor = cc.c4f(1, 1, 1, 1)

    self._touchDisabled = true

end

function M:drawRect(aWidth, aHeight, lineSize, lineColor, fillColor)
    self._type = 0 -- avoid updateshape call in handleSizeChange
    self:setSize(aWidth, aHeight)
    self._type = 1

    self._lineSize = lineSize
    self._lineColor = lineColor
    self._fillColor = fillColor

    self:updateShape()
end

function M:drawEllipse(aWidth, aHeight, lineSize, lineColor, fillColor)
    self._type = 0 -- avoid updateshape call in handleSizeChange
    self:setSize(aWidth, aHeight)
    self._type = 2

    self._lineSize = lineSize
    self._lineColor = lineColor
    self._fillColor = fillColor

    self:updateShape()
end

function M:isEmpty()
    return self._type
end

function M:cg_setColor(value)
    self._fillColor = value
    self:updateShape()
end

function M:handleInit()

    --local classTpye = cc.NVGDrawNode
    local classTpye = cc.DrawNode

    self._shape = classTpye:create()
    self._shape:retain()
    UIPackage.markForRelease(self._shape,self.__cname)

    self._classType = classTpye

    self._displayObject = self._shape
end

function M:setup_BeforeAdd(xml)
    M.super.setup_BeforeAdd(self, xml)

    local p = xml["@type"]
    if p then
        if p == "rect" then
            self._type = 1
        elseif p == "eclipse" then
            self._type = 2
        end
    end

    if self._type ~= 0 then
        local p = xml["@lineSize"]
        if p then
            self._lineSize = checkint(p)
        end

        local p = xml["@lineColor"]
        if p then
            self._lineColor = ToolSet.convertFromHtmlColor4F(p)
        end

        local p = xml["@fillColor"]
        if p then
            self._fillColor = ToolSet.convertFromHtmlColor4F(p)
        end

        self:updateShape()
    end
end

function M:updateShape()
    self._shape:clear()
    if self._type == 1 then
        if self._lineSize > 0 then
            if self._classType == cc.DrawNode then
            else
                self._shape:setLineWidth(self._lineSize)
            end
            self._shape:drawRect(cc.p(0, 0),
                    cc.p(self._size.width, self._size.height),
                    self._lineColor)
        end
        self._shape:drawSolidRect(cc.p(0, 0),
                cc.p(self._size.width, self._size.height),
                self._fillColor)
        self._touchDisabled = false
    elseif self._type == 2 then
        if self._lineSize > 0 then
            if self._classType == cc.DrawNode then
                self._shape:drawCircle(
                        cc.p(self._size.width / 2, self._size.height / 2),
                        self._size.width / 2,
                        360,
                        0, -- segments
                        false, -- drawLineToCenter
                        1, --scaleX
                        self._size.height / self._size.width, --scaleY
                        self._lineColor)
            else
                -- cc.NVGDrawNode
                self._shape:setLineWidth(self._lineSize)
                self._shape:drawCircle(
                        cc.p(self._size.width / 2, self._size.height / 2),
                        self._size.width / 2,
                        self._lineColor)
            end
        end
        if self._classType == cc.DrawNode then
            self._shape:drawSolidCircle(
                    cc.p(self._size.width / 2, self._size.height / 2),
                    self._size.width / 2,
                    360,
                    100,
                    1,
                    self._size.height / self._size.width, -- scaleY
                    self._fillColor)
        else
            --cc.NVGDrawNode
            self._shape:drawSolidCircle(
                    cc.p(self._size.width / 2, self._size.height / 2),
                    self._size.width / 2,
                    self._fillColor)
        end

        self._touchDisabled = false
    else
        self._touchDisabled = false
    end
end

function M:handleSizeChanged()
    GObject.handleSizeChanged(self)

    self:updateShape()
end

return M
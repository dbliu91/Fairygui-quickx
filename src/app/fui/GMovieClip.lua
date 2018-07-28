local FUISprite = require("app.fui.node.FUISprite")
local ActionMovieClip = require("app.fui.node.ActionMovieClip")

local GObject = require("app.fui.GObject")

---@class GMovieClip:GObject
local M = class("GMovieClip",GObject)

function M:ctor()
    GObject.ctor(self)

    self._sizeImplType = 1
    self._touchDisabled = true

    self._playing = true
    self._content = nil
    self._playAction = nil
end

function M:doDestory()
    M.super.doDestory(self)

    if self._playAction then
        self._playAction:release()
        self._playAction = nil
    end
end

function M:handleInit()
    self._content = FUISprite.new(cc.Sprite)
    self._content:retain()
    UIPackage.markForRelease(self._content,self.__cname)

    self._displayObject = self._content
end

function M:isPlaying()
    return self._playing
end

function M:setPlaying(value)
    if self._playing ~= value then
        self._playing = value
        if self._playing == true then
            self._content:runAction(self._playAction)
        else
            self._content:stopAction(self._playAction)
        end
    end
end

function M:getCurrentFrame()
    --return self._playAction:getCurrentFrame()
    return 1
end

function M:setCurrentFrame(value)
    --self._playAction:setCurrentFrame(value)
    self._content:setSpriteFrame(self._packageItem.animationSpriteFrameNameList[value])
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

--- from start to end(-1 means ending)，
--- repeat times(0 means infinite loop)，
--- when all is over, stopping at endAt(-1 means same value of end)
function M:setPlaySettings(start_frame,end_frame,times,endAt,completeCallback)
    --return self._playAction:setPlaySettings(start_frame,end_frame,times,endAt,completeCallback)
end

function M:constructFromResource()
    self.sourceSize.width = self._packageItem.width
    self.sourceSize.height = self._packageItem.height
    self.initSize = clone(self.sourceSize)


    --self._playAction = ActionMovieClip.new(self._packageItem.animation)
    self._playAction = transition.playAnimationForever(self._content,self._packageItem.animation, self._packageItem.repeatDelay)
    self._playAction:retain()
    UIPackage.markForRelease(self._playAction,self.__cname)

    --self._playAction:setAnimation(self._packageItem.animation, self._packageItem.repeatDelay)
    --self._content:runAction(self._playAction)

    self:setSize(self.sourceSize.width,self.sourceSize.height)
end

function M:handleGrayedChanged()
    GObject.handleGrayedChanged(self)

    self._content:setGrayed(self._finalGrayed)
end

function M:setup_BeforeAdd(xml)
    GObject.setup_BeforeAdd(self,xml)

    local p

    p = xml["@frame"]
    if p then
        self:setCurrentFrame(checkint(p))
    end

    p = xml["@playing"]
    if p and p=="false" then
        self:setPlaying(false)
    end

    p = xml["@flip"]
    if p then
        self:setFlip(p)
    end

    p = xml["@color"]
    if p then
        self:setColor(ToolSet.convertFromHtmlColor(p))
    end
end

return M
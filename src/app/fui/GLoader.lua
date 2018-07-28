local FUISprite = require("app.fui.node.FUISprite")

local GObject = require("app.fui.GObject")

---@class GLoader:GObject
local M = class("GLoader", GObject)

function M:ctor()
    M.super.ctor(self)

    self._autoSize = false
    self._align = T.TextHAlignment.LEFT
    self._verticalAlign = T.TextVAlignment.TOP
    self._fill = T.LoaderFillType.NONE
    self._updatingLayout = false
    self._contentItem = nil
    self._contentStatus = 0
    self._content = nil
    self._playAction = nil
    self._playing = true
    self._frame = 0

    self._contentSize = cc.size(0, 0)
    self._contentSourceSize = cc.size(0, 0)
end

function M:doDestory()
    M.super.doDestory(self)

    if self._playAction then
        self._playAction:release()
        self._playAction = nil
    end

    if self._content then
        --self._content:release()
        self._content = nil
    end
end

function M:handleInit()
    self._content = FUISprite.new(cc.Sprite)
    --self._content:retain()
    --UIPackage.markForRelease(self._content,self.__cname)
    self._content:setAnchorPoint(cc.p(0, 0))
    self._content:setCascadeOpacityEnabled(true)

    self._displayObject = display.newNode()
    self._displayObject:retain()
    UIPackage.markForRelease(self._displayObject,self.__cname)
    self._displayObject:addChild(self._content)
end

function M:getURL()
    return self._url
end

function M:setURL(value)
    if self._url == value then
        return
    end

    self._url = value
    self:loadContent()
    self:updateGear("gearIcon")
end

function M:getIcon()
    return self._url
end

function M:setIcon(value)
    self:setURL(value)
end

function M:getAlign()
    return self._align
end

function M:setAlign(value)
    if self._align ~= value then
        self._align = value
        self:updateLayout()
    end
end

function M:getVerticalAlign()
    return self._verticalAlign
end

function M:setVerticalAlign(value)
    if self._verticalAlign ~= value then
        self._verticalAlign = value
        self:updateLayout()
    end
end

function M:getAutoSize()
    return self._autoSize
end

function M:setAutoSize(value)
    if self._autoSize ~= value then
        self._autoSize = value
        self:updateLayout()
    end
end

function M:getFill()
    return self._fill
end

function M:setFill(value)
    if self._fill ~= value then
        self._fill = value
        self:updateLayout()
    end
end

function M:getContentSize()
    return self._contentSize
end

function M:getColor()
    return self._content:getColor()
end

function M:setColor(value)
    self._content:setColor(value)
end

function M:isPlaying()
    return self._playing
end

function M:setPlaying(value)
    if self._playing ~= value then
        self._playing = value
        if self._playAction then
            if self._playing == true then
                self._content:runAction(self._playAction)
            else
                self._content:stopAction(self._playAction)
            end
        end
        self:updateGear("gearAni")
    end
end

function M:getCurrentFrame()
    return self._playAction:getCurrentFrame()
end

function M:setCurrentFrame(value)
    self._frame = value
    if self._playAction then
        self._playAction:setCurrentFrame(value)
    end
    self:updateGear("gearAni")
end

function M:cg_getColor()
    return self._content:getColor()
end

function M:cg_setColor(value)
    self._content:setColor(value)
end

function M:handleSizeChanged()
    M.super.handleSizeChanged(self)

    if self._updatingLayout == false then
        self:updateLayout()
    end
end

function M:handleGrayedChanged()
    M.super.handleGrayedChanged(self)

    self._content:setGrayed(self._finalGrayed)
end

function M:setup_BeforeAdd(xml)
    M.super.setup_BeforeAdd(self, xml)

    local p

    p= xml["@url"]
    if p then
        self._url = p
    end

    p = xml["@align"]
    if p then
        self._align = ToolSet.parseAlign(p)
    end

    p = xml["@vAlign"]
    if p then
        self._verticalAlign = ToolSet.parseVerticalAlign(p)
    end

    p = xml["@fill"]
    if p then
        self._fill = p
    end

    self._autoSize = xml["@autoSize"] == "true"

    p = xml["@color"]
    if p then
        local c = ToolSet.convertFromHtmlColor(p)
        self:setColor(c)
    end

    p = xml["@frame"]
    if p then
        self._frame = checkint(p)
    end

    p = xml["@playing"]
    if p then
        self._playing = (p == "false")
    end

    if self._url ~= "" then
        self:loadContent()
    end

end

function M:loadExternal()
    local c = cc.Director:getInstance():getTextureCache()
    c:addImage(self._url)
    local tex = c:getTextureForKey(self._url)
    if tex then
        local sf = cc.SpriteFrame:createWithTexture(tex, cc.rect(0, 0, tex:getContentSize().width, tex:getContentSize().height))
        self:onExternalLoadSuccess(sf)
    else
        self:onExternalLoadFailed()
    end
end

function M:freeExternal(tex)

end

function M:onExternalLoadSuccess(sf)
    self._contentStatus = 4
    self._content:setSpriteFrame(sf)
    local rect = sf:getRectInPixels()
    self._contentSourceSize.width = rect.width
    self._contentSourceSize.height = rect.height
    self:updateLayout()
end

function M:onExternalLoadFailed()
    self:setErrorState()
end

function M:loadContent()

    self:clearContent()

    if self._url == nil or self._url == "" then
        return
    end

    if string.find(self._url, "ui://") == 1 then
        self:loadFromPackage()
    else
        self._contentStatus = 3
        self:loadExternal()
    end

end

function M:loadFromPackage()
    self._contentItem = UIPackage.getItemByURL(self._url)

    if self._contentItem ~= nil then
        self._contentItem:load()

        if self._contentItem.type == T.PackageItemType.IMAGE then
            self._contentStatus = 1
            self._contentSourceSize.width = self._contentItem.width
            self._contentSourceSize.height = self._contentItem.height
            self._content:setSpriteFrame(self._contentItem.spriteFrame)
            if self._contentItem.scale9Grid == true then
                self._content:setScale9Grid(self._contentItem.scale9Grid)
            end
            self:updateLayout()
        elseif self._contentItem.type == T.PackageItemType.MOVIECLIP then
            self._contentStatus = 2
            self._contentSourceSize.width = self._contentItem.width
            self._contentSourceSize.height = self._contentItem.height

            self._playAction = transition.playAnimationForever(self._content,self._contentItem.animation, self._contentItem.repeatDelay)
            self._playAction:retain()
            UIPackage.markForRelease(self._playAction,self.__cname)

            --[[
            if (_playAction == nullptr)
            {
                _playAction = ActionMovieClip::create(_contentItem->animation, _contentItem->repeatDelay);
                _playAction->retain();
            }
            else
                _playAction->setAnimation(_contentItem->animation, _contentItem->repeatDelay);
            if (_playing)
                _content->runAction(_playAction);
            else
                _playAction->setCurrentFrame(_frame);
            --]]

            self:updateLayout()
        else
            if self._autoSize == true then
                self:setSize(self._contentItem.width, self._contentItem.height)
            end

            self:setErrorState()
        end
    else
        self:setErrorState()
    end
end

function M:clearContent()
    self:clearErrorState()

    if self._contentStatus == 4 then
        self:freeExternal(self._content:getSpriteFrame())
    end

    if self._contentStatus == 2 then
        --[[
        _playAction->setAnimation(nullptr);
        _content->stopAction(_playAction);
        --]]
    end

    self._content:clearContent()
    self._contentItem = nil

    self._contentStatus = 0

end

function M:updateLayout()
    if self._contentStatus == 0 then
        if self._autoSize == true then
            self._updatingLayout = true
            self:setSize(50, 30)
            self._updatingLayout = false
        end
        return
    end

    self._contentSize = clone(self._contentSourceSize)

    if self._autoSize == true then
        self._updatingLayout = true
        if (self._contentSize.width == 0) then
            self._contentSize.width = 50
        end
        if (self._contentSize.height == 0) then
            self. _contentSize.height = 30
        end
        self:setSize(self._contentSize.width, self._contentSize.height)
        self._updatingLayout = false

        if self._size.width == self._contentSize.width and self._size.height == self._contentSize.height then
            self._content:setScale(1, 1)
            self._content:setAnchorPoint(cc.p(0, 0))
            self._content:setPosition(0, 0)
            return
        end
    end

    local sx = 1
    local sy = 1

    if self._fill ~= T.LoaderFillType.NONE then
        sx = self._size.width / self._contentSourceSize.width
        sy = self._size.height / self._contentSourceSize.height

        if sx ~= 1 or sy ~= 1 then
            if (self._fill == T.LoaderFillType.SCALE_MATCH_HEIGHT) then
                sx = sy
            elseif (self._fill == T.LoaderFillType.SCALE_MATCH_WIDTH) then
                sy = sx
            elseif (self._fill == T.LoaderFillType.SCALE) then
                if (sx > sy) then
                    sx = sy
                else
                    sy = sx
                end
            elseif (self._fill == T.LoaderFillType.SCALE_NO_BORDER) then
                if (sx > sy) then
                    sy = sx
                else
                    sx = sy
                end
            end

            self._contentSize.width = math.floor(self._contentSourceSize.width * sx)
            self._contentSize.height = math.floor(self._contentSourceSize.height * sy)

        end
    end

    self._content:setContentSize(self._contentSourceSize)
    self._content:setScale(sx, sy)
    self._content:setAnchorPoint(cc.p(0, 0))

    local nx, ny

    if self._align == T.TextHAlignment.CENTER then
        nx = math.floor((self._size.width - self. _contentSize.width) / 2)
    elseif self._align == T.TextHAlignment.RIGHT then
        nx = math.floor((self._size.width - self. _contentSize.width))
    else
        nx = 0
    end

    if self._align == T.TextVAlignment.CENTER then
        ny = math.floor((self._size.height - self. _contentSize.height) / 2)
    elseif self._align == T.TextVAlignment.BOTTOM then
        ny = 0
    else
        ny = self._size.height - self. _contentSize.height
    end

    self._content:setPosition(cc.p(nx,ny))

end

function M:setErrorState()

end

function M:clearErrorState()

end

return M
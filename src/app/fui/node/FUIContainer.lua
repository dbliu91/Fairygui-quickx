local RectClippingSupport = require("app.fui.node.RectClippingSupport")

---@class FUIContainer
local M = class("FUIContainer",function (classType)
    if not classType then
        classType = cc.Node
    end
    local n = classType:create()
    n._classType = classType
    return n
end)

function M:isClippingEnabled()
    if self._rectClippingSupport ~= nil then
        return self._rectClippingSupport._clippingEnabled
    else
        return false
    end
end

function M:setClippingEnabled(value)
    if self._rectClippingSupport == nil then
        if value == false then
            return
        end

        self._rectClippingSupport = RectClippingSupport.new()
    end

    self._rectClippingSupport._clippingEnabled = value
end

function M:getClippingRegion()
    if self._rectClippingSupport ~= nil then
        return self._rectClippingSupport._clippingRegion
    else
        return cc.rect(0,0,0,0)
    end
end

function M:setClippingRegion(clippingRegion)

    if self._classType.setClippingRegion then
        self._classType.setClippingRegion(self,clippingRegion)
    end

    if self._rectClippingSupport == nil then
        self._rectClippingSupport = RectClippingSupport.new()
    end

    self._rectClippingSupport._clippingRegion = clippingRegion

end

--[[



--]]

--[[


    cocos2d::Node* getStencil() const;
    void setStencil(cocos2d::Node* stencil);
    GLfloat getAlphaThreshold() const;
    void setAlphaThreshold(GLfloat alphaThreshold);
    bool isInverted() const;
    void setInverted(bool inverted);

    void onEnter() override;
    void onEnterTransitionDidFinish() override;
    void onExitTransitionDidStart() override;
    void onExit() override;
    void visit(cocos2d::Renderer *renderer, const cocos2d::Mat4 &parentTransform, uint32_t parentFlags) override;
    void setCameraMask(unsigned short mask, bool applyChildren = true) override;
--]]

function M:setContentSize(contentSize)
    cc.Node.setContentSize(self,contentSize)

    if self._rectClippingSupport then
        self._rectClippingSupport._clippingRectDirty = true
    end

    --self:setClippingRegion(self._rectClippingSupport and self._rectClippingSupport._clippingRegion or cc.rect(0,0,contentSize.width,contentSize.height))
end

--[[
private:
    void onBeforeVisitScissor();
    void onAfterVisitScissor();
--]]

function M:getClippingRect()
    --[[
    if (_rectClippingSupport->_clippingRectDirty)
    {
        Vec2 worldPos = convertToWorldSpaceAR(_rectClippingSupport->_clippingRegion.origin);
        AffineTransform t = getNodeToWorldAffineTransform();
        float scissorWidth = _rectClippingSupport->_clippingRegion.size.width*t.a;
        float scissorHeight = _rectClippingSupport->_clippingRegion.size.height*t.d;
        _rectClippingSupport->_clippingRect.setRect(worldPos.x - (scissorWidth * _anchorPoint.x), worldPos.y - (scissorHeight * _anchorPoint.y), scissorWidth, scissorHeight);
        _rectClippingSupport->_clippingRectDirty = false;
    }
    return _rectClippingSupport->_clippingRect;
    --]]
end

return M
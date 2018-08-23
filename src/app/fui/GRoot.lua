local GComponent = require("app.fui.GComponent")
local GGraph = require("app.fui.GGraph")

local GCoroutine = require("app.fui.utils.GCoroutine")

local InputProcessor = require("app.fui.event.InputProcessor")

---@class GRoot:GComponent
---@field protected _windowSizeListener
---@field protected _inputProcessor
---@field protected _modalLayer
---@field protected _modalWaitPane
---@field protected _tooltipWin
---@field protected _defaultTooltipWin
local M = class("GRoot", GComponent)

M._soundVolumeScale = 1

function M:ctor()
    M.super.ctor(self)

    self._routines = {}

    self._popupStack = {}
    self._justClosedPopups = {}

end

function M:doDestory()
    M.super.doDestory(self)

    self._inputProcessor = nil

    if self._modalWaitPane then
        self._modalWaitPane:doDestory()
        self._modalWaitPane = nil
    end

    if self._defaultTooltipWin then
        self._defaultTooltipWin:doDestory()
        self._defaultTooltipWin = nil
    end

    if self._modalLayer then
        self._modalLayer:doDestory()
        self._modalLayer = nil
    end
end

function M:init(scene, zorder)
    M.super.init(self, scene)

    self._inputProcessor = InputProcessor.new(self)
    self._inputProcessor:setCaptureCallback(handler(self, self.onTouchEvent));

    self.name = "root"

    --初始化一个协程，用于定时器
    self._coroutine = GCoroutine.new()

    self._displayObject:scheduleUpdateWithPriorityLua(handler(self, self.coroutineUpdate), cc.PRIORITY_SYSTEM)

    --[[
    _inputProcessor = new InputProcessor(this);
    _inputProcessor->setCaptureCallback(CC_CALLBACK_1(GRoot::onTouchEvent, this));

#ifdef CC_PLATFORM_PC
    _windowSizeListener = Director::getInstance()->getEventDispatcher()->addCustomEventListener(GLViewImpl::EVENT_WINDOW_RESIZED, CC_CALLBACK_0(GRoot::onWindowSizeChanged, this));
#endif
    --]]

    self:onWindowSizeChanged()

    if zorder then
        scene:addChild(self._displayObject, zorder)
    else
        scene:addChild(self._displayObject)
    end
end

function M:showWindow(win)
    self:addChild(win);
    self:adjustModalLayer();
end

function M:hideWindow(win)
    win:hide();
end

function M:hideWindowImmediately(win)
    if (win:getParent() == self) then
        self:removeChild(win);
    end

    self:adjustModalLayer();
end

function M:bringToFront(win)
    local cnt = self:numChildren();
    local i;
    if (self._modalLayer:getParent() and false == win:isModal()) then
        i = self:getChildIndex(self._modalLayer);
    else
        i = cnt;
    end

    for i = cnt, 1, -1 do
        local g = self:getChildAt(i)
        if g == win then
            return
        end
        if iskindof(g, "Window") then
            break
        end
    end

    if i >= 1 then
        self:setChildIndex(win, i)
    end
end

function M:showModalWait()
    self:getModalWaitingPane();
    if self._modalWaitPane then
        self:addChild(self._modalWaitPane);
    end
end

function M:closeModalWait()
    if (self._modalWaitPane ~= nil and self._modalWaitPane:getParent() ~= nil) then
        self:removeChild(self._modalWaitPane);
    end
end

function M:closeAllExceptModals()
    for idx = #self._children, 1, -1 do
        local v = self._children[idx]
        if iskindof(v, "Window") and v:isModal() == false then
            self:hideWindowImmediately(v)
        end
    end
end

function M:closeAllWindows()
    for idx = #self._children, 1, -1 do
        local v = self._children[idx]
        if iskindof(v, "Window") then
            self:hideWindowImmediately(v)
        end
    end
end

function M:getTopWindow()
    for idx = #self._children, 1, -1 do
        local v = self._children[idx]
        if iskindof(v, "Window") then
            return v
        end
    end

    return nil
end

function M:getModalWaitingPane()
    if UIConfig.globalModalWaiting and UIConfig.globalModalWaiting ~= "" then
        if (self._modalWaitPane == nil) then
            self._modalWaitPane = UIPackage.createObjectFromURL(UIConfig.globalModalWaiting);
            self._modalWaitPane:setSortingOrder(INT_MAX);
        end

        self._modalWaitPane:setSize(self:getWidth(), self:getHeight());
        self._modalWaitPane:addRelation(self, T.RelationType.Size);

        return self._modalWaitPane;
    else
        return nil
    end
end

function M:getModalLayer()
    if self._modalLayer==nil then
        self:createModalLayer()
    end

    return self._modalLayer
end

function M:hasModalWindow()
    return self._modalLayer~=nil and self._modalLayer:getParent()~=nil
end

function M:isModalWaiting()
    return self._modalWaitPane~=nil and self._modalWaitPane:onStage()==true
end

function M:getInputProcessor()
    return self._inputProcessor
end

function M:getTouchPosition(touchId)
    return self._inputProcessor:getTouchPosition(touchId)
end

function M:getTouchTarget()
    return self._inputProcessor:getRecentInput():getTarget()
end

function M:handlePositionChanged()
    self._displayObject:setPosition(0, self._size.height)
end

function M:onEnter()
    M.super.onEnter(self)
    UIRoot = self
end

function M:onExit()
    M.super.onExit(self)
    if UIRoot == self then
        UIRoot = nil
    end
end

function M:onCleanup()

end

---@param popup GObject
---@param dir PopupDirection
function M:togglePopup(popup, target, dir)
    if not dir then
        dir = T.PopupDirection.AUTO
    end

    if table.indexof(self._justClosedPopups, popup) ~= false then
        return
    end

    self:showPopup(popup, target, dir)
end

---@param popup GObject
---@param dir PopupDirection
function M:showPopup(popup, target, dir)
    if not dir then
        dir = T.PopupDirection.AUTO
    end

    if (#self._popupStack > 0) then
        self:hidePopup(popup);
    end

    table.insert(self._popupStack, popup)

    if target then
        local p = target
        while p do
            if (p:getParent() == self) then
                if (popup:getSortingOrder() < p:getSortingOrder()) then
                    popup:setSortingOrder(p:getSortingOrder());
                end
                break ;
            end
            p = p:getParent();
        end
    end

    self:addChild(popup);
    self:adjustModalLayer();

    if iskindof(popup, "Window") and target == nil and dir == T.PopupDirection.AUTO then
        return
    end

    local pos = self:getPopupPosition(popup, target, dir);
    popup:setPosition(pos.x, pos.y);

end

---@param popup GObject
function M:hidePopup(popup)
    if (popup) then
        local idx = table.indexof(self._popupStack, popup)
        if idx ~= false then
            for i = #self._popupStack, idx, -1 do
                local v = self._popupStack[i]
                self:closePopup(v)
                table.remove(self._popupStack)
            end
        end
    else
        for i, v in ipairs(self._popupStack) do
            self:closePopup(v)
        end
        self._popupStack = {}
    end
end

function M:hasAnyPopup()
    return #self._popupStack > 0
end

function M:getPopupPosition(popup, target, dir)
    local pos = cc.p(0, 0);
    local size = cc.p(0, 0);
    if target then
        pos = target:localToGlobal(cc.p(0, 0));
        pos = self:globalToLocal(pos);
        local p = cc.p(target:getSize().width, target:getSize().height)
        size = target:localToGlobal(p);
        size = self:globalToLocal(size);
        size = cc.pSub(size, pos);
    else
        pos = self:globalToLocal(self._inputProcessor:getRecentInput():getPosition());
    end

    local xx, yy;
    xx = pos.x;
    if (xx + popup:getWidth() > self:getWidth()) then
        xx = xx + size.x - popup:getWidth();
    end
    yy = pos.y + size.y;

    if ((dir == T.PopupDirection.AUTO and yy + popup:getHeight() > self:getHeight())
            or dir == T.PopupDirection.UP) then
        yy = pos.y - popup:getHeight() - 1;
        if (yy < 0) then
            yy = 0;
            xx = xx + size.x / 2;
        end
    end

    return cc.p(math.round(xx), math.round(yy))
end

--[[
    void showTooltips(const std::string& msg);
    void showTooltipsWin(GObject* tooltipWin);
    void hideTooltips();
--]]


--[[ 声音相关
    void playSound(const std::string& url, float volumeScale = 1);
    bool isSoundEnabled() const { return _soundEnabled; }
    void setSoundEnabled(bool value);
    float getSoundVolumeScale() const { return _soundVolumeScale; }
    void setSoundVolumeScale(float value);

--]]

function M:setSoundPlayFunc(func)
    self._sound_play_func = func
end

function M:playSound(url, volumnScale)
    if self._soundEnabled == false then
        return
    end

    local pi = UIPackage.getItemByURL(url)
    if pi then
        print("playSound ", pi.file, M._soundVolumeScale * volumnScale)
        if self._sound_play_func then
            self._sound_play_func(pi.file, M._soundVolumeScale * volumnScale)
        end
    else
        if self._sound_play_func then
            self._sound_play_func(url, M._soundVolumeScale * volumnScale)
        end
    end
end

function M:onWindowSizeChanged()
    self:setSize(display.width, display.height)
end

function M:closePopup(target)
    if (target and target:getParent()) then
        if iskindof(target, "Window") then
            target:hide();
        else
            self:removeChild(target);
        end
    end
end

function M:checkPopups()
    self._justClosedPopups = {}
    if #self._popupStack > 0 then
        local mc = self._inputProcessor:getRecentInput():getTarget();
        local handled = false;
        while (mc ~= nil and mc ~= self) do

            local idx = table.indexof(self._popupStack, mc)
            if idx ~= false then
                for i = #self._popupStack, idx + 1, -1 do
                    local v = self._popupStack[i]
                    self:closePopup(v)
                    table.remove(self._popupStack)
                end
                handled = true
                break
            end

            mc = mc:getParent();
        end

        if (handled == false) then
            for i = #self._popupStack, 1, -1 do
                local v = self._popupStack[i]
                table.insert(self._justClosedPopups, v)
                self:closePopup(v)
            end
            self._popupStack = {}
        end
    end
end

function M:adjustModalLayer()
    if (not self._modalLayer) then
        self:createModalLayer();
    end

    local cnt = self:numChildren();

    if (self._modalWaitPane and self._modalWaitPane:getParent()) then
        self:setChildIndex(self._modalWaitPane, cnt);  --这里可能有bug
    end

    for i = cnt, 1, -1 do
        local child = self:getChildAt(i)
        if iskindof(child, "Window") and child:isModal() then
            if self._modalLayer:getParent() == nil then
                self:addChildAt(self._modalLayer, i);
            else
                self:setChildIndexBefore(self._modalLayer, i);
            end
            return
        end
    end

    if self._modalLayer:getParent() then
        self:removeChild(self._modalLayer)
    end
end

function M:createModalLayer()
    self._modalLayer = GGraph.new();
    self._modalLayer:init()
    self._modalLayer:drawRect(self:getWidth(), self:getHeight(), 0, cc.c4f(255, 255, 255, 255), UIConfig.modalLayerColor);
    self._modalLayer:addRelation(self, T.RelationType.Size);
end

function M:onTouchEvent(eventType)
    if (eventType == T.UIEventType.TouchBegin) then
        if (self._tooltipWin) then
            self:hideTooltips();
        end
        self:checkPopups();
    end

end

function M:coroutineUpdate(dt)
    self._coroutine:updateCoroutine(dt)
    GActionManager.inst():update(dt)
end

---@return GCoroutine
function M:getCoroutine()
    return self._coroutine
end

function M:PlayRoutine(obj, func, dt)
    local r = self._displayObject:performWithDelay(function()
        func(obj)
    end, dt)
    local key = tostring(obj) .. tostring(func)
    self._routines[key] = r
end

function M:RemoveRoutine(obj, func)
    local key = tostring(obj) .. tostring(func)
    local r = self._routines[key]
    if tolua.isnull(r) == false then
        self._displayObject:stopAction(r)
    end
    self._routines[key] = nil
end

return M
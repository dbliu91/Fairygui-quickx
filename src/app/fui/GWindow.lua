local GComponent = require("app.fui.GComponent")

local M = class("Window", GComponent)

function M:ctor(...)
    M.super.ctor(self, ...)
    self._requestingCmd = 0
    self._frame = nil

    self._contentPane = nil
    self._modalWaitPane = nil
    self._closeButton = nil
    self._dragArea = nil
    self._contentArea = nil

    self._modal = false
    self._inited = false
    self._loading = false
    self._bringToFontOnClick = UIConfig.bringWindowToFrontOnClick

    self._uiSources = {}

end

function M:doDestory()
    M.super.doDestory(self)
    G_doDestory(self._contentPane);
    G_doDestory(self._frame);
    G_doDestory(self._closeButton);
    G_doDestory(self._dragArea);
    G_doDestory(self._modalWaitPane);
end

function M:show()
    UIRoot:showWindow(self)
end

function M:hide()
    if (self:isShowing()) then
        self:doHideAnimation();
    end
end

function M:hideImmediately()
    UIRoot:hideWindowImmediately(self)
end

function M:toggleStatus()
    if (self:isTop()) then
        self:hide();
    else
        self:show();
    end
end

function M:bringToFront()
    UIRoot:bringToFront(self)
end

function M:isShowing()
    return self._parent ~= nil
end

function M:isTop()
    return self._parent ~= nil and self._parent:getChildIndex(self) == self._parent:numChildren();
end

function M:isModal()
    return self._modal
end

function M:setModal(value)
    self._modal = value
end

function M:showModalWait(requestingCmd)
    if not requestingCmd then
        requestingCmd = 0
    end

    if requestingCmd ~= 0 then
        self._requestingCmd = requestingCmd
    end

    if UIConfig.windowModalWaiting and UIConfig.windowModalWaiting ~= "" then
        if self._modalWaitPane == nil then
            self._modalWaitPane = UIPackage.createObjectFromURL(UIConfig.windowModalWaiting);
        end

        self:layoutModalWaitPane()
        self:addChild(self._modalWaitPane)
    end
end

function M:layoutModalWaitPane()
    if (self._contentArea) then
        local pt = self._frame:localToGlobal(cc.p(0, 0));
        pt = self:globalToLocal(pt);
        self._modalWaitPane:setPosition(pt.x + self._contentArea:getX(), pt.y + self._contentArea:getY());
        self._modalWaitPane:setSize(self._contentArea:getWidth(), self._contentArea:getHeight());
    else
        self._modalWaitPane:setSize(self._size.width, self._size.height);
    end
end

function M:closeModalWait(requestingCmd)
    if not requestingCmd then
        requestingCmd = 0
    end

    if requestingCmd ~= 0 then
        if self._requestingCmd ~= requestingCmd then
            return false
        end
    end

    self._requestingCmd = 0

    if (self._modalWaitPane and self._modalWaitPane:getParent()) then
        self:removeChild(self._modalWaitPane);
    end

    return true;
end

function M:initWindow()
    if (self._inited == true or self._loading == true) then
        return ;
    end

    if #self._uiSources > 0 then
        self._loading = false;

        for i, v in ipairs(self._uiSources) do
            if v:isLoaded() == false then
                v:load(handler(self, self.onUILoadComplete))
                self._loading = true
            end
        end

        if (self._loading == false) then
            self:_initWindow();
        end
    else
        self:_initWindow();
    end

end

function M:_initWindow()
    self._inited = true;
    self:onInit();

    if (self:isShowing()) then
        self:doShowAnimation();
    end
end

function M:addUISource(uiSource)
    table.insert(self._uiSources, uiSource)
end

function M:isBringToFrontOnClick()
    return self._bringToFontOnClick
end

function M:setBringToFrontOnClick(value)
    self._bringToFontOnClick = value
end

function M:getContentPane()
    return self._contentPane
end

function M:setContentPane(value)
    if (self._contentPane ~= value) then
        if (self._contentPane) then
            self:removeChild(self._contentPane);
            G_doDestory(self._frame);
        end

        self._contentPane = value;

        if (self._contentPane) then

            self:addChild(self._contentPane);
            self:setSize(self._contentPane:getWidth(), self. _contentPane:getHeight());
            self._contentPane:addRelation(self, T.RelationType.Size);
            self._frame = self._contentPane:getChild("frame")

            if (self._frame and iskindof(self._frame, "GComponent")) then
                self:setCloseButton(self._frame:getChild("closeButton"));
                self:setDragArea(self._frame:getChild("dragArea"));
                self:setContentArea(self._frame:getChild("contentArea"));
            end
        else
            self._frame = nil;
        end
    end
end

function M:getFrame()
    return self._frame
end

function M:getCloseButton()
    return self._closeButton
end

function M:setCloseButton(value)
    if (self._closeButton) then
        self._closeButton:removeClickListener(self);
    end
    self._closeButton = value;
    if (self._closeButton) then
        self._closeButton:addClickListener(handler(self, self.closeEventHandler), self);
    end
end

function M:getDragArea()
    return self._dragArea
end

function M:setDragArea(value)
    if (self._dragArea ~= value) then
        if (self._dragArea) then
            self._dragArea:setDraggable(false);
            self._dragArea:removeEventListener(T.UIEventType.DragStart, self);
        end

        self._dragArea = value;
        if (self._dragArea) then
            if iskindof(self._dragArea, "GGraph") and self._dragArea:isEmpty() then
                self._dragArea:drawRect(self._dragArea:getWidth(), self._dragArea:getHeight(), 0, cc.c4f(0, 0, 0, 0), cc.c4f(0, 0, 0, 0));
            end

            self._dragArea:setDraggable(true);
            self._dragArea:addEventListener(T.UIEventType.DragStart, handler(self, self.onDragStart), self);
        end
    end
end

function M:getContentArea()
    return self._contentArea
end

function M:setContentArea(value)
    self._contentArea = value;
end

function M:getModalWaitingPane()
    return self._modalWaitPane
end

function M:handleInit()
    M.super.handleInit(self)

    self:addEventListener(T.UIEventType.TouchBegin, handler(self, self.onTouchBegin))
end

function M:onInit()
end
function M:onShown()
end
function M:onHide()
end

function M:doShowAnimation()
    self:onShown();
end

function M:doHideAnimation()
    self:hideImmediately();
end

function M:onEnter()
    M.super.onEnter(self)

    if (self._inited == false) then
        self:initWindow();
    else
        self:doShowAnimation();
    end
end

function M:onExit()
    M.super.onExit(self)

    self:closeModalWait();
    self:onHide();
end

function M:closeEventHandler(context)
    self:hide()
end

function M:onUILoadComplete()
    for i, v in ipairs(self._uiSources) do
        if v:isLoaded() == false then
            return
        end
    end

    self._loading = false
    self:_initWindow()
end

function M:onTouchBegin(context)
    if (self:isShowing() and self._bringToFontOnClick == true) then
        self:bringToFront();
    end
end

function M:onDragStart(context)
    context:preventDefault();
    self:startDrag(context:getInput():getTouchId());
end

return M
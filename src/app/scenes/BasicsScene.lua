local GGraph = require("app.fui.GGraph")
local PopupMenu = require("app.fui.PopupMenu")

local DemoScene = require("app.scenes.DemoScene")

local Window1 = require("app.scenes.Window1")
local Window2 = require("app.scenes.Window2")

local M = class("BasicsScene", DemoScene)

function M:ctor(...)
    self._demoObjects = {}
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIConfig.buttonSound = "ui://Basics/click"
    UIConfig.verticalScrollBar = "ui://Basics/ScrollBar_VT"
    UIConfig.horizontalScrollBar = "ui://Basics/ScrollBar_HZ"
    UIConfig.tooltipsWin = "ui://Basics/WindowFrame"
    UIConfig.popupMenu = "ui://Basics/PopupMenu"

    UIPackage.addPackage("UI/Basics")

    local _view = UIPackage.createObject("Basics", "Main")
    self._groot:addChild(_view)

    self._backBtn = _view:getChild("btn_Back")
    self._backBtn:setVisible(false)
    self._backBtn:addClickListener(handler(self, self.onClickBack))

    self._demoContainer = _view:getChild("container");
    self._cc = _view:getController("c1");

    local cnt = _view:numChildren()
    for i = 1, cnt do
        local obj = _view:getChildAt(i)
        if (obj:getGroup() ~= nil and obj:getGroup().name == "btns") then
            obj:addClickListener(handler(self, self.runDemo))
        end
    end

end

function M:runDemo(context)
    local name = context:getSender().name
    name = string.sub(name, 5)
    local v = self._demoObjects[name]
    if not v then
        v = UIPackage.createObject("Basics", "Demo_" .. name)
        self._demoObjects[name] = v
    end

    self._demoContainer:removeChildren()
    self._demoContainer:addChild(v)
    self._cc:setSelectedIndex(2)
    self._backBtn:setVisible(true)

    if (name == "Text") then
        self:playText();
    elseif (name == "Depth") then
        self:playDepth();
    elseif (name == "Window") then
        self:playWindow();
    elseif (name == "Drag&Drop") then
        self:playDragDrop();
    elseif (name == "Popup") then
        self:playPopup();
    end

end

function M:onClickBack(context)
    self._cc:setSelectedIndex(1)
    self._backBtn:setVisible(false)
end

local startPos = cc.p(0,0)
function M:playDepth()
    local obj = self._demoObjects["Depth"]
    local testContainer = obj:getChild("n22")
    local fixedObj = testContainer:getChild("n0");
    fixedObj:setSortingOrder(100);
    fixedObj:setDraggable(true);

    local numChildren = testContainer:numChildren();
    local i = 1;
    while (i <= numChildren) do
        local child = testContainer:getChildAt(i);
        if (child ~= fixedObj) then

            testContainer:removeChildAt(i);
            numChildren = numChildren -1;
        else
            i = i + 1;
        end
    end
    startPos = fixedObj:getPosition();

    obj:getChild("btn0"):addClickListener(function (context)
        local graph = GGraph.new();
        graph:init()
        startPos.x =startPos.x+ 10;
        startPos.y =startPos.y+ 10;
        graph:setPosition(startPos.x, startPos.y);
        graph:drawRect(150, 150, 1, cc.c4f(0,0,0,1), cc.c4f(1,0,0,1));
        obj:getChild("n22"):addChild(graph);
    end,self)

    obj:getChild("btn1"):addClickListener(function (context)
        local graph = GGraph.new();
        graph:init()
        startPos.x =startPos.x+ 10;
        startPos.y =startPos.y+ 10;
        graph:setPosition(startPos.x, startPos.y);
        graph:drawRect(150, 150, 1, cc.c4f(0,0,0,1), cc.c4f(0,1,0,1));
        graph:setSortingOrder(200);
        obj:getChild("n22"):addChild(graph);
    end,self)

end

function M:playPopup()
    if (self._pm == nil) then
        self._pm = PopupMenu.new();
        self._pm:init()
        self._pm:addItem("Item 1", handler(self, self.onClickMenu));
        self._pm:addItem("Item 2", handler(self, self.onClickMenu));
        self._pm:addItem("Item 3", handler(self, self.onClickMenu));
        self._pm:addItem("Item 4", handler(self, self.onClickMenu));
    end

    if (self._popupCom == nil) then
        self._popupCom = UIPackage.createObject("Basics", "Component12");
        self._popupCom:center();
    end

    local obj = self._demoObjects["Popup"]
    obj:getChild("n0"):addClickListener(function(context)
        self._pm:show(context:getSender(), T.PopupDirection.DOWN);
    end)

    obj:getChild("n1"):addClickListener(function(context)
        self._groot:showPopup(self._popupCom);
    end)

    obj:addEventListener(T.UIEventType.RightClick, function(context)
        self._pm:show();
    end)
end

function M:playWindow()
    local obj = self._demoObjects["Window"]

    if (self._winA == nil) then
        self._winA = Window1.new()
        self._winA:init()

        self._winB = Window2.new()
        self._winB:init()

        obj:getChild("n0"):addClickListener(function(context)
            self._winA:show();
        end)

        obj:getChild("n1"):addClickListener(function(context)
            self._winB:show();
        end)
    end

end

function M:playDragDrop()

    local obj = self._demoObjects["Drag&Drop"]
    obj:getChild("a"):setDraggable(true);

    local b = obj:getChild("b");
    b:setDraggable(true);
    b:addEventListener(T.UIEventType.DragStart,function (context)
        --Cancel the original dragging, and start a new one with a agent.
        context:preventDefault();
        DragDropManager.getInstance():startDrag(b:getIcon(), b:getIcon(), context:getInput():getTouchId());
    end)

    local c = obj:getChild("c");
    c:setIcon("")
    c:addEventListener(T.UIEventType.Drop,function (context)
        c:setIcon(context:getDataValue());
    end)

    local bounds = obj:getChild("n7")
    local size = bounds:getSize()
    local rect = bounds:transformRect(cc.rect(0,0, size.width,size.height), self._groot);

    ---!!Because at this time the container is on the right side of the stage and beginning to move to left(transition), so we need to caculate the final position
    rect.x =rect.x - obj:getParent():getX()
    ----

    local d = obj:getChild("d")
    d:setDraggable(true)
    d:setDragBounds(rect)

end

function M:onClickMenu(context)
    local itemObject = context:getData();
    print("click ", itemObject:getText());
end

function M:playText(context)
    
end

return M
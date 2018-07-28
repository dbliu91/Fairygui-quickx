local DemoScene = require("app.scenes.DemoScene")

local M = class("LoopListScene", DemoScene)

function M:ctor(...)
    self._list = nil
    self._view = nil
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/LoopList");
    UIConfig.horizontalScrollBar = "";
    UIConfig.verticalScrollBar = "";

    self._view = UIPackage.createObject("LoopList", "Main");
    self._groot:addChild(self._view);

    self._list = self._view:getChild("list")
    self._list.itemRenderer = function(index, obj)
        self:renderListItem(index, obj)
    end
    self._list:setVirtualAndLoop();
    self._list:setNumItems(5);
    self._list:addEventListener(T.UIEventType.Scroll, handler(self,self.doSpecialEffect));

    self:doSpecialEffect()
end

function M:renderListItem(index, obj)
    obj:setPivot(0.5, 0.5);
    obj:setIcon("ui://LoopList/n" .. tostring(index));
end

function M:doSpecialEffect(context)
    --change the scale according to the distance to middle
    local midX = self._list:getScrollPane():getPosX() + self._list:getViewWidth() / 2;
    local cnt = self._list:numChildren();

    for i = 1, cnt do
        local obj = self._list:getChildAt(i);
        local dist = math.abs(midX - obj:getX() - obj:getWidth() / 2);
        if (dist > obj:getWidth()) then
            --no intersection
            obj:setScale(1, 1);
        else
            local ss = 1 + (1 - dist / obj:getWidth()) * 0.24;
            obj:setScale(ss, ss);
        end
    end

    local first = self._list:getFirstChildInView()

    local idx = LUA_MOD(first+1,self._list:getNumItems())
    local path = tostring(idx)
    self._view:getChild("n3"):setText(path);

end

return M
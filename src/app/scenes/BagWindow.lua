local Window = require("app.fui.GWindow")
local GActionInterval = require("app.fui.action.GActionInterval")
local GSequence = require("app.fui.action.GSequence")

local M = class("BagWindow", Window)

function M:onInit()
    self:setContentPane(UIPackage.createObject("Bag", "BagWin"));

    self:center();
    self:setModal(true);

    self._list = self._contentPane:getChild("list");
    self._list:addEventListener(T.UIEventType.ClickItem, handler(self, self.onClickItem));
    self._list.itemRenderer = handler(self, self.renderListItem);
    self._list:setNumItems(45);
end

function M:renderListItem(index, obj)
    obj:setIcon("icons/i" .. checkint(math.random(1,10)-1) .. ".png");
    obj:setText("" .. checkint(math.random(1,100)));
end


function M:doShowAnimation()
    self:setScale(0.1, 0.1);
    self:setPivot(0.5, 0.5);

    --[[
    ActionInterval* action = ActionFloat2::create(0.3f, getScale(), Vec2::ONE, CC_CALLBACK_2(Window2::setScale, this));
    action = composeActions(action, tweenfunc::Quad_EaseOut, 0, CC_CALLBACK_0(Window2::onShown, this));
    displayObject()->runAction(action);
    --]]

    local action = GActionInterval.new()
    action:setDuration(0.3)
    action._from = { self:getScale().x,self:getScale().y }
    action._to = { 1,1 }
    action:reset_delta()
    action.update = function(action, delta)
        local v1 = action._to[1] - action._delta[1] * (1 - delta)
        local v2 = action._to[2] - action._delta[2] * (1 - delta)
        self:setScale(v1,v2)
    end
    action.completeAction=function ()
        self:onShown()
    end

    UIRoot:getActionManager():addAction(action, self, false)
end

function M:doHideAnimation()
    --[[
        ActionInterval* action = ActionFloat2::create(0.3f, getScale(), Vec2(0.1f, 0.1f), CC_CALLBACK_2(Window2::setScale, this));
    action = composeActions(action, tweenfunc::Quad_EaseOut, 0, CC_CALLBACK_0(Window2::hideImmediately, this));
    displayObject()->runAction(action);
    --]]

    local action = GActionInterval.new()
    action:setDuration(0.3)
    action._from = { self:getScale().x,self:getScale().y }
    action._to = { 0.1,0.1 }
    action:reset_delta()
    action.update = function(action, delta)
        local v1 = action._to[1] - action._delta[1] * (1 - delta)
        local v2 = action._to[2] - action._delta[2] * (1 - delta)
        self:setScale(v1,v2)
    end
    action.completeAction=function ()
        self:hideImmediately()
    end

    UIRoot:getActionManager():addAction(action, self, false)

end

function M:onClickItem(context)
    local item = context:getData();
    self._contentPane:getChild("n11"):setIcon(item:getIcon());
    self._contentPane:getChild("n13"):setText(item:getText());
end

return M
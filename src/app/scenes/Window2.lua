local GActionInterval = require("app.fui.action.GActionInterval")

local Window = require("app.fui.GWindow")

local M = class("Window2",Window)

function M:onInit()
    self:setContentPane(UIPackage.createObject("Basics", "WindowB"));
    self:center();
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

function M:onShown()
    self._contentPane:getTransition("t1"):play();
end

function M:onHide()
    self._contentPane:getTransition("t1"):stop();
end

return M
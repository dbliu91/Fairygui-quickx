local DemoScene = require("app.scenes.DemoScene")

local GActionInterval = require("app.fui.action.GActionInterval")

local M = class("TransitionDemoScene", DemoScene)

function M:ctor(...)
    self._demoObjects = {}

    M.super.ctor(self, ...)
end

function M:continueInit()


    UIPackage.addPackage("UI/Transition")

    local _view = UIPackage.createObject("Transition", "Main")
    self._groot:addChild(_view)

    self._btnGroup = _view:getChild("g0")

    self._g1 = UIPackage.createObject("Transition", "BOSS")
    self._g2 = UIPackage.createObject("Transition", "BOSS_SKILL")
    self._g3 = UIPackage.createObject("Transition", "TRAP")
    self._g4 = UIPackage.createObject("Transition", "GoodHit")
    self._g5 = UIPackage.createObject("Transition", "PowerUp")

    self._g5:getTransition("t0"):setHook("play_num_now", handler(self, self.playNum))


    _view:getChild("btn0"):addClickListener(function ()
        self:play(self._g1)
    end)


    _view:getChild("btn1"):addClickListener(function ()
        self:play(self._g2)
    end)


    _view:getChild("btn2"):addClickListener(function ()
        self:play(self._g3)
    end)


    _view:getChild("btn3"):addClickListener(function ()
        self:play4()
    end)


    _view:getChild("btn4"):addClickListener(function ()
        self:play5()
    end)

end

function M:play(target)
    self._btnGroup:setVisible(false)
    self._groot:addChild(target)
    local t = target:getTransition("t0")
    t:play(function ()
        self._btnGroup:setVisible(true)
        self._groot:removeChild(target)
    end)
end

function M:play4(context)
    self._btnGroup:setVisible(false)
    self._g4:setPosition(self._groot:getWidth() - self._g4:getWidth() - 20, 100);
    self._groot:addChild(self._g4);
    local t = self._g4:getTransition("t0");
    t:play(3,0,function ()
        self._btnGroup:setVisible(true);
        self._groot:removeChild(self._g4);
    end)
end

function M:play5(context)
    self._btnGroup:setVisible(false)
    self._g5:setPosition(20,self._groot:getHeight() - self._g5:getHeight() - 100);
    self._groot:addChild(self._g5);
    local t = self._g5:getTransition("t0");

    self._startValue = 10000;
    local add = 1000 + math.random(0,2000);
    self._endValue = self._startValue + add

    self._g5:getChild("value"):setText(tostring(self._startValue));
    self._g5:getChild("add_value"):setText(tostring(add));

    t:play(function ()
        self._btnGroup:setVisible(true);
        self._groot:removeChild(self._g5);
    end)
end

function M:playNum()
    local action = GActionInterval.new()
    action:setDuration(0.3)
    action._from = { self._startValue }
    action._to = { self._endValue }
    action:reset_delta()
    action.update = function(action, delta)
        local v1 = action._to[1] - action._delta[1] * (1 - delta)
        local value = checkint(v1)
        self._g5:getChild("value"):setText(tostring(value))
    end
    action.completeAction=function ()
    end

    UIRoot:getActionManager():addAction(action, self, false)
end

return M
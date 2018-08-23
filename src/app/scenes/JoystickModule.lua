
local UIEventDispatcher = require("app.fui.event.UIEventDispatcher")

local GActionInterval = require("app.fui.action.GActionInterval")
local GSequence = require("app.fui.action.GSequence")

local M = class("JoystickModule",UIEventDispatcher)

M.MOVE =  100;
M.END = 101;

function M:ctor()
    M.super.ctor(self)
    self._startStageX = 0
    self._startStageY = 0
    self._lastStageX = 0
    self._lastStageY = 0
end

function M:init(mainView)

    self._button = mainView:getChild("joystick")
    self._button:setChangeStateOnClick(false)

    self._thumb = self._button:getChild("thumb");
    self._touchArea = mainView:getChild("joystick_touch");
    self._center = mainView:getChild("joystick_center");

    self._InitX = self._center:getX() + self._center:getWidth() / 2;
    self._InitY = self._center:getY() + self._center:getHeight() / 2;

    self.touchId = -1;
    self._radius = 150;

    self._touchArea:addEventListener(T.UIEventType.TouchBegin,handler(self,self.onTouchBegin))
    self._touchArea:addEventListener(T.UIEventType.TouchMove,handler(self,self.onTouchMove))
    self._touchArea:addEventListener(T.UIEventType.TouchEnd,handler(self,self.onTouchEnd))
end

function M:onTouchBegin(context)
    if (self.touchId == -1) then--First touch
        local evt = context:getInput()
        self.touchId = evt:getTouchId()

        --self._button:displayObject():stopActionByTag(1)
        GActionManager.inst():removeActionByTag(1,self._button)

        local pt = UIRoot:globalToLocal(evt:getPosition())
        local bx = pt.x;
        local by = pt.y;
        self._button:setSelected(true);

        if (bx < 0) then
            bx = 0
        elseif (bx > self._touchArea:getWidth()) then
            bx = self._touchArea:getWidth()
        end

        if (by > UIRoot:getHeight()) then
            by = UIRoot:getHeight()
        elseif (by < self._touchArea:getY()) then
            by = self._touchArea:getY()
        end

        self._lastStageX = bx;
        self._lastStageY = by;
        self._startStageX = bx;
        self._startStageY = by;

        self._center:setVisible(true)
        self._center:setPosition(bx - self._center:getWidth() / 2, by - self._center:getHeight() / 2);
        self._button:setPosition(bx - self._button:getWidth() / 2, by - self._button:getHeight() / 2);

        local deltaX = bx - self._InitX;
        local deltaY = by - self._InitY;
        local degrees = math.atan2(deltaY,deltaX)*180/math.pi;
        self._thumb:setRotation(degrees+90)

        context:captureTouch()
    end
end

function M:onTouchMove(context)
    local evt = context:getInput()
    if self.touchId ~= -1 and evt:getTouchId()==self.touchId then
        local pt = UIRoot:globalToLocal(evt:getPosition());
        local bx = pt.x;
        local by = pt.y;
        local moveX = bx - self._lastStageX;
        local moveY = by - self._lastStageY;
        self._lastStageX = bx;
        self._lastStageY = by;
        local buttonX = self._button:getX() + moveX;
        local buttonY = self._button:getY() + moveY;

        local offsetX = buttonX + self._button:getWidth() / 2 - self._startStageX;
        local offsetY = buttonY + self._button:getHeight() / 2 - self._startStageY;

        local rad = math.atan2(offsetY, offsetX);
        local degree = rad * 180 / math.pi;
        self._thumb:setRotation(degree + 90);

        local maxX = self._radius * math.cos(rad);
        local maxY = self._radius * math.sin(rad);

        if ( math.abs(offsetX) > math.abs(maxX)) then
            offsetX = maxX;
        end

        if (math.abs(offsetY) > math.abs(maxY)) then
            offsetY = maxY;
        end

        buttonX = self._startStageX + offsetX;
        buttonY = self._startStageY + offsetY;

        if (buttonX < 0) then
            buttonX = 0;
        end

        if (buttonY > UIRoot:getHeight()) then
            buttonY = UIRoot:getHeight();
        end

        self._button:setPosition(buttonX - self._button:getWidth() / 2, buttonY - self._button:getHeight() / 2);

        self:dispatchEvent(M.MOVE,nil,degree)

    end

end

function M:onTouchEnd(context)
    local evt = context:getInput()
    if self.touchId ~= -1 and evt:getTouchId()==self.touchId then
        self.touchId = -1

        self._thumb:setRotation(self._thumb:getRotation()+180)
        self._center:setVisible(false)

        --[[
        Action* action = Sequence::createWithTwoActions(ActionFloat2::create(0.3f,
            _button->getPosition(),
            Vec2(_InitX - _button->getWidth() / 2, _InitY - _button->getHeight() / 2), CC_CALLBACK_2(GObject::setPosition, _button)),
        CallFunc::create([this]()
        {
            _button->setSelected(false);
            _thumb->setRotation(0);
            _center->setVisible(true);
            _center->setPosition(_InitX - _center->getWidth() / 2, _InitY - _center->getHeight() / 2);
        }));
        action->setTag(1);

        _button->displayObject()->runAction(action);
        dispatchEvent(END);
        --]]
        ---[[
        local action = GActionInterval.new()
        action:setDuration(0.1)
        action._from = {
            self._button:getPosition().x,
            self._button:getPosition().y,
        }
        action._to = {
            self._InitX - self._button:getWidth() / 2,
            self._InitY - self._button:getHeight() / 2,
        }

        action:reset_delta()
        action.update = function(action, delta)
            local x = action._to[1] - action._delta[1] * (1 - delta)
            local y = action._to[2] - action._delta[2] * (1 - delta)

            self._button:setPosition(x,y)
        end

        action.completeAction = function()
            self._button:setSelected(false);
            self._thumb:setRotation(0);
            self._center:setVisible(true);
            self._center:setPosition(self._InitX - self._center:getWidth() / 2, self._InitY - self._center:getHeight() / 2);
        end

        GActionManager.inst():addAction(action,self._button,false)
        --]]

        self:dispatchEvent(M.END)
    end
end

return M
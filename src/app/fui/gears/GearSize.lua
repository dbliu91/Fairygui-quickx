local GActionInterval = require("app.fui.action.GActionInterval")
local GSequence = require("app.fui.action.GSequence")

local GearBase = require("app.fui.gears.GearBase")

---@class GearSize
local M = class("GearSize", GearBase)

local init_default = {
    x = 0;
    y = 0;
    scale_x = 0;
    scale_y = 0;
}

function M:ctor(...)
    M.super.ctor(self, ...)

    self._storage = {}
    self._default = clone(init_default)
    self._tweenTarget = cc.rect(0, 0, 0, 0)

end

function M:init()
    self._default = {
        x = self._owner:getWidth();
        y = self._owner:getHeight();
        scale_x = self._owner:getScaleX();
        scale_y = self._owner:getScaleY();
    }
    self._storage = {}
end

function M:addStatus(pageId, value)

    if value == "-" or value == nil or value == "" then
        return
    end

    local v4 = string.split(value, ",")
    local v = {
        x = checkint(v4[1]);
        y = checkint(v4[2]);
        scale_x = checknumber(v4[3]);
        scale_y = checknumber(v4[4]);
    }
    if pageId == nil or pageId == "" then
        self._default = v
    else
        self._storage[pageId] = v
    end

end

function M:apply()

    local gv
    local v = self._storage[self._controller:getSelectedPageId()]
    if v then
        gv = clone(v)
    else
        gv = clone(self._default)
    end

    if self.tween == true and UIPackage._constructing == 0 and disableAllTweenEffect == false then

        if self._owner:displayObject():getActionByTag(T.ActionTag.GEAR_SIZE_ACTION) ~= nil then
            if self._tweenTarget.x ~= gv.x
                    or self._tweenTarget.y ~= gv.y
                    or self._tweenTarget.scale_x ~= gv.scale_x
                    or self._tweenTarget.scale_y ~= gv.scale_y
            then
                GActionManager.inst():removeActionByTag(T.ActionTag.GEAR_SIZE_ACTION, self._owner)
                self:onTweenComplete()
            else
                return
            end
        end

        local a = (gv.x ~= self._owner:getWidth() or gv.y ~= self._owner:getHeight());
        local b = (gv.scale_x ~= self._owner:getScaleX() or gv.scale_y ~= self._owner:getScaleY());

        if a or b then
            if self._owner:checkGearController("gearDisplay", self._controller) then
                self._displayLockToken = self._owner:addDisplayLock()
            end
            self._tweenTarget = gv

            --[[
            ActionInterval* action = ActionVec4::create(tweenTime,
                Vec4(_owner->getWidth(), _owner->getHeight(), _owner->getScaleX(), _owner->getScaleY()),
                gv,
                CC_CALLBACK_1(GearSize::onTweenUpdate, this, a, b));

            action = composeActions(action, easeType, delay, CC_CALLBACK_0(GearSize::onTweenComplete, this), ActionTag::GEAR_SIZE_ACTION);
            _owner->displayObject()->runAction(action);
            --]]

            ---[[

            local seq = GSequence.new()

            local delayAction = GActionInterval.new()
            delayAction:setDuration(self.delay)
            delayAction.update = function()
            end

            local action = GActionInterval.new()
            action:setDuration(self.tweenTime)
            action._from = {
                self._owner:getWidth(),
                self._owner:getHeight(),
                self._owner:getScaleX(),
                self._owner:getScaleY(),
            }
            action._to = {
                gv.x,
                gv.y,
                gv.scale_x,
                gv.scale_y,
            }

            action:reset_delta(action)
            action.update = function(action, delta)
                local arr = {}
                arr[1] = action._to[1] - action._delta[1] * (1 - delta)
                arr[2] = action._to[2] - action._delta[2] * (1 - delta)
                arr[3] = action._to[3] - action._delta[3] * (1 - delta)
                arr[4] = action._to[4] - action._delta[4] * (1 - delta)
                self:onTweenUpdate(arr, a, b)
            end

            seq:setActions({ delayAction, action })
            seq.completeAction = function()
                self:onTweenComplete()
            end

            seq:setTag(T.ActionTag.GEAR_SIZE_ACTION)
            GActionManager.inst():addAction(seq, self._owner, false)
            --]]

        end


    else
        self._owner._gearLocked = true
        self._owner:setSize(gv.x, gv.y, self._owner:checkGearController("gearXY", self._controller))
        self._owner:setScale(gv.scale_x, gv.scale_y)
        self._owner._gearLocked = false
    end
end

function M:onTweenUpdate(v, a, b)
    self._owner._gearLocked = true;

    if a then
        self._owner:setSize(v[1], v[2], self._owner:checkGearController("gearXY", self._controller));
    end

    if b then
        self._owner:setScale(v[3], v[4]);
    end

    self._owner._gearLocked = false;
end

function M:onTweenComplete()
    if (self._displayLockToken ~= 0) then
        self._owner:releaseDisplayLock(self._displayLockToken);
        self._displayLockToken = 0;
    end
    self._owner:dispatchEvent(T.UIEventType.GearStop);
end

function M:updateState()
    self._storage[self._controller:getSelectedPageId()] = {
        x = self._owner:getWidth();
        y = self._owner:getHeight();
        scale_x = self._owner:getScaleX();
        scale_y = self._owner:getScaleY();
    }
end

function M:updateFromRelations(dx, dy)

    if self._controller and #self._storage > 0 then
        for i, v in pairs(self._storage) do
            v.x = v.x + dx
            v.y = v.y + dy
        end
        self._default.x = self._default.x + dx
        self._default.y = self._default.y + dy

        self:updateState()
    end

end

return M
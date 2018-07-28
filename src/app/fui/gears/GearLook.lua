local GActionInterval = require("app.fui.action.GActionInterval")
local GSequence = require("app.fui.action.GSequence")

local GearLookValue = class("GearLookValue")

function GearLookValue:ctor(alpha, rotation, grayed, touchable)
    self.alpha = alpha or 0
    self.rotation = rotation or 0
    self.grayed = grayed or false
    self.touchable = touchable or false
end

local GearBase = require("app.fui.gears.GearBase")

---@class GearLook
local M = class("GearLook", GearBase)

function M:ctor(...)
    M.super.ctor(self, ...)

    self._storage = {}
    self._default = GearLookValue.new()
    self._tweenTarget = cc.p(0, 0)
end

function M:init()

    self._default = GearLookValue.new(self._owner:getAlpha(), self._owner:getRotation(),
            self._owner:isGrayed(), self._owner:isTouchable())

    self._storage = {}
end

function M:addStatus(pageId, value)
    if value == "-" or value == "" then
        return
    end

    local arr = string.split(value, ",")

    local gv = GearLookValue.new()

    gv.alpha = checknumber(arr[1]) or 0
    gv.rotation = checknumber(arr[2]) or 0
    gv.grayed = arr[3] == "1"
    gv.touchable = arr[4] == "1"

    if pageId == "" then
        self._default = gv
    else
        self._storage[pageId] = gv
    end
end

function M:apply()
    local gv
    local id = self._controller:getSelectedPageId()
    local value = self._storage[id]
    if value then
        gv = value
    else
        gv = self._default
    end

    if self.tween == true and UIPackage._constructing == 0 and disableAllTweenEffect == false then
        if self._owner:displayObject():getActionByTag(T.ActionTag.GEAR_LOOK_ACTION) ~= nil then
            if self._tweenTarget.x ~= gv.alpha or self._tweenTarget.y ~= gv.rotation then
                UIRoot:getActionManager():removeActionByTag(T.ActionTag.GEAR_LOOK_ACTION, self._owner)
                self:onTweenComplete()
            else
                return
            end
        end

        local a = gv.alpha ~= self._owner:getAlpha();
        local b = gv.rotation ~= self._owner:getRotation();

        if a or b then
            if self._owner:checkGearController("gearDisplay", self._controller) then
                self._displayLockToken = self._owner:addDisplayLock()
            end
            self._tweenTarget = cc.p(gv.alpha, gv.rotation)

            --[[
            ActionInterval* action = ActionVec2::create(tweenTime,
                Vec2(_owner->getAlpha(), _owner->getRotation()),
                _tweenTarget,
                CC_CALLBACK_1(GearLook::onTweenUpdate, this, a, b));
            action = composeActions(action, easeType, delay, CC_CALLBACK_0(GearLook::onTweenComplete, this), ActionTag::GEAR_LOOK_ACTION);
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
            action._from = { self._owner:getAlpha(), self._owner:getRotation() }
            action._to = { gv.alpha, gv.rotation }

            action:reset_delta(action)
            action.update = function(action, delta)
                local x = action._to[1] - action._delta[1] * (1 - delta)
                local y = action._to[2] - action._delta[2] * (1 - delta)
                self:onTweenUpdate(cc.p(x, y), a, b)
            end

            seq:setActions({ delayAction, action })
            seq.completeAction = function()
                self:onTweenComplete()
            end

            seq:setTag(T.ActionTag.GEAR_LOOK_ACTION)
            UIRoot:getActionManager():addAction(seq, self._owner, false)
            --]]
        end
    else
        self._owner._gearLocked = true
        self._owner:setAlpha(gv.alpha);
        self._owner:setRotation(gv.rotation);
        self._owner:setGrayed(gv.grayed);
        self._owner:setTouchable(gv.touchable);
        self._owner._gearLocked = false
    end
end

function M:onTweenUpdate(v, a, b)
    self._owner._gearLocked = true;

    if a then
        self._owner:setAlpha(v.x);
    end

    if b then
        self._owner:setRotation(v.y);
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
    self._storage[self._controller:getSelectedPageId()] = GearLookValue.new(self._owner:getAlpha(), self._owner:getRotation(),
            self._owner:isGrayed(), self._owner:isTouchable())
end

return M
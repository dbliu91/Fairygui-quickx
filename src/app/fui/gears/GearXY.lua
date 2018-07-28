local GActionInterval = require("app.fui.action.GActionInterval")
local GSequence = require("app.fui.action.GSequence")

local GearBase = require("app.fui.gears.GearBase")

---@class GearXY
local M = class("GearXY", GearBase)

function M:ctor(...)
    M.super.ctor(self,...)

    self._tweenTarget = cc.p(0, 0)
end

function M:init()
    self._default = cc.p(self._owner:getX(), self._owner:getY())
    self._storage = {}
end

function M:addStatus(pageId,value)
    if value == "-" or value=="" then
        return
    end

    local v2 = string.split(value,",")
    local x = checkint(v2[1])
    local y = checkint(v2[2])

    if pageId == "" then
        self._default = cc.p(x,y)
    else
        self._storage[pageId] = cc.p(x,y)
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
        if self._owner:displayObject():getActionByTag(T.ActionTag.GEAR_XY_ACTION) ~= nil then
            if self._tweenTarget.x ~= gv.x or self._tweenTarget.y ~= gv.y then
                --self._owner:displayObject():stopActionByTag(T.ActionTag.GEAR_XY_ACTION)
                UIRoot:getActionManager():removeActionByTag(T.ActionTag.GEAR_XY_ACTION, self._owner)
                self:onTweenComplete()
            else
                return
            end
        end

        if self._owner:getX() ~= gv.x or self._owner:getY() ~= gv.y then
            if self._owner:checkGearController("gearDisplay",self._controller) then
                self._displayLockToken = self._owner:addDisplayLock()
            end
            self._tweenTarget = gv

            --[[
            ActionInterval* action = ActionVec2::create(tweenTime,
                 _owner->getPosition(),
                 gv,
                 CC_CALLBACK_1(GearXY::onTweenUpdate, this));
             action = composeActions(action, easeType, delay, CC_CALLBACK_0(GearXY::onTweenComplete, this), ActionTag::GEAR_XY_ACTION);
             _owner->displayObject()->runAction(action);
            --]]
            ---[[

            local seq = GSequence.new()

            local delayAction = GActionInterval.new()
            delayAction:setDuration(self.delay)
            delayAction.update = function() end

            local action = GActionInterval.new()
            action:setDuration(self.tweenTime)
            action._from = { self._owner:getX(), self._owner:getY() }
            action._to = { gv.x, gv.y }

            action:reset_delta(action)
            action.update = function(action, delta)
                local x = action._to[1] - action._delta[1] * (1 - delta)
                local y = action._to[2] - action._delta[2] * (1 - delta)
                self:onTweenUpdate(cc.p(x,y))
            end


            seq:setActions({delayAction,action})
            seq.completeAction = function()
                self:onTweenComplete()
            end

            seq:setTag(T.ActionTag.GEAR_XY_ACTION)
            UIRoot:getActionManager():addAction(seq, self._owner, false)
            --]]
        end
    else
        self._owner._gearLocked = true
        self._owner:setPosition(gv.x,gv.y)
        self._owner._gearLocked = false
    end
end

function M:onTweenUpdate(v)
    self._owner._gearLocked = true;
    self._owner:setPosition(v.x, v.y);
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
    self._storage[self._controller:getSelectedPageId()] = cc.p(self._owner:getX(),self._owner:getY())
end

function M:updateFromRelations(dx,dy)
    if self._controller ~= nil and #self._storage~=0 then

        for i, v in ipairs(self._storage) do
            v = cc.p(v.x+dx,v.y+dy)
        end

        self._default.x = self._default.x + dx
        self._default.y = self._default.y + dy

        self:updateState()
    end
end

return M
local GearBase = require("app.fui.gears.GearBase")

---@class GearColor
local M = class("GearColor",GearBase)

function M:ctor(...)
    M.super.ctor(self,...)

    self._storage = {}
    self._default = {
        color =  cc.c4f(1,1,1,1);
        outlineColor = cc.c4f(1,1,1,1);
    }
    self._tweenTarget = cc.c4f(1,1,1,1)
end

function M:init()

    if self._owner.cg_getColor then
        self._default.color = clone(self._owner:cg_getColor())
    end

    if self._owner.cg_getOutlineColor then
        self._default.outlineColor = clone(self._owner:cg_getOutlineColor())
    end

    self._storage = {}
end

function M:addStatus(pageId,value)
    if (not value or value == "-" or value == "") then
        return;
    end

    local arr = string.split(value,",")

    local gv = {}
    gv.color = ToolSet.convertFromHtmlColor(arr[1])

    if #arr==1  then
        gv.outlineColor = cc.c4b(0,0,0,0)
    else
        gv.outlineColor = ToolSet.convertFromHtmlColor(arr[2])
    end

    if not pageId or pageId=="" then
        self._default = gv
    else
        self._storage[pageId] = gv
    end

end

function M:apply()

    local v =  self._storage[self._controller:getSelectedPageId()]
    if not v then
        v = self._default
    end

    if (self.tween==true and UIPackage._constructing == 0 and disableAllTweenEffect==false) then
        --[[
            if (gv.outlineColor.a > 0)
            {
                _owner->_gearLocked = true;
                cg->cg_setOutlineColor(gv.outlineColor);
                _owner->_gearLocked = false;
            }

            if (_owner->displayObject()->getActionByTag(ActionTag::GEAR_COLOR_ACTION) != nullptr)
            {
                if (_tweenTarget.x != gv.color.r || _tweenTarget.y != gv.color.g || _tweenTarget.z != gv.color.b)
                {
                    _owner->displayObject()->stopActionByTag(ActionTag::GEAR_COLOR_ACTION);
                    onTweenComplete();
                }
                else
                    return;
            }

            if (gv.color != cg->cg_getColor())
            {
                if (_owner->checkGearController(0, _controller))
                    _displayLockToken = _owner->addDisplayLock();
                _tweenTarget.set(gv.color.r, gv.color.g, gv.color.b, gv.color.a);
                const Color4B& curColor = cg->cg_getColor();

                ActionInterval* action = ActionVec4::create(tweenTime,
                    Vec4(curColor.r, curColor.g, curColor.b, curColor.a),
                    _tweenTarget,
                    CC_CALLBACK_1(GearColor::onTweenUpdate, this));
                action = composeActions(action, easeType, delay, CC_CALLBACK_0(GearColor::onTweenComplete, this), ActionTag::GEAR_COLOR_ACTION);
                _owner->displayObject()->runAction(action);
            }
        --]]
    else
        self._owner._gearLocked = true
        if self._owner.cg_setColor then
            self._owner:cg_setColor(v.color);
        end
        if (v.outlineColor.a > 0 and self._owner.cg_setOutlineColor) then
            self._owner:cg_setOutlineColor(v.outlineColor);
        end
        self._owner._gearLocked = false
    end

end

--[[
void GearColor::onTweenUpdate(const Vec4& v)
{
    IColorGear *cg = dynamic_cast<IColorGear*>(_owner);

    _owner->_gearLocked = true;
    cg->cg_setColor(Color4B(v.x, v.y, v.z, v.w));
    _owner->_gearLocked = false;
}

void GearColor::onTweenComplete()
{
    if (_displayLockToken != 0)
    {
        _owner->releaseDisplayLock(_displayLockToken);
        _displayLockToken = 0;
    }
    _owner->dispatchEvent(UIEventType::GearStop);
}
--]]

function M:updateState()
    local gv = {}
    if self._owner.cg_getColor then
        gv.color = clone(self._owner:cg_getColor())
    end

    if self._owner.cg_getOutlineColor then
        gv.outlineColor = clone(self._owner:cg_getOutlineColor())
    end

    self._storage[self._controller:getSelectedPageId()] = gv

end

return M
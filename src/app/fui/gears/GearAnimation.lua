local GearBase = require("app.fui.gears.GearBase")

---@class GearAnimation
local M = class("GearAnimation",GearBase)

--[[

GearAnimation::GearAnimationValue::GearAnimationValue() :frame(0), playing(false)
{

}

GearAnimation::GearAnimationValue::GearAnimationValue(bool playing, int frame)
{
    this->playing = playing;
    this->frame = frame;
}

GearAnimation::GearAnimation(GObject * owner) :GearBase(owner)
{

}

GearAnimation::~GearAnimation()
{
}

void GearAnimation::init()
{
    IAnimationGear *ag = dynamic_cast<IAnimationGear*>(_owner);

    _default = GearAnimationValue(ag->isPlaying(), ag->getCurrentFrame());
    _storage.clear();
}

void GearAnimation::addStatus(const std::string&  pageId, const std::string& value)
{
    if (value == "-" || value.length() == 0)
        return;

    std::vector<std::string> arr;
    ToolSet::splitString(value, ',', arr);

    GearAnimationValue gv;
    gv.frame = Value(arr[0]).asInt();
    gv.playing = arr[1] == "p";
    if (pageId.size() == 0)
        _default = gv;
    else
        _storage[pageId] = gv;
}

void GearAnimation::apply()
{
    _owner->_gearLocked = true;

    GearAnimationValue gv;
    auto it = _storage.find(_controller->getSelectedPageId());
    if (it != _storage.end())
        gv = it->second;
    else
        gv = _default;

    IAnimationGear *ag = dynamic_cast<IAnimationGear*>(_owner);

    ag->setPlaying(gv.playing);
    ag->setCurrentFrame(gv.frame);

    _owner->_gearLocked = false;
}

void GearAnimation::updateState()
{
    IAnimationGear *ag = dynamic_cast<IAnimationGear*>(_owner);

    _storage[_controller->getSelectedPageId()] = GearAnimationValue(ag->isPlaying(), ag->getCurrentFrame());
}
--]]

return M
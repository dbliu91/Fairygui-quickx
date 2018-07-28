local M = class("PixelHitTest")

local bit_blshift = bit.lshift or bit.blshift
local bit_band = bit.band
local bit_brshift = bit.rshift or bit.brshift

function M:ctor(data,offsetX,offsetY)
    self.offsetX = offsetX
    self.offsetY = offsetY
    self.scaleX = 1
    self.scaleY = 1
    self._data = data
end

---@param obj GObject
function M:hitTest(obj,localPoint)
    local x = math.floor((localPoint.x / self.scaleX - self.offsetX) * self._data.scale);
    local y = math.floor(((obj:getHeight() - localPoint.y) / self.scaleY - self.offsetY) * self._data.scale);
    if (x < 0 or y < 0 or x >= self._data.pixelWidth) then
        return false;
    end

    local pos = y * self._data.pixelWidth + x;
    local pos2 = checkint(pos / 8);
    local pos3 = pos % 8;

    if (pos2 >= 0 and pos2 < self._data.pixelsLength) then
        local v = bit_brshift(self._data.pixels[pos2], pos3)
        v = bit_band(v,0x1)
        return v > 0;
    else
        return false;
    end
end

return M
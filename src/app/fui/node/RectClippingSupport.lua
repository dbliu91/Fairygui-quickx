local M = class("RectClippingSupport")

function M:ctor()
    self._clippingEnabled = false
    self._scissorOldState = false
    self._clippingRectDirty = false
end

return M
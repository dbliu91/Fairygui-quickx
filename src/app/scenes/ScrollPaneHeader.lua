local GComponent = require("app.fui.GComponent")

local M = class("ScrollPaneHeader", GComponent)

function M:isReadyToRefresh()
    return self._c1:getSelectedIndex() == 2;
end

function M:setRefreshStatus(value)
    self._c1:setSelectedIndex(value)
end

function M:constructFromXML(xml)
    GComponent.constructFromXML(self, xml)
    self._c1 = self:getController("c1")
    self:addEventListener(T.UIEventType.SizeChange, handler(self, self.onSizeChanged))
end

function M:onSizeChanged(context)
    if (self._c1:getSelectedIndex() == 3 or self._c1:getSelectedIndex() == 4) then
        return ;
    end

    if (self:getHeight() > self.sourceSize.height) then
        self._c1:setSelectedIndex(2);
    else
        self._c1:setSelectedIndex(1);
    end
end

return M
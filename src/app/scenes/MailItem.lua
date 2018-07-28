local GButton = require("app.fui.GButton")

local M = class("MainItem",GButton)

function M:constructFromXML(xml)
    M.super.constructFromXML(self,xml)

    self._timeText = self:getChild("timeText");
    self._readController = self:getController("IsRead");
    self._fetchController = self:getController("c1");
    self._trans = self:getTransition("t0");
end

function M:setTime(value)
    self._timeText:setText(value);
end


function M:setRead(value)
    self._readController:setSelectedIndex(value==true and 2 or 1);
end


function M:setFetched(value)
    self._fetchController:setSelectedIndex(value==true and 2 or 1);
end


function M:setTime(value)
    self._timeText:setText(value);
end

function M:playEffect(delay)
    self:setVisible(false);
    self._trans:play(1, delay, nil);
end


return M
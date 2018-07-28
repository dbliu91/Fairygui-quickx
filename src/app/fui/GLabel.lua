local GComponent = require("app.fui.GComponent")

---@class GLabel:GComponent
local M = class("GLabel", GComponent)

function M:ctor(...)
    M.super.ctor(self,...)

    self._titleObject = nil
    self._iconObject = nil
    self._title = ""
    self._icon = ""
end

function M:getTitle()
    return self._title
end

function M:setTitle(value)
    self._title = value;
    if (self._titleObject) then
        self._titleObject:setText(self._title);
    end
    self:updateGear("gearText");
end

function M:getText()
    return self._title
end

function M:setText(value)
    self:setTitle(value)
end

function M:getIcon()
    return self._icon
end

function M:setIcon(value)
    self._icon = value;
    if (self._iconObject) then
        self._iconObject:setIcon(self._icon);
    end
    self:updateGear("gearIcon");
end

function M:getTitleColor()
    if iskindof(self._titleObject, "GTextField") then
        return self._titleObject:getColor()
    elseif iskindof(self._titleObject, "GLabel") then
        return self._titleObject:getTitleColor()
    elseif iskindof(self._titleObject, "GButton") then
        return self._titleObject:getTitleColor()
    else
        return cc.c3b(0, 0, 0)
    end
end

function M:setTitleColor(c3b_value)
    if iskindof(self._titleObject, "GTextField") then
        self._titleObject:setColor(c3b_value)
    elseif iskindof(self._titleObject, "GLabel") then
        self._titleObject:setTitleColor(c3b_value)
    elseif iskindof(self._titleObject, "GButton") then
        self._titleObject:setTitleColor(c3b_value)
    end
end

function M:getTitleFontSize()
    if iskindof(self._titleObject, "GTextField") then
        return self._titleObject:getFontSize()
    elseif iskindof(self._titleObject, "GLabel") then
        return self._titleObject:getTitleFontSize()
    elseif iskindof(self._titleObject, "GButton") then
        return self._titleObject:getTitleFontSize()
    else
        return 0
    end
end

function M:setTitleFontSize(c3b_value)
    if iskindof(self._titleObject, "GTextField") then
        self._titleObject:setFontSize(c3b_value)
    elseif iskindof(self._titleObject, "GLabel") then
        self._titleObject:setTitleFontSize(c3b_value)
    elseif iskindof(self._titleObject, "GButton") then
        self._titleObject:setTitleFontSize(c3b_value)
    end
end

function M:constructFromXML(xml)
    M.super.constructFromXML(self, xml)

    self._titleObject = self:getChild("title");
    self._iconObject = self:getChild("icon");
    if (self._titleObject) then
        self._title = self._titleObject:getText();
    end
    if (self._iconObject) then
        self._icon = self._iconObject:getIcon();
    end
end

function M:setup_AfterAdd(xml)
    M.super.setup_AfterAdd(self, xml)

    xml = xml.Label

    if not xml then
        return
    end

    local p

    p = xml["@title"]
    if p then
        self:setTitle(p)
    end

    p = xml["@icon"]
    if p then
        self:setIcon(p)
    end

    p = xml["@titleColor"]
    if p then
        local c = ToolSet.convertFromHtmlColor(p)
        self:setTitleColor(c)
    end

    p = xml["@titleFontSize"]
    if p then
        self:setTitleFontSize(checkint(p))
    end


    --[[
    GTextInput* input = dynamic_cast<GTextInput*>(_titleObject);
    if (input)
    {
        p = xml->Attribute("prompt");
        if (p)
            input->setPrompt(p);

        if (xml->BoolAttribute("password"))
            input->setPassword(true);

        p = xml->Attribute("restrict");
        if (p)
            input->setRestrict(p);

        p = xml->Attribute("maxLength");
        if (p)
            input->setMaxLength(atoi(p));

        p = xml->Attribute("keyboardType");
        if (p)
            input->setKeyboardType(atoi(p));
    }
    --]]

end

return M
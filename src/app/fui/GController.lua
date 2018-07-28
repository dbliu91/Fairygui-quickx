local UIEventDispatcher = require("app.fui.event.UIEventDispatcher")

---@class GController:UIEventDispatcher
---@field private _parent GComponent
---@field private _selectedIndex number
---@field private _previousIndex number
---@field private _parent GComponent
---@field public name string
---@field public changing boolean
---@field public autoRadioGroupDepth boolean
---@field public _actions [ControllerAction]
local M = class("GController",UIEventDispatcher)

function M:ctor()
    M.super.ctor(self)
    self._pageIds = {}
    self._pageNames = {}
    self._actions = {}

    self._selectedIndex = -1
    self._previousIndex = -1

    self.name = ""
    self.changing = false
    self.autoRadioGroupDepth = false
end

function M:getParent()
    return self._parent
end

function M:setParent(value)
    self._parent = value
end

function M:getSelectedIndex()
    return self._selectedIndex
end

function M:setSelectedIndex(value)
    if self._selectedIndex ~= value then
        if value > #self._pageIds or value<1 then
            print("Invalid selected index")
            return
        end

        self.changing = true

        self._previousIndex = self._selectedIndex
        self._selectedIndex = value
        self._parent:applyController(self)

        self:dispatchEvent(T.UIEventType.Changed)

        self.changing = false
    end
end

function M:getSelectedPage()
    if self._selectedIndex == -1 then
        return ""
    else
        return self._pageNames[self._selectedIndex]
    end
end

---@param value string
function M:setSelectedPage(value)
    local i = table.indexof(self._pageNames, value)
    if i == false then
        i = 1
    end
    self:setSelectedIndex(i)
end

function M:getSelectedPageId()
    if self._selectedIndex == -1 then
        return ""
    else
        return self._pageIds[self._selectedIndex]
    end
end

function M:setSelectedPageId(value)
    local i = table.indexof(self._pageIds, value)
    if i == false then
        i = 1
    end
    self:setSelectedIndex(i)
end

function M:getPrevisousIndex()
    return self._previousIndex
end

function M:getPreviousPage()
    if self._selectedIndex == -1 then
        return ""
    else
        return self._pageNames[self._previousIndex]
    end
end

function M:getPreviousPageId()
    if self._selectedIndex == -1 then
        return ""
    else
        return self._pageIds[self._previousIndex]
    end
end

function M:getPageCount()
    return #self._pageIds
end

function M:hasPage(aName)
    return table.indexof(self._pageNames, aName) ~= false
end

function M:getPageIndexById(value)
    return table.indexof(self._pageIds, value)
end

function M:getPageNameById(value)
    local i = table.indexof(self._pageIds, value)
    if i ~= false then
        return self._pageNames[i]
    else
        return ""
    end
end

function M:getPageId(index)
    return self._pageIds[index]
end

function M:setOppositePageId(value)
    local i = table.indexof(self._pageIds, value)
    if i >1 then
        self:setSelectedIndex(1)
    elseif #self._pageIds>1 then
        self:setSelectedIndex(2)
    end
end

function M:runActions()
    if #self._actions == 0 then
        return
    end

    for i, v in ipairs(self._actions) do
        v:run(self, self:getPreviousPageId(), self:getSelectedPageId())
    end
end

function M:setup(xml)

    local p = xml["@name"]
    if p then
        self.name = p
    end

    self.autoRadioGroupDepth = (xml["@autoRadioGroupDepth"] == "true")

    local p = xml["@pages"]
    if p then
        local elems = string.split(p, ",")
        local cnt = #elems
        for i = 1, cnt, 2 do
            table.insert(self._pageIds, elems[i])
            table.insert(self._pageNames, elems[i + 1])
        end
    end

    --TODO
    --[[

    TXMLElement* cxml = xml->FirstChildElement("action");
    while (cxml)
    {
        ControllerAction* action = ControllerAction::createAction(cxml->Attribute("type"));
        action->setup(cxml);
        _actions.push_back(action);

        cxml = cxml->NextSiblingElement("action");
    }

    --]]

    if (self._parent and #self._pageIds > 0) then
        self._selectedIndex = 1;
    else
        self._selectedIndex = -1;
    end

end

return M
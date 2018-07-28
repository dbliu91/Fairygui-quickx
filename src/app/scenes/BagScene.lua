local DemoScene = require("app.scenes.DemoScene")
local BagWindow = require("app.scenes.BagWindow")

local M = class("BagScene", DemoScene)

function M:ctor(...)
    --self._list = nil
    --self._view = nil
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/Bag");
    UIConfig.horizontalScrollBar = "";
    UIConfig.verticalScrollBar = "";

    self._view = UIPackage.createObject("Bag", "Main");
    self._groot:addChild(self._view);

    self._view.name = "BagMain"

    self._bagWindow = BagWindow.new();
    self._bagWindow:init()

    self._view:getChild("bagBtn"):addClickListener(function()
        self._bagWindow:show()

        local kv_map = ToolSet.log_node_tree(self._groot,function (before, node)
            --print(before, node.name, node.id,node:getX(),node:getY(),node:getWidth(),node:getHeight())
        end)

        for i, v in ipairs(kv_map["##"]) do
            print(v.name)
        end

    end);
end

return M
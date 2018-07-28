local DemoScene = require("app.scenes.DemoScene")
local TreeView = require("app.fui.treeview.TreeView")
local TreeNode = require("app.fui.treeview.TreeNode")

local M = class("TreeViewScene", DemoScene)

function M:ctor(...)
    self._list = nil
    self._view = nil
    M.super.ctor(self, ...)
end

function M:continueInit()
    UIPackage.addPackage("UI/TreeView");
    UIConfig.horizontalScrollBar = "";
    UIConfig.verticalScrollBar = "";

    self._view = UIPackage.createObject("TreeView", "Main");
    self._groot:addChild(self._view);

    self._treeView = TreeView.new()
    self._treeView:init(self._view:getChild("tree"));

    self._treeView:addEventListener(T.UIEventType.ClickItem, handler(self, self.onClickNode))
    self._treeView.treeNodeRender = handler(self, self.renderTreeNode)

    local topNode = TreeNode.new(true);
    topNode:setData("I'm a top node")
    self._treeView:getRootNode():addChild(topNode)

    for i = 1, 5 do
        local node = TreeNode.new();
        node:setData("Hello " .. i)
        topNode:addChild(node)
    end

    local aFolderNode = TreeNode.new(true);
    aFolderNode:setData("A folder node")
    topNode:addChild(aFolderNode)

    for i = 1, 5 do
        local node = TreeNode.new();
        node:setData("Good " .. i)
        aFolderNode:addChild(node)
    end

    for i = 1, 3 do
        local node = TreeNode.new();
        node:setData("World " .. i)
        topNode:addChild(node)
    end

    local anotherTopNode = TreeNode.new()
    anotherTopNode:setData({
        "I'm a top node too",
        "ui://TreeView/heart"
    })

    self._treeView:getRootNode():addChild(anotherTopNode)
end

function M:onClickNode(context)
    local node = context:getData()
    if node:isFolder() and context:getInput():isDoubleClick() then
        node:setExpaned(not node:isExpanded())
    end
end

function M:renderTreeNode(node)
    local btn = node:getCell()
    if node:isFolder() then
        if node:isExpanded() then
            btn:setIcon("ui://TreeView/folder_opened");
        else
            btn:setIcon("ui://TreeView/folder_closed");
        end

        btn:setText(node:getData())
    elseif type(node:getData()) == "table" then
        local t = node:getData()
        btn:setIcon(t[2])
        btn:setText(t[1])
    else
        btn:setIcon("ui://TreeView/file")
        btn:setText(node:getData())
    end
end

return M
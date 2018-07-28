local DemoScene = require("app.scenes.DemoScene")

local M = class("MenuScene", DemoScene)

function M:continueInit()
    local v = UIPackage.createObject("MainMenu", "Main")
    self._groot:addChild(v)

    v:getChild("n1"):addClickListener(function(context)
        local BasicsScene = require("app.scenes.BasicsScene")
        local scene = BasicsScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n2"):addClickListener(function(context)
        local TransitionDemoScene = require("app.scenes.TransitionDemoScene")
        local scene = TransitionDemoScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n4"):addClickListener(function(context)
        local VirtualListScene = require("app.scenes.VirtualListScene")
        local scene = VirtualListScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n5"):addClickListener(function(context)
        local LoopListScene = require("app.scenes.LoopListScene")
        local scene = LoopListScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n6"):addClickListener(function(context)
        local HitTestScene = require("app.scenes.HitTestScene")
        local scene = HitTestScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n7"):addClickListener(function(context)
        local PullToRefreshScene = require("app.scenes.PullToRefreshScene")
        local scene = PullToRefreshScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n8"):addClickListener(function(context)
        local ModalWaitingScene = require("app.scenes.ModalWaitingScene")
        local scene = ModalWaitingScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n9"):addClickListener(function(context)
        local JoystickScene = require("app.scenes.JoystickScene")
        local scene = JoystickScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n10"):addClickListener(function(context)
        local BagScene = require("app.scenes.BagScene")
        local scene = BagScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n11"):addClickListener(function(context)
        local ChatScene = require("app.scenes.ChatScene")
        local scene = ChatScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n12"):addClickListener(function(context)
        local ListEffectScene = require("app.scenes.ListEffectScene")
        local scene = ListEffectScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n13"):addClickListener(function(context)
        local ScrollPaneScene = require("app.scenes.ScrollPaneScene")
        local scene = ScrollPaneScene.new()
        display.replaceScene(scene, "fade")
    end)

    v:getChild("n14"):addClickListener(function(context)
        local TreeViewScene = require("app.scenes.TreeViewScene")
        local scene = TreeViewScene.new()
        display.replaceScene(scene, "fade")
    end)

    --ToolSet.addDebugButton(self)

end

return M
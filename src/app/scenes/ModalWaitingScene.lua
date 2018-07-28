local DemoScene = require("app.scenes.DemoScene")
local Window = require("app.fui.GWindow")

local M = class("ModalWaitingScene", DemoScene)

function M:onCleanup()
    if self._testWin then
        self._testWin:doDestory()
    end
end

function M:continueInit()
    UIPackage.addPackage("UI/ModalWaiting");
    UIConfig.globalModalWaiting = "ui://ModalWaiting/GlobalModalWaiting";
    UIConfig.windowModalWaiting = "ui://ModalWaiting/WindowModalWaiting";

    self._view = UIPackage.createObject("ModalWaiting", "Main");
    self._groot:addChild(self._view);

    self._testWin = Window.new()
    self._testWin:init()

    self._testWin:setContentPane(UIPackage.createObject("ModalWaiting", "TestWin"))
    self._testWin:getContentPane():getChild("n1"):addClickListener(function(context)
        self._testWin:showModalWait()

        ---simulate a asynchronous request
        local q = self._groot:getCoroutine()
        q:PlayRoutine(function()
            q:WaitTime(3)
            self._testWin:closeModalWait()
        end)
    end)

    self._view:getChild("n0"):addClickListener(function(context)
        self._testWin:show()
    end)

    self._groot:showModalWait()

    ---simulate a asynchronous request
    performWithDelay(self,function ()
        self._groot:closeModalWait()
    end,3)
end

return M
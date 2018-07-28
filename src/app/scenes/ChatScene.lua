local DemoScene = require("app.scenes.DemoScene")

local M = class("ChatScene",DemoScene)

function M:ctor(...)
    M.super.ctor(self,...)
    self._messages = {}
end

function M:onCleanup()
    if self._emojiSelectUI then
        self._emojiSelectUI:doDestory()
    end
end

function M:continueInit()
    UIPackage.addPackage("UI/Emoji");
    UIConfig.verticalScrollBar = "";

    self._view = UIPackage.createObject("Emoji", "Main");
    self._groot:addChild(self._view);

    self._list = self._view:getChild("list");
    self._list:setVirtual();
    self._list.itemProvider = handler(self,self.getListItemResource)
    self._list.itemRenderer = handler(self,self.renderListItem)

    self._input = self._view:getChild("input");
    self._input:addEventListener(T.UIEventType.Submit, handler(self,self.onSubmit));

    self._view:getChild("btnSend"):addClickListener(handler(self,self.onClickSendBtn))
    self._view:getChild("btnEmoji"):addClickListener(handler(self,self.onClickEmojiBtn))

    self._emojiSelectUI = UIPackage.createObject("Emoji", "EmojiSelectUI");
    self._emojiSelectUI:getChild("list"):addEventListener(T.UIEventType.ClickItem, handler(self,self.onClickEmoji));
end

function M:onClickSendBtn(context)
    local msg = self._input:getText()
    if not msg or msg=="" then
        return
    end

    self:addMsg("Unity", "r0", msg, true)
    self._input:setText("")

end

function M:onClickEmojiBtn(context)
    self._groot:showPopup(self._emojiSelectUI,context:getSender(),T.PopupDirection.UP)
end

function M:onClickEmoji(context)
    local item = context:getData()
    self._input:setText(self._input:getText().."["..item:getText().."]")
end

function M:onSubmit(context)
    self:onClickSendBtn(context)
end

function M:renderListItem(index,obj)
    local item = obj
    local msg = self._messages[index]

    if not msg.fromMe then
        item:getChild("name"):setText(msg.sender)
    end

    item:setIcon("ui://Emoji/" .. msg.senderIcon)

    local tf = item:getChild("msg")
    tf:setText("");
    tf:setWidth(tf.initSize.width);
    --tf:setText(EmojiParser.getInstance():parse(msg.msg));
    tf:setWidth(tf:getTextSize().width);

end

function M:getListItemResource(index)
    local msg = self._messages[index]
    if msg.fromMe==true then
        return "ui://Emoji/chatRight";
    else
        return "ui://Emoji/chatLeft";
    end
end

function M:addMsg(sender,senderIcon,msg,fromMe)
    local isScrollBottom = self._list:getScrollPane():isBottomMost()

    local newMessage = {}
    newMessage.sender = sender;
    newMessage.senderIcon = senderIcon;
    newMessage.msg = msg;
    newMessage.fromMe = fromMe;

    table.insert(self._messages,newMessage)

    if newMessage.fromMe==true then
        if #self._messages==1 or math.random()<0.5 then
            local replyMessage = {}

            replyMessage.sender = "FairyGUI";
            replyMessage.senderIcon = "r1";
            replyMessage.msg = "Today is a good day. [:cool]";
            replyMessage.fromMe = false;

            table.insert(self._messages,replyMessage)
        end
    end

    if #self._messages>100 then
        for i = 1, #self._messages - 100 do
            table.remove(self._messages,1)
        end
    end

    self._list:setNumItems(#self._messages);

    if isScrollBottom then
        self._list:getScrollPane():scrollBottom(true)
    end
end

return M
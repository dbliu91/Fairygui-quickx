---Helper for drag and drop.
---这是一个提供特殊拖放功能的功能类。与GObject.draggable不同，拖动开始后，他使用一个替代的图标作为拖动对象。
---当玩家释放鼠标/手指，目标组件会发出一个onDrop事件。
---@class DragDropManager
local M = class("DragDropManager")

local __inst

M.getInstance = function()
    if __inst == nil then
        __inst = M.new()
    end

    return __inst
end

function M:ctor()
    self._sourceData = nil

    self._agent = UIObjectFactory.newObject("loader")

    self._agent.name = "DragDropManager_agent"

    self._agent:setTouchable(false);
    self._agent:setDraggable(true);
    self._agent:setSize(100, 100);
    self._agent:setPivot(0.5, 0.5, true);
    self._agent:setAlign(T.TextHAlignment.CENTER);
    self._agent:setVerticalAlign(T.TextVAlignment.CENTER);
    self._agent:setSortingOrder(INT_MAX);

    self._agent:addEventListener(T.UIEventType.DragEnd, handler(self,self.onDragEnd), self);

end

function M:doDestory()
    G_doDestory(self._agent)
end

---Loader object for real dragging.
---用于实际拖动的Loader对象。你可以根据实际情况设置loader的大小，对齐等。
---@return GLoader
function M:getAgent()
    return self._agent
end

---Is dragging?
---返回当前是否正在拖动。
function M:isDragging()
    return self._agent:getParent()~=nil
end

---Start dragging.
---开始拖动。
---@param icon string @Icon to be used as the dragging sign.
---@param sourceData everything @Custom data. You can get it in the onDrop event data.
---@param touchPointID int @Copy the touchId from InputEvent to here, if has one.
function M:startDrag(icon,sourceData,touchPointID)
    if self._agent:getParent() ~= nil then
        return
    end

    self._sourceData = sourceData;
    self._agent:setURL(icon);
    UIRoot:addChild(self._agent);
    local pt = UIRoot:globalToLocal(UIRoot:getTouchPosition(touchPointID));
    self._agent:setPosition(pt.x, pt.y);
    self._agent:startDrag(touchPointID);

end

---Cancel dragging.
---取消拖动。
function M:cancel()
    if self._agent:getParent() ~= nil then
        self._agent:stopDrag();
        UIRoot:removeChild(self._agent);
        self._sourceData = nil;
    end
end

function M:onDragEnd(context)
    if self._agent:getParent() == nil then--cancelled
        return
    end

    UIRoot:removeChild(self._agent);

    local obj = UIRoot:getTouchTarget();
    while (obj~=nil) do
        if iskindof(obj,"GComponent")==true then
            if obj:hasEventListener(T.UIEventType.Drop) then
                --obj->requestFocus();
                obj:dispatchEvent(T.UIEventType.Drop, nil, self._sourceData);
                return
            end
        end
        obj = obj:getParent()
    end
end


return M
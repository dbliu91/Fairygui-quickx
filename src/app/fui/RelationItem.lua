---@class RelationDef
---@field percent boolean
---@field type RelationType
---@field axis number

-----------------------------------------------------------------------------

---@class RelationItem
---@field RelationDef [RelationDef]
local M = class("RelationItem")

---@param owner GObject
function M:ctor(owner)
    self._target = nil
    self._owner = owner

    self._defs = {}
    self._targetData = {}
end

function M:getTarget()
    return self._target
end

function M:setTarget(value)

    local old = self._target

    if old ~= value then
        if old then
            self:releaseRefTarget(old)
        end
        self._target = value
        if value then
            self:addRefTarget(value)
        end
    end
end

---@param relationType RelationType
---@param usePercent boolean
function M:add(relationType, usePercent)
    if relationType == T.RelationType.Size then
        self:add(T.RelationType.Width, usePercent)
        self:add(T.RelationType.Height, usePercent)
        return
    end

    for i, v in ipairs(self._defs) do
        if v.type == relationType then
            return
        end
    end

    self:internalAdd(relationType, usePercent)
end

---@param relationType RelationType
---@param usePercent boolean
function M:internalAdd(relationType, usePercent)
    if relationType == T.RelationType.Size then
        self:internalAdd(T.RelationType.Width, usePercent)
        self:internalAdd(T.RelationType.Height, usePercent)
        return
    end

    ---@type RelationType
    local info = {}
    info.percent = usePercent
    info.type = relationType
    info.axis = (relationType <= T.RelationType.Right_Right or relationType == T.RelationType.Width or relationType >= T.RelationType.LeftExt_Left and relationType <= T.RelationType.RightExt_Right) and 0 or 1;
    table.insert(self._defs, info)

    if usePercent == true
            or relationType == T.RelationType.Left_Center
            or relationType == T.RelationType.Center_Center
            or relationType == T.RelationType.Right_Center
            or relationType == T.RelationType.Top_Middle
            or relationType == T.RelationType.Middle_Middle
            or relationType == T.RelationType.Bottom_Middle
    then
        self._owner:setPixelSnapping(true)
    end

end

---@param relationType RelationType
function M:remove(relationType)
    if relationType == T.RelationType.Size then
        self:remove(T.RelationType.Width)
        self:remove(T.RelationType.Height)
        return
    end

    for i = #self._defs, 1, -1 do
        local v = self._defs[i]
        if v.type == relationType then
            table.remove(self._defs, i)
            break
        end
    end
end

function M:copyFrom(source)
    self:setTarget(source._target)
    self._defs = {}
    for i, v in ipairs(source._defs) do
        table.insert(self._defs, clone(v))
    end
end

function M:isEmpty()
    return #self._defs == 0
end

function M:applyOnSelfSizeChanged(dWidth, dHeight, applyPivot)

    if self._target == nil or #self._defs == 0 then
        return
    end

    local ox = self._owner._position.x
    local oy = self._owner._position.y

    for i, v in ipairs(self._defs) do
        if v.type == T.RelationType.Center_Center then
            self._owner:setX(self._owner._position.x - (0.5 - (applyPivot and self._owner._pivot.x or 0)) * dWidth);
        elseif v.type == T.RelationType.Right_Center or v.type == T.RelationType.Right_Left or v.type == T.RelationType.Right_Right then
            self._owner:setX(self._owner._position.x - (1 - (applyPivot and self._owner._pivot.x or 0)) * dWidth);
        elseif v.type == T.RelationType.Middle_Middle then
            self._owner:setY(self._owner._position.y - (0.5 - (applyPivot and self._owner._pivot.y or 0)) * dHeight);
        elseif v.type == T.RelationType.Bottom_Middle or v.type == T.RelationType.Bottom_Top or v.type == T.RelationType.Bottom_Bottom then
            self._owner:setY(self._owner._position.y - (1 - (applyPivot and self._owner._pivot.y or 0)) * dHeight);
        end
    end

    if ox ~= self._owner._position.x or oy ~= self._owner._position.y then
        ox = self._owner._position.x - ox;
        oy = self._owner._position.y - oy;

        self._owner:updateGearFromRelations("gearXY", ox, oy)

        if self._owner._parent then
            local arr = self._owner._parent:getTransitions()
            for i, v in ipairs(arr) do
                v:updateFromRelations(self._owner.id, ox, oy)
            end
        end

    end

end

---@param target GObject
---@param info RelationDef
function M:applyOnXYChanged(target, info, dx, dy)

    local tmp

    if info.type == T.RelationType.Left_Left
            or info.type == T.RelationType.Left_Center
            or info.type == T.RelationType.Left_Right
            or info.type == T.RelationType.Center_Center
            or info.type == T.RelationType.Right_Left
            or info.type == T.RelationType.Right_Center
            or info.type == T.RelationType.Right_Right then
        self._owner:setX(self._owner._position.x + dx)
    elseif info.type == T.RelationType.Top_Top
            or info.type == T.RelationType.Top_Middle
            or info.type == T.RelationType.Top_Bottom
            or info.type == T.RelationType.Middle_Middle
            or info.type == T.RelationType.Bottom_Top
            or info.type == T.RelationType.Bottom_Middle
            or info.type == T.RelationType.Bottom_Bottom then
        self._owner:setY(self._owner._position.y + dy)
    elseif info.type == T.RelationType.LeftExt_Left
            or info.type == T.RelationType.LeftExt_Right then
        tmp = self._owner:getXMin();
        self._owner:setWidth(self._owner._rawSize.width - dx);
        self._owner:setXMin(tmp + dx);
    elseif info.type == T.RelationType.RightExt_Left
            or info.type == T.RelationType.RightExt_Right then
        tmp = self._owner:getXMin();
        self._owner:setWidth(self._owner._rawSize.width + dx);
        self._owner:setXMin(tmp);
    elseif info.type == T.RelationType.TopExt_Top
            or info.type == T.RelationType.TopExt_Bottom then
        tmp = self._owner:getYMin();
        self._owner:setHeight(self._owner._rawSize.height - dy);
        self._owner:setYMin(tmp + dy);
    elseif info.type == T.RelationType.BottomExt_Top
            or info.type == T.RelationType.BottomExt_Bottom then
        tmp = self._owner:getYMin();
        self._owner:setHeight(self._owner._rawSize.height + dy);
        self._owner:setYMin(tmp);
    end
end

---@param target GObject
---@param info RelationDef
function M:applyOnSizeChanged(target, info)
    local pos = 0;
    local pivot = 0;
    local delta = 0;

    if (info.axis == 0) then
        if (target ~= self._owner._parent) then
            pos = target._position.x;
            if (target._pivotAsAnchor) then
                pivot = target._pivot.x;
            end
        end

        if info.percent then
            if (self._targetData.z ~= 0) then
                delta = target._size.width / self._targetData.z;
            end
        else
            delta = target._size.width - self._targetData.z;
        end
    else
        if (target ~= self._owner._parent) then
            pos = target._position.y;
            if (target._pivotAsAnchor) then
                pivot = target._pivot.y;
            end
        end

        if info.percent then

            if self._target.w ~= 0 then
                delta = target._size.height / self._targetData.w
            end
        else
            delta = target._size.height - self._targetData.w;
        end
    end

    local v, tmp

    ---移动x轴------------------------
    if info.type == T.RelationType.Left_Left then
        if (info.percent) then
            self._owner:setXMin(pos + (self._owner:getXMin() - pos) * delta);
        elseif (pivot ~= 0) then
            self._owner:setX(self._owner._position.x + delta * (-pivot));
        end
    elseif info.type == T.RelationType.Left_Center then
        if (info.percent) then
            self._owner:setXMin(pos + (self._owner:getXMin() - pos) * delta);
        else
            self._owner:setX(self._owner._position.x + delta * (0.5 - pivot));
        end
    elseif info.type == T.RelationType.Left_Right then
        if (info.percent) then
            self._owner:setXMin(pos + (self._owner:getXMin() - pos) * delta);
        else
            self._owner:setX(self._owner._position.x + delta * (1 - pivot));
        end
    elseif info.type == T.RelationType.Center_Center then
        if (info.percent) then
            self._owner:setXMin(pos + (self._owner:getXMin() + self._owner._rawSize.width * 0.5 - pos) * delta - self._owner._rawSize.width * 0.5);
        else
            self._owner:setX(self._owner._position.x + delta * (0.5 - pivot));
        end
    elseif info.type == T.RelationType.Right_Left then
        if (info.percent) then
            self._owner:setXMin(pos + (self._owner:getXMin() + self._owner._rawSize.width - pos) * delta - self._owner._rawSize.width);
        elseif (pivot ~= 0) then
            self._owner:setX(self._owner._position.x + delta * (-pivot));
        end
    elseif info.type == T.RelationType.Right_Center then
        if (info.percent) then
            self._owner:setXMin(pos + (self._owner:getXMin() + self._owner._rawSize.width - pos) * delta - self._owner._rawSize.width);
        else
            self._owner:setX(self._owner._position.x + delta * (0.5 - pivot));
        end
    elseif info.type == T.RelationType.Right_Right then
        if (info.percent) then
            self._owner:setXMin(pos + (self._owner:getXMin() + self._owner._rawSize.width - pos) * delta - self._owner._rawSize.width);
        else
            self._owner:setX(self._owner._position.x + delta * (1 - pivot));
        end
        ---移动y轴------------------------
    elseif info.type == T.RelationType.Top_Top then
        if (info.percent) then
            self._owner:setYMin(pos + (self._owner:getYMin() - pos) * delta);
        elseif (pivot ~= 0) then
            self._owner:setY(self._owner._position.y + delta * (-pivot));
        end
    elseif info.type == T.RelationType.Top_Middle then
        if (info.percent) then
            self._owner:setYMin(pos + (self._owner:getYMin() - pos) * delta);
        else
            self._owner:setY(self._owner._position.y + delta * (0.5 - pivot));
        end
    elseif info.type == T.RelationType.Top_Bottom then
        if (info.percent) then
            self._owner:setYMin(pos + (self._owner:getYMin() - pos) * delta);
        else
            self._owner:setY(self._owner._position.y + delta * (1 - pivot));
        end
    elseif info.type == T.RelationType.Middle_Middle then
        if (info.percent) then
            self._owner:setYMin(pos + (self._owner:getYMin() + self._owner._rawSize.height * 0.5 - pos) * delta - self._owner._rawSize.height * 0.5);
        else
            self._owner:setY(self._owner._position.y + delta * (0.5 - pivot));
        end
    elseif info.type == T.RelationType.Bottom_Top then
        if (info.percent) then
            self._owner:setYMin(pos + (self._owner:getYMin() + self._owner._rawSize.height - pos) * delta - self._owner._rawSize.height);
        elseif (pivot ~= 0) then
            self._owner:setY(self._owner._position.y + delta * (-pivot));
        end
    elseif info.type == T.RelationType.Bottom_Middle then
        if (info.percent) then
            self._owner:setYMin(pos + (self._owner:getYMin() + self._owner._rawSize.height - pos) * delta - self._owner._rawSize.height);
        else
            self._owner:setY(self._owner._position.y + delta * (0.5 - pivot));
        end
    elseif info.type == T.RelationType.Bottom_Bottom then
        if (info.percent) then
            self._owner:setYMin(pos + (self._owner:getYMin() + self._owner._rawSize.height - pos) * delta - self._owner._rawSize.height);
        else
            self._owner:setY(self._owner._position.y + delta * (1 - pivot));
        end
        -----size----------------------------
    elseif info.type == T.RelationType.Width then
        if (self._owner._underConstruct and self._owner == target._parent) then
            v = self._owner.sourceSize.width - target.initSize.width;
        else
            v = self._owner._rawSize.width - self._targetData.z;
        end
        if (info.percent) then
            v = v * delta;
        end
        if (self._target == self._owner._parent) then
            if (self._owner._pivotAsAnchor) then
                tmp = self._owner:getXMin();
                self._owner:setSize(target._size.width + v, self._owner._rawSize.height, true);
                self._owner:setXMin(tmp);
            else
                self._owner:setSize(target._size.width + v, self._owner._rawSize.height, true);
            end
        else
            self._owner:setWidth(target._size.width + v);
        end
    elseif info.type == T.RelationType.Height then
        if (self._owner._underConstruct and self._owner == target._parent) then
            v = self._owner.sourceSize.height - target.initSize.height;
        else
            v = self._owner._rawSize.height - self._targetData.w;
        end
        if (info.percent) then
            v = v * delta;
        end
        if (self._target == self._owner._parent) then
            if (self._owner._pivotAsAnchor) then
                tmp = self._owner:getYMin();
                self._owner:setSize(self._owner._rawSize.width, target._size.height + v, true);
                self._owner:setYMin(tmp);
            else
                self._owner:setSize(self._owner._rawSize.width, target._size.height + v, true);
            end
        else
            self._owner:setHeight(target._size.height + v);
        end
    elseif info.type == T.RelationType.LeftExt_Left then
        tmp = self._owner:getXMin();
        if (info.percent) then
            v = pos + (tmp - pos) * delta - tmp;
        else
            v = delta * (-pivot);
        end
        self._owner:setWidth(self._owner._rawSize.width - v);
        self._owner:setXMin(tmp + v);
    elseif info.type == T.RelationType.LeftExt_Right then
        tmp = self._owner:getXMin();
        if (info.percent) then
            v = pos + (tmp - pos) * delta - tmp;
        else
            v = delta * (1 - pivot);
        end
        self._owner:setWidth(self._owner._rawSize.width - v);
        self._owner:setXMin(tmp + v);
    elseif info.type == T.RelationType.RightExt_Left then
        tmp = self._owner:getXMin();
        if (info.percent) then
            v = pos + (tmp + self._owner._rawSize.width - pos) * delta - (tmp + self._owner._rawSize.width);
        else
            v = delta * (-pivot);
        end
        self._owner:setWidth(self._owner._rawSize.width + v);
        self._owner:setXMin(tmp);
    elseif info.type == T.RelationType.RightExt_Right then
        tmp = self._owner:getXMin();
        if (info.percent) then
            if (self._owner == target._parent) then
                if (self._owner._underConstruct) then
                    self._owner:setWidth(pos + target._size.width - target._size.width * pivot +
                            (self._owner.sourceSize.width - pos - target.initSize.width + target.initSize.width * pivot) * delta);
                else
                    self._owner:setWidth(pos + (self._owner._rawSize.width - pos) * delta);
                end
            else
                v = pos + (tmp + self._owner._rawSize.width - pos) * delta - (tmp + self._owner._rawSize.width);
                self._owner:setWidth(self._owner._rawSize.width + v);
                self._owner:setXMin(tmp);

            end
        else
            if (self._owner == target._parent) then
                if (self._owner._underConstruct) then
                    self._owner:setWidth(self._owner.sourceSize.width + (target._size.width - target.initSize.width) * (1 - pivot));
                else
                    self._owner:setWidth(self._owner._rawSize.width + delta * (1 - pivot));
                end
            else
                v = delta * (1 - pivot);
                self._owner:setWidth(self._owner._rawSize.width + v);
                self._owner:setXMin(tmp)
            end
        end
    elseif info.type == T.RelationType.TopExt_Top then
        tmp = self._owner:getYMin();
        if (info.percent) then
            v = pos + (tmp - pos) * delta - tmp;
        else
            v = delta * (-pivot);
        end
        self._owner:setHeight(self._owner._rawSize.height - v);
        self._owner:setYMin(tmp + v);
    elseif info.type == T.RelationType.TopExt_Bottom then
        tmp = self._owner:getYMin();
        if (info.percent) then
            v = pos + (tmp - pos) * delta - tmp;
        else
            v = delta * (1 - pivot);
        end
        self._owner:setHeight(self._owner._rawSize.height - v);
        self._owner:setYMin(tmp + v);
    elseif info.type == T.RelationType.BottomExt_Top then
        tmp = self._owner:getYMin();
        if (info.percent) then
            v = pos + (tmp + self._owner._rawSize.height - pos) * delta - (tmp + self._owner._rawSize.height);
        else
            v = delta * (-pivot);
        end
        self._owner:setHeight(self._owner._rawSize.height + v);
        self._owner:setYMin(tmp);
    elseif info.type == T.RelationType.BottomExt_Bottom then
        tmp = self._owner:getYMin();
        if (info.percent) then
            if (self._owner == target._parent) then
                if (self._owner._underConstruct) then
                    self._owner:setHeight(pos + target._size.height - target._size.height * pivot +
                            (self._owner.sourceSize.height - pos - target.initSize.height + target.initSize.height * pivot) * delta);
                else
                    self._owner:setHeight(pos + (self._owner._rawSize.height - pos) * delta);
                end
            else
                v = pos + (tmp + self._owner._rawSize.height - pos) * delta - (tmp + self._owner._rawSize.height);
                self._owner:setHeight(self._owner._rawSize.height + v);
                self._owner:setYMin(tmp);
            end
        else
            if (self._owner == target._parent) then
                if (_owner._underConstruct) then
                    self._owner:setHeight(self._owner.sourceSize.height + (target._size.height - target.initSize.height) * (1 - pivot));
                else
                    self._owner:setHeight(self._owner._rawSize.height + delta * (1 - pivot));
                end
            else
                v = delta * (1 - pivot);
                self._owner:setHeight(self._owner._rawSize.height + v);
                self._owner:setYMin(tmp);
            end
        end
    end
end

function M:addRefTarget(target)
    if not target then
        return
    end

    if target ~= self._owner._parent then
        target:addEventListener(T.UIEventType.PositionChange, handler(self, self.onTargetXYChanged), self)
    end
    target:addEventListener(T.UIEventType.SizeChange, handler(self, self.onTargetSizeChanged), self)

    self._targetData.x = self._target._position.x
    self._targetData.y = self._target._position.y
    self._targetData.z = self._target._size.width
    self._targetData.w = self._target._size.height

end

function M:releaseRefTarget(target)
    if not target then
        return
    end

    target:removeEventListener(T.UIEventType.PositionChange, self)
    target:removeEventListener(T.UIEventType.SizeChange, self)

end

---@param context EventContext
function M:onTargetXYChanged(context)
    local target = context:getSender()
    if self._owner:relations().handling ~= nil or
            (self._owner._group ~= nil and self._owner._group._updating ~= 0)
    then
        self._targetData.x = target._position.x
        self._targetData.y = target._position.y
        return
    end

    self._owner:relations().handling = target

    local ox = self._owner._position.x
    local oy = self._owner._position.y
    local dx = target._position.x - self._targetData.x
    local dy = target._position.y - self._targetData.y

    for i, v in ipairs(self._defs) do
        self:applyOnXYChanged(target, v, dx, dy)
    end

    self._targetData.x = target._position.x
    self._targetData.y = target._position.y

    if ox ~= self._owner._position.x or oy ~= self._owner._position.y then
        ox = self._owner._position.x - ox
        oy = self._owner._position.y - ox

        self._owner:updateGearFromRelations("gearXY", ox, oy)

        if self._owner._parent then
            local arr = self._owner._parent:getTransitions()
            for i, v in ipairs(arr) do
                v:updateFromRelations(self._owner.id, ox, oy)
            end
        end

    end

    self._owner:relations().handling = nil

end

---@param context EventContext
function M:onTargetSizeChanged(context)

    local target = context:getSender()
    if self._owner:relations().handling or
            (self._owner._group ~= nil and self._owner._group._updating ~= 0)
    then
        self._targetData.z = target._size.width
        self._targetData.w = target._size.height
        return
    end

    self._owner:relations().handling = target

    local ox = self._owner._position.x
    local oy = self._owner._position.y
    local ow = self._owner._rawSize.width
    local oh = self._owner._rawSize.height

    for i, v in ipairs(self._defs) do
        self:applyOnSizeChanged(target, v)
    end

    self._targetData.z = target._size.width
    self._targetData.w = target._size.height

    if ox ~= self._owner._position.x or oy ~= self._owner._position.y then
        ox = self._owner._position.x - ox
        oy = self._owner._position.y - ox

        self._owner:updateGearFromRelations("gearXY", ox, oy)

        if self._owner._parent then
            local arr = self._owner._parent:getTransitions()
            for i, v in ipairs(arr) do
                v:updateFromRelations(self._owner.id, ox, oy)
            end
        end

    end

    if ow ~= self._owner._rawSize.width or oh ~= self._owner._rawSize.height then
        ow = self._owner._rawSize.width - ow
        oh = self._owner._rawSize.height - oh

        self._owner:updateGearFromRelations("gearSize", ox, oy)
    end

    self._owner:relations().handling = nil
end

return M
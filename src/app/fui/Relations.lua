local ByteArray = require("framework.cc.utils.ByteArray")

local RelationItem = require("app.fui.RelationItem")

---@class Relations
---@field protected _owner GObject
---@field protected _items
---@field public handling GObject
local M = class("Relations")

local RELATION_NAMES = {
    "left-left", -- 0
    "left-center",
    "left-right",
    "center-center",
    "right-left",
    "right-center",
    "right-right",
    "top-top", -- 7
    "top-middle",
    "top-bottom",
    "middle-middle",
    "bottom-top",
    "bottom-middle",
    "bottom-bottom",
    "width-width", -- 14
    "height-height", --15
    "leftext-left", --16
    "leftext-right",
    "rightext-left",
    "rightext-right",
    "topext-top", --20
    "topext-bottom",
    "bottomext-top",
    "bottomext-bottom"--23
}

function M:ctor(owner)
    self._owner = owner
    self.handling = nil
    self._items = {}
end

---@param target GObject
---@param relationType RelationType
---@param usePercent boolean
function M:add(target, relationType, usePercent)
    if usePercent==nil then
        usePercent = false
    end

    for i, v in ipairs(self._items) do
        if v:getTarget() == target then
            v:add(relationType, usePercent)
            return
        end
    end

    local newItem = RelationItem.new(self._owner)
    newItem:setTarget(target)
    newItem:add(relationType, usePercent)
    table.insert(self._items, newItem)
end

---@param target GObject
---@param sidePairs string
function M:addItems(target, sidePairs)
    local arr = string.split(sidePairs, ",")
    for i, v in ipairs(arr) do
        local usePercent = (string.sub(v, -1) == "%")
        if usePercent then
            v = string.sub(v, i, -1)
        end

        if not string.find(v, "-") then
            v = v .. "-" .. v
        end

        local relationType = table.indexof(RELATION_NAMES,v)

        if relationType == false then
            print("invalid relation type")
            return
        end

        self:add(target, relationType-1, usePercent)
    end
end

---@param target GObject
---@param relationType RelationType
function M:remove(target, relationType)
    for i, v in ipairs(self._items) do
        if v:getTarget() == target then
            v:remove(relationType)
        end
    end
end

---@param target GObject
function M:contains(target)
    for i, v in ipairs(self._items) do
        if v:getTarget() == target then
            return true
        end
    end
    return false
end

---@param target GObject
function M:clearFor(target)
    for i = #self._items, 1, -1 do
        local item = self._items[i]
        if item:getTarget() == target then
            table.remove(self._items, i)
        end
    end
end

function M:clearAll()
    self._items = {}
end

---@param source Relations
function M:copyFrom(source)
    self:clearAll()

    for i, v in ipairs(source._items) do
        local item = RelationItem.new(self._owner)
        item:copyFrom(v)
        table.insert(self._items, item)
    end
end

function M:setup(xml)

    ---@type GObject
    local target

    for i, cxml in ipairs(xml:children()) do
        if "relation" == cxml:name() then
            local targetId = cxml["@target"]
            if self._owner:getParent() then
                if targetId and targetId ~= "" then
                    target = self._owner:getParent():getChildById(targetId)
                else
                    target = self._owner:getParent()
                end
            else
                --call from component construction
                target = self._owner:getChildById(targetId)
            end

            if target then
                local sidePair = cxml["@sidePair"]
                if sidePair then
                    self:addItems(target, sidePair)
                end
            end

        end
    end
end

function M:onOwnerSizeChanged(dWidth,dHeight,applyPivot)
    for i, v in ipairs(self._items) do
        v:applyOnSelfSizeChanged(dWidth,dHeight,applyPivot)
    end
end

return M
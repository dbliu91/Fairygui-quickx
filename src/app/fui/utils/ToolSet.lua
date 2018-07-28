local socket = require("socket")

---@class ToolSet
local M = {}

function M.getCurrentTime()
    return socket.gettime()
end

local string_gsub = string.gsub
local string_match = string.match
local string_len = string.len

local util_map = function(fun, params)
    table.map(params, fun)
    return params
end

function M.convertFromHtmlColor(color)
    local result
    color = string_gsub(color, "#", "")
    if string_len(color) == 8 then
        result = { string_match(color, "(%w%w)(%w%w)(%w%w)(%w%w)") }
    else
        result = { string_match(color, "(%w%w)(%w%w)(%w%w)") }
    end
    result = util_map(function(v, k)
        return tonumber(v, 16) or 0
    end, result)
    if 3 < #result then
        return cc.c4b(result[2], result[3], result[4], result[1])
    else
        return cc.c4b(result[1], result[2], result[3], 255)
    end
end

function M.convertFromHtmlColor4F(color)
    local result
    color = string_gsub(color, "#", "")
    if string_len(color) == 8 then
        result = { string_match(color, "(%w%w)(%w%w)(%w%w)(%w%w)") }
    else
        result = { string_match(color, "(%w%w)(%w%w)(%w%w)") }
    end
    result = util_map(function(v, k)
        return (tonumber(v, 16) or 0) / 255
    end, result)
    if 3 < #result then
        return cc.c4f(result[2], result[3], result[4], result[1])
    else
        return cc.c4f(result[1], result[2], result[3], 255)
    end
end

function M.parseAlign(p)
    if p == "left" then
        return T.TextHAlignment.LEFT
    elseif p == "center" then
        return T.TextHAlignment.CENTER
    elseif p == "right" then
        return T.TextHAlignment.RIGHT
    else
        return T.TextHAlignment.LEFT
    end
end

function M.parseVerticalAlign(p)
    if p == "top" then
        return T.TextVAlignment.TOP
    elseif p == "middle" then
        return T.TextVAlignment.CENTER
    elseif p == "bottom" then
        return T.TextVAlignment.BOTTOM
    else
        return T.TextVAlignment.TOP
    end
end

function M.parseGroupLayoutType(p)
    if p == "hz" then
        return T.GroupLayoutType.HORIZONTAL
    elseif p == "vt" then
        return T.TextVAlignment.VERTICAL
    else
        return T.GroupLayoutType.NONE
    end
end

local log_node_tree

local log_node_tree_kv_map

log_node_tree = function(node, cb, index)

    local is_first = false

    if not index then
        index = 1

        log_node_tree_kv_map = {}

        is_first = true
    end

    local before = ""
    for i = 1, index do
        before = before .. "#"
    end

    if cb then
        cb(before, node)

        if not log_node_tree_kv_map[before] then
            log_node_tree_kv_map[before] = {}
        end
        table.insert(log_node_tree_kv_map[before],node)
    end

    if node._children and #node._children > 0 then
        local new_index = index + 1
        for i, v in ipairs(node._children) do
            log_node_tree(v, cb, new_index)
        end
    else
        print("no child")
    end

    return log_node_tree_kv_map
end

M.log_node_tree = log_node_tree

M.addDebugButton = function(self)

    local op_debug = function(event)
        local path_pre = "games.dbmj.src"
        local help = require_ex(path_pre .. ".views.TestSceneHelp").new()
        help:test(self)
    end

    local btn = cc.ui.UIPushButton.new("res/public/tip_point.png")
                  :onButtonClicked(op_debug)
                  :addTo(self)
                  :pos(200, 400)

    btn:setGlobalZOrder(100)
end

return M
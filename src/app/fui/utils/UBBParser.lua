local M = class("UBBParser")

local __inst

M.getInstance = function()
    if not __inst then
        __inst = M.new()
    end
    return __inst
end

---@param text string
---@param remove boolean
function M:parse(text, remove)
    self._text = text
    local pos1, pos2, pos3

    local ended;
    local tag, attr;
    local repl;
    local func;
    local result = "";

    pos1 = 1
    pos2 = string.find(self._text, "%[", pos1)
    while pos2 do
        if pos2 > 1 and string.byte(self._text, pos2 - 1) == 92 then
            result = result .. string.sub(self._text, pos2 - 1);
            result = result .. "[";
            pos1 = pos2 + 1;
        else
            result = result .. string.sub(self._text, pos1, pos2 - 1);
            pos1 = pos2;
            pos2 = string.find(self._text, "%]", pos1)
            if not pos2 then
                break
            end

            ended = string.byte(self._text, pos1 + 1) == string.byte('/');
            tag = string.sub(self._text, ended and pos1 + 2 or pos1+1, pos2 - 1);
            self._readPos = pos2 + 1;
            attr = nil;
            repl = nil;

            pos3 = string.find(tag, "=")
            if pos3 then
                attr = string.sub(tag, pos3+1)
                tag = string.sub(tag, 1, pos3-1)
            end

            tag = string.lower(tag)
            func = self._handlers[tag];
            if func then
                if remove ~= true then
                    repl = func(tag, ended, attr)
                    if repl then
                        result = result .. repl
                    end
                end
            else
                result = result .. string.sub(self._text, pos1, self._readPos - 1)
            end
            pos1 = self._readPos;
        end

        pos2 = string.find(self._text, "%[", pos1)
    end

    print("最终结果", result)
    return result
end

function M:ctor()

    self._readPos = 1;
    self.smallFontSize = 12
    self.normalFontSize = 14
    self.largeFontSize = 16
    self.defaultImgWidth = 0
    self.defaultImgHeight = 0

    self._handlers = {};
    self._handlers["url"] = handler(self, self.onTag_URL);
    self._handlers["img"] = handler(self, self.onTag_IMG);
    self._handlers["b"] = handler(self, self.onTag_Simple);
    self._handlers["i"] = handler(self, self.onTag_Simple);
    self._handlers["u"] = handler(self, self.onTag_Simple);
    self._handlers["sup"] = handler(self, self.onTag_Simple);
    self._handlers["sub"] = handler(self, self.onTag_Simple);
    self._handlers["color"] = handler(self, self.onTag_COLOR);
    self._handlers["font"] = handler(self, self.onTag_FONT);
    self._handlers["size"] = handler(self, self.onTag_SIZE);
    self._handlers["align"] = handler(self, self.onTag_ALIGN);
end

function M:onTag_URL(tagName, ended, attr)
    if ended then
        if attr then
            return "<a href=\"" .. attr .. "\" target=\"_blank\">"
        else
            local href = self:getTagText()
            return "<a href=\"" .. href .. "\" target=\"_blank\">"
        end
    else
        return "</a>";
    end
end

function M:onTag_IMG(tagName, ended, attr)
    if ended then
        return ""
    else
        local src = self:getTagText(true)
        if not src then
            return ""
        end

        if self.defaultImgWidth then
            return "<img src=\"" .. src .. "\" width=\"" .. self.defaultImgWidth .. "\" height=\"" .. self.defaultImgHeight .. "\"/>";
        else
            return "<img src=\"" .. src .. "\"/>";
        end

    end
end

function M:onTag_Simple(tagName, ended, attr)
    if ended then
        return "</" .. tagName .. ">"
    else
        return "<" .. tagName .. ">"
    end
end

function M:onTag_COLOR(tagName, ended, attr)
    if false == ended then
        return "<font color=\"" .. attr .. "\">";
    else
        return "</font>"
    end
end

function M:onTag_FONT(tagName, ended, attr)
    if false == ended then
        return "<font face=\"" .. attr .. "\">";
    else
        return "</font>";
    end
end

function M:onTag_SIZE(tagName, ended, attr)
    if (false == ended) then
        return "<font size=\"" .. attr .. "\">";
    else
        return "</font>";
    end
end

function M:onTag_ALIGN(tagName, ended, attr)
    if (false == ended) then
        return "<p align=\"" .. attr .. "\">";
    else
        return "</p>";
    end
end

return M
module(..., package.seeall)

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--
-- xml.lua - XML parser for use with the Corona SDK.
--
-- version: 1.2
--
-- CHANGELOG:
--
-- 1.2 - Created new structure for returned table
-- 1.1 - Fixed base directory issue with the loadFile() function.
--
-- NOTE: This is a modified version of Alexander Makeev's Lua-only XML parser
-- found here: http://lua-users.org/wiki/LuaXml
--
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function newParser()

    XmlParser = {};

    function XmlParser:ToXmlString(value)
        value = string.gsub(value, "&", "&amp;"); -- '&' -> "&amp;"
        value = string.gsub(value, "<", "&lt;"); -- '<' -> "&lt;"
        value = string.gsub(value, ">", "&gt;"); -- '>' -> "&gt;"
        value = string.gsub(value, "\"", "&quot;"); -- '"' -> "&quot;"
        value = string.gsub(value, "([^%w%&%;%p%\t% ])",
                function(c)
                    return string.format("&#x%X;", string.byte(c))
                end);
        return value;
    end

    function XmlParser:FromXmlString(value)
        value = string.gsub(value, "&#x([%x]+)%;",
                function(h)
                    return string.char(tonumber(h, 16))
                end);
        value = string.gsub(value, "&#([0-9]+)%;",
                function(h)
                    return string.char(tonumber(h, 10))
                end);
        value = string.gsub(value, "&quot;", "\"");
        value = string.gsub(value, "&apos;", "'");
        value = string.gsub(value, "&gt;", ">");
        value = string.gsub(value, "&lt;", "<");
        value = string.gsub(value, "&amp;", "&");
        return value;
    end

    function XmlParser:ParseArgs(node, s)
        string.gsub(s, "(%w+)=([\"'])(.-)%2", function(w, _, a)
            node:addProperty(w, self:FromXmlString(a))
        end)
    end

    function XmlParser:fixParseError(xmlText, ni, j)
        local test = string.sub(xmlText, ni, j)

        local fi, fj = string.find(test, "[\"']")
        if not fi then
            ---没有字符串，跳过
            return j
        end

        ---有字符串，寻找配对
        local str_begin_pos, str_end_pos, label, q1, str, str_xxx, end_q = string.find(xmlText, "(%w+)=([\"'])(.-)%2([^>\"']-)(%/?)>", ni)
        if str_begin_pos and str_end_pos and str_end_pos > j then
            return str_end_pos
        else
            return j
        end
    end

    function XmlParser:ParseXmlText(xmlText, try_to_fix_jiantou_error,visitor)

        if not try_to_fix_jiantou_error then
            try_to_fix_jiantou_error = false
        end

        if visitor then
            --如果有监听者，开启比较耗性能的《防止字符串中有>符号，导致解析错误》
            try_to_fix_jiantou_error = true
        end

        local stack = {}
        local top = newNode()
        table.insert(stack, top)
        local ni, c, label, xarg, empty
        local i, j = 1, 1
        while true do
            ni, j, c, label, xarg, empty = string.find(xmlText, "<(%/?)([%w_:]+)(.-)(%/?)>", i)
            if not ni then
                break
            end

            if try_to_fix_jiantou_error == true then
                --防止字符串中有>符号，导致解析错误
                local fix_j = XmlParser:fixParseError(xmlText, ni, j)
                if fix_j ~= j then
                    local sub_xmlText = string.sub(xmlText, 1, fix_j)
                    ni, j, c, label, xarg = string.find(sub_xmlText, "<(%/?)([%w_:]+)(.+)>", i)
                    if xarg and string.len(xarg) > 0 then
                        local last = string.sub(xarg, -1)
                        if last == "/" then
                            empty = "/"
                            xarg = string.sub(xarg, 1, -2)
                        else
                            empty = nil
                        end
                    end
                end
            end

            local text = string.sub(xmlText, i, ni - 1);
            if not string.find(text, "^%s*$") then
                local lVal = (top:value() or "") .. self:FromXmlString(text)
                if visitor and visitor.textHandler then visitor:textHandler(lVal) end
                stack[#stack]:setValue(lVal)
            end
            if empty == "/" then
                -- empty element tag
                local lNode = newNode(label)
                self:ParseArgs(lNode, xarg)
                top:addChild(lNode)
                if visitor and visitor.startElement then visitor:startElement(lNode,stack) end
                if visitor and visitor.endElement then visitor:endElement(lNode,stack) end
            elseif c == "" then
                -- start tag
                local lNode = newNode(label)
                self:ParseArgs(lNode, xarg)
                table.insert(stack, lNode)
                top = lNode
                if visitor and visitor.startElement then visitor:startElement(lNode,stack) end
            else
                -- end tag
                local toclose = table.remove(stack) -- remove top

                top = stack[#stack]
                if #stack < 1 then
                    if try_to_fix_jiantou_error ==false then
                        return XmlParser:ParseXmlText(xmlText, true)
                    else
                        error("XmlParser: nothing to close with " .. label)
                    end
                end
                if toclose:name() ~= label then
                    if try_to_fix_jiantou_error ==false then
                        return XmlParser:ParseXmlText(xmlText, true)
                    else
                        error("XmlParser: trying to close " .. toclose:name() .. " with " .. label)
                    end
                end
                top:addChild(toclose)
                if visitor and visitor.endElement then visitor:endElement(toclose,stack) end
            end
            i = j + 1
        end
        local text = string.sub(xmlText, i);
        if #stack > 1 then
            print("XmlParser: unclosed " .. stack[#stack]:name())
            if try_to_fix_jiantou_error ==false then
                return XmlParser:ParseXmlText(xmlText, true)
            else
                error("XmlParser: trying to close " .. toclose:name() .. " with " .. label)
            end
        end
        return top
    end

    function XmlParser:loadFile(xmlFilename, base)
        if not base then
            base = system.ResourceDirectory
        end

        local path = system.pathForFile(xmlFilename, base)
        local hFile, err = io.open(path, "r");

        if hFile and not err then
            local xmlText = hFile:read("*a"); -- read file content
            io.close(hFile);
            return self:ParseXmlText(xmlText), nil;
        else
            print(err)
            return nil
        end
    end

    return XmlParser
end

function newNode(name)
    local node = {}
    node.___value = nil
    node.___name = name
    node.___children = {}
    node.___props = {}

    function node:value() return self.___value end
    function node:setValue(val) self.___value = val end
    function node:name() return self.___name end
    function node:setName(name) self.___name = name end
    function node:children() return self.___children end
    function node:numChildren() return #self.___children end
    function node:addChild(child)
        if self[child:name()] ~= nil then
            if type(self[child:name()].name) == "function" then
                local tempTable = {}
                table.insert(tempTable, self[child:name()])
                self[child:name()] = tempTable
            end
            table.insert(self[child:name()], child)
        else
            self[child:name()] = child
        end
        table.insert(self.___children, child)
    end

    function node:properties() return self.___props end
    function node:numProperties() return #self.___props end
    function node:addProperty(name, value)
        local lName = "@" .. name
        if self[lName] ~= nil then
            if type(self[lName]) == "string" then
                local tempTable = {}
                table.insert(tempTable, self[lName])
                self[lName] = tempTable
            end
            table.insert(self[lName], value)
        else
            self[lName] = value
        end
        table.insert(self.___props, { name = name, value = self[name] })
    end

    return node
end
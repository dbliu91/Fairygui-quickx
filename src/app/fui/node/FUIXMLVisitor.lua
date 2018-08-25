local FUIRichElement = require("app.fui.node.FUIRichElement")

local M = class("FUIXMLVisitor")

function M:ctor(richText)
    self._format = TextFormat.new()
    self._richText = richText

    self._textFormatStack = {}
    self._linkStack = {}
    self._textFormatStackTop = 1
    self._skipText = 0
    self._ignoreWhiteSpace = false
    self._textBlock = ""
end

function M:startElement(node, stack)
    --print(node)
    local elementName = node:name()

    if (
            elementName == "b"
    )
    then
        self:pushTextFormat()
        self._format.bold = true
    end

    if (
            elementName == "i"
    )
    then
        self:pushTextFormat()
        self._format.italics = true
    end

    if (
            elementName == "u"
    )
    then
        self:pushTextFormat()
        self._format.underline = true
    end

    if (
            elementName == "font"
    )
    then
        self:pushTextFormat()
        self._format.fontSize = checkint(node["@size"] or self._format.fontSize)
        if node["@color"] then
            self._format.color = ToolSet.convertFromHtmlColor(node["@color"])
            self._format._hasColor = true
        end
    end

    if (
            elementName == "br"
    )
    then
        self:addNewLine(false)
    end

    if (
            elementName == "img"
    )
    then
        local src = ""
        local width = 0
        local height = 0
        if node["@src"] then
            src = node["@src"]
        end

        if src and src ~= "" then
            local pi = UIPackage.getItemByURL(src)
            if pi then
                width = pi.width
                height = pi.height
            end
        end

        width = node["@width"] or width
        height = node["@height"] or height

        --[[
        if (width == 0)
            width = 5;
        if (height == 0)
            height = 10;
        --]]

        local element = FUIRichElement.new(FUIRichElement.Type.IMAGE)
        element.width = width
        element.height = height
        element.text = src
        table.insert(self._richText._richElements, element)
        if #self._linkStack > 0 then
            element.link = self._linkStack[#self._linkStack]
        end

    end

    if (
            elementName == "a"
    )
    then
        self:pushTextFormat();

        local href = node["@href"]
        local element = FUIRichElement.new(FUIRichElement.Type.LINK)
        element.text = href
        table.insert(self._richText._richElements, element)
        table.insert(self._linkStack, element)

        if (self._richText._anchorTextUnderline) then
            self._format.underline = true;
        end
        if (self._format._hasColor == true) then
            self._format.color = self._richText._anchorFontColor;
        end

    end

    if (
            elementName == "p"
                    or elementName == "ui"
                    or elementName == "div"
                    or elementName == "li"
    )
    then
        self:addNewLine(true)
    end

    if (
            elementName == "html"
                    or elementName == "body"
    )
    then
        --full html
        self._ignoreWhiteSpace = true
    end

    if (
            elementName == "head"
                    or elementName == "style"
                    or elementName == "script"
                    or elementName == "form"
    )
    then
        self._skipText = self._skipText + 1
    end

end

function M:endElement(node, stack)
    --print(node)
    local elementName = node:name()
    if (
            elementName == "b"
                    or elementName == "i"
                    or elementName == "u"
                    or elementName == "font"
    )
    then
        self:popTextFormat()
    end

    if (
            elementName == "a"
    )
    then
        self:popTextFormat()
        if #self._linkStack > 0 then
            table.remove(self._linkStack)
        end
    end

    if (
            elementName == "head"
                    or elementName == "style"
                    or elementName == "script"
                    or elementName == "form"
    )
    then
        self._skipText = self._skipText - 1
    end

end

function M:textHandler(str)

    if not str then
        return
    end

    if self._skipText~=0 then
        return
    end

    if self._ignoreWhiteSpace then
        self._textBlock = self._textBlock .. string.trim(str)
    else
        self._textBlock = self._textBlock .. str
    end

    print("textHandler",str)

end

function M:pushTextFormat()
    if #self._textFormatStack < self._textFormatStackTop then
        table.insert(self._textFormatStack, self._format)
    else
        self._textFormatStack[self._textFormatStackTop] = self._format
    end
    self._textFormatStackTop = self._textFormatStackTop + 1
end

function M:popTextFormat()
    if (self._textFormatStackTop > 1) then
        self._format = self._textFormatStack[self._textFormatStackTop];
        self._textFormatStackTop = self._textFormatStackTop - 1
    end
end

return M
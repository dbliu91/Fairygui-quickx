local xmlSimple = require("app.fui.utils.xmlSimple")
local UBBParser =  require("app.fui.utils.UBBParser")

local FUIXMLVisitor = require("app.fui.node.FUIXMLVisitor")


local GUTTER_X = 2
local GUTTER_Y = 2

local M = class("FUIRichText", function()
    return cc.Node:create()
end)

function M:ctor()
    self._ubbEnabled = false
    self._formatTextDirty = true
    self._leftSpaceWidth = 0
    self._textRectWidth = 0
    self._numLines = 0
    --self._overflow = Label::Overflow::NONE
    self._anchorTextUnderline = true
    self._anchorFontColor = display.COLOR_BLUE
    self._defaultTextFormat = TextFormat.new()

    self._richElements = {}
    self._elementRenders = {}
    self._imageLoaders = {}

    self._dimensions = cc.size(0, 0)

    self._text = ""
end

function M:onCleanup()
end

function M:getDimensions()
    return self._dimensions
end

function M:setDimensions(width, height)
    if ((self._numLines > 1 and width ~= self._dimensions.width) or width < self:getContentSize().width) then
        self._formatTextDirty = true;
        self._dimensions.width = width
        self._dimensions.height = height
    end
end

function M:getText()
    return self._text
end

function M:setText(value)
    --[[
        _text = value;
    _formatTextDirty = true;
    _richElements.clear();
    _numLines = 0;

    if (value.empty())
        return;

    string parsedText;
    if (_ubbEnabled)
        parsedText = UBBParser::getInstance()->parse(_text.c_str());
    else
        parsedText = _text;
    parsedText = "<dummy>" + parsedText + "</dummy>";
    FUIXMLVisitor visitor(this);
    SAXParser parser;
    parser.setDelegator(&visitor);
    parser.parseIntrusive(&parsedText.front(), parsedText.length());
    --]]
    self._text = value
    self._formatTextDirty = true
    self._numLines = 0

    if not value or value == "" then
        return
    end

    local parsedText
    if self._ubbEnabled == true then
        parsedText = UBBParser.getInstance():parse(self._text)
    else
        parsedText = self._text
    end

    parsedText = "<dummy>" .. parsedText .. "</dummy>"

    local visitor = FUIXMLVisitor.new(self)

    local doc = xmlSimple.newParser():ParseXmlText(parsedText,true,visitor)
    self:parseDoc(doc)
end

function M:parseDoc(doc)
    dump(doc, "", 10000)
end

function M:isUBBEnabled()
    return self._ubbEnabled
end

function M:setUBBEnabled(value)
    self._ubbEnabled = value
end

function M:getTextFormat()
    return self._defaultTextFormat
end

function M:applyTextFormat()
    self._formatTextDirty = true
end

function M:getOverflow()
    return self._overflow
end

function M:setOverflow(overflow)
    if self._overflow ~= overflow then
        self._overflow = overflow
        self._formatTextDirty = true
    end
end

function M:isAnchorTextUnderline()
    return self._anchorTextUnderline
end

function M:setAnchorTextUnderline(enable)
    if self._anchorTextUnderline ~= enable then
        self._anchorTextUnderline = enable
        self._formatTextDirty = true
    end
end

function M:getAnchorFontColor()
    return self._anchorFontColor
end

function M:setAnchorFontColor(color)
    self._anchorFontColor = color;
    self._formatTextDirty = true
end

function M:hitTestLink(worldPoint)
    local rect
    for i, v in ipairs(self:getChildren()) do
        while true do
            local element = v.element
            if element==nil or element.link==nil then
                break
            end

            local size = v:getContentSize()
            rect = cc.rect(0,0,size.width,size.height)
            local p = v:convertToNodeSpace(worldPoint)

            if cc.rectContainsPoint(rect,p)==true then
                return element.link.text
            end

            break
        end
    end

    return nil
end

--[[

    const char* hitTestLink(const cocos2d::Vec2& worldPoint);
    virtual void visit(cocos2d::Renderer *renderer, const cocos2d::Mat4 &parentTransform, uint32_t parentFlags) override;

    virtual const cocos2d::Size& getContentSize() const override;

        virtual bool init() override;
    void formatText();
    void formarRenderers();
    void handleTextRenderer(FUIRichElement* element, const TextFormat& format, const std::string& text);
    void handleImageRenderer(FUIRichElement* element);
    void addNewLine();
    int findSplitPositionForWord(cocos2d::Label* label, const std::string& text);
    void doHorizontalAlignment(const std::vector<cocos2d::Node*>& row, float rowWidth);

--[[
    std::vector<FUIRichElement*> _richElements;
    std::vector<std::vector<Node*>> _elementRenders;
    cocos2d::Vector<GLoader*> _imageLoaders;
    bool _formatTextDirty;
    cocos2d::Size _dimensions;
    float _leftSpaceWidth;
    float _textRectWidth;
    int _numLines;
    std::string _text;
    bool _ubbEnabled;
    cocos2d::Label::Overflow _overflow;
    TextFormat* _defaultTextFormat;
    bool _anchorTextUnderline;
    cocos2d::Color3B _anchorFontColor;
--]]

--]]

return M
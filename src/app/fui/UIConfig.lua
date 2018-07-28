---@class FontNameItem
---@field public name string
---@field public ttf boolean

---@class UIConfig
local UIConfig = {
    defaultFont = "";
    buttonSound = "";
    buttonSoundVolumeScale =1;
    defaultScrollStep = 25;
    defaultScrollDecelerationRate = 0.967;
    defaultScrollTouchEffect = true;
    defaultScrollBounceEffect = true;
    defaultScrollBarDisplay = T.ScrollBarDisplayType.DEFAULT;
    verticalScrollBar = "";
    horizontalScrollBar = "";
    touchDragSensitivity = 10;
    clickDragSensitivity = 2;
    touchScrollSensitivity = 20;
    defaultComboBoxVisibleItemCount = 10;
    globalModalWaiting = "";
    tooltipsWin = "";
    modalLayerColor = cc.c4f(0, 0, 0, 0.4);
    bringWindowToFrontOnClick = true;
    windowModalWaiting = "";
    popupMenu = "";
    popupMenu_seperator = "";
    _fontNames = {};
}

---@param aliasName string
UIConfig.registerFont = function(aliasName,realName)
    ---@type FontNameItem
    local fi = {}
    fi.name = realName
    fi.ttf = cc.FileUtils:getInstance():isFileExist(realName)
    UIConfig._fontNames[aliasName] = fi
end

---@param aliasName string
---@return boolean @isTTF
UIConfig.getRealFontName = function(aliasName)

    if not aliasName or aliasName == "" then
        aliasName = UIConfig.defaultFont
    end

    local realName =  UIConfig._fontNames[aliasName]
    local isTTF = false
    if realName and realName.ttf==true then
        isTTF = true
    end

    return realName and realName.name or aliasName,isTTF

end

return UIConfig
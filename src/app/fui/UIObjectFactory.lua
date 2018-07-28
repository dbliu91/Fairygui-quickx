
local GComponent = require("app.fui.GComponent")
local GImage = require("app.fui.GImage")
local GMovieClip = require("app.fui.GMovieClip")

local GGroup = require("app.fui.GGroup")
local GList = require("app.fui.GList")
local GGraph = require("app.fui.GGraph")
local GLoader = require("app.fui.GLoader")

local GButton = require("app.fui.GButton")
local GLabel = require("app.fui.GLabel")
local GProgressBar = require("app.fui.GProgressBar")
local GSlider = require("app.fui.GSlider")
local GScrollBar = require("app.fui.GScrollBar")
local GComboBox = require("app.fui.GComboBox")

local GBasicTextField = require("app.fui.text.GBasicTextField")
local GRichTextField = require("app.fui.text.GRichTextField")
local GTextInput = require("app.fui.text.GTextInput")

---@class UIObjectFactory
local M = {}

local __loaderCreator
local __packageItemExtensions = {}

M.setPackageItemExtension = function (url,creator)
    if (not url or url=="" ) then
        print("Invaild url:", url);
        return;
    end
    local pi = UIPackage.getItemByURL(url);
    if (pi) then
        pi.extensionCreator = creator;
    end

    __packageItemExtensions[url] = creator;
end

---@param pi PackageItem
---@param di DisplayListItem
M.__newObjectByItem = function(pi,di)
    local ret
    if pi.type == T.PackageItemType.IMAGE then
        ret = GImage:create()
    elseif pi.type == T.PackageItemType.MOVIECLIP then
        ret = GMovieClip:create()
    elseif pi.type == T.PackageItemType.COMPONENT then
        if pi.extensionCreator then
            ret = pi.extensionCreator()
        else
            local xml = pi.componentData
            local extention = xml:children()[1]["@extention"]
            if extention then
                if (extention == "Button") then
                    ret = GButton:create()
                elseif (extention == "Label") then
                    ret = GLabel:create()
                elseif (extention == "ProgressBar") then
                    ret = GProgressBar:create()
                elseif (extention == "Slider") then
                    ret = GSlider:create()
                elseif (extention == "ScrollBar") then
                    ret = GScrollBar:create()
                elseif (extention == "ComboBox") then
                    ret = GComboBox:create()
                else
                    ret = GComponent:create()
                end
            else
                ret = GComponent:create()
            end
        end
    end

    if ret then
        ret:setPackageItem(pi,di)
        ret:init()
    end

    return ret
end

---@param di DisplayListItem
M.__newObjectByString = function(type,di)
    local ret
    if (type == "image") then
        ret = GImage:create()
    elseif (type == "movieclip") then
        ret = GMovieClip:create()
    elseif (type == "component") then
        ret = GComponent:create()
    elseif (type == "text") then
        ret = GBasicTextField:create()
    elseif (type == "richtext") then
        ret = GRichTextField:create()
    elseif (type == "inputtext") then
        ret = GTextInput:create()
    elseif (type == "group") then
        ret = GGroup:create()
    elseif (type == "list") then
        ret = GList:create()
    elseif (type == "graph") then
        ret = GGraph:create()
    elseif (type == "loader") then
        if __loaderCreator then
            ret = __loaderCreator()
        else
            ret = GLoader:create()
        end
    else
        ret = nil
    end

    if ret then
        ret:setPackageItem(nil,di)
        ret:init()
    end

    return ret
end

M.setLoaderExtension = function(creator)
    __loaderCreator = creator
end

---@param di DisplayListItem
M.newObject = function(item,di)
    if type(item) == "string" then
        return M.__newObjectByString(item,di)
    end

    return M.__newObjectByItem(item,di)
end

---@param pi PackageItem
M.__resolvePackageItemExtension= function(pi)
    local key = UIPackage.URL_PREFIX .. pi.owner:getId() .. pi.id
    local ext = __packageItemExtensions[key]
    if ext then
        pi.extensionCreator = ext
        return
    end

    key = UIPackage.URL_PREFIX .. pi.owner:getName() .. "/" .. pi.name
    ext = __packageItemExtensions[key]
    if ext then
        pi.extensionCreator = ext
        return
    end
    pi.extensionCreator = nil
end

return M
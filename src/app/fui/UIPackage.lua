local ByteArray = require("framework.cc.utils.ByteArray")

local xmlSimple = require("app.fui.utils.xmlSimple")

local PixelHitTestData = require("app.fui.event.PixelHitTestData")

local GBitmapFont = require("app.fui.text.GBitmapFont")


---@type PackageItem
local PackageItem = require("app.fui.PackageItem")

---@class UIPackage
local M = class("UIPackage")

M.URL_PREFIX = "ui://";
M._constructing = 0

local __packageInstById = {}
local __packageInstByName = {}
local __packageList = {}
local __emptyTexture
local __xmlCache = {}

function M:ctor()
    self._descPack = {}
    self._descPackXMLNode = {}

    self._items = {}

    self._itemsById = {}
    self._itemsByName = {}

    self._sprites = {}

    self._hitTestDatas = {}
end

function M:doDestory()
    for i, v in ipairs(self._items) do
        v:doDestory()
    end
    self._sprites = {}
    self._descPack = {}
    self._descPackXMLNode = {}
end

---------分割线----静态方法----------------------------------------------


---检测是否有内存泄漏---------------------------------
local __retain_node_map = {}
local __retain_node_uid = 0
local is_debug = false
function M.markForRelease(node,__cname)
    if is_debug~=true then
        return
    end
    node.my_history = debug.getinfo(2)
    node.xxx___cname = __cname
    __retain_node_uid = __retain_node_uid+1
    node.__retain_node_uid = __retain_node_uid
    __retain_node_map[tostring(node)] = node
end

function M.dumpRetainNode()
    if is_debug~=true then
        return
    end
    print("检测是否有内存泄漏，开始")
    local uid_list_un_relase = {}
    for k, v in pairs(__retain_node_map) do
        if tolua.isnull(v) then
            __retain_node_map[k] = nil
        else
            local count = v:getReferenceCount()
            print(v.__cname,v.xxx___cname,"uid:",v.__retain_node_uid, count)
            if v.my_history then
                dump(v.my_history)
            end

            table.insert(uid_list_un_relase,v.__retain_node_uid)

            if v:getParent() then
                v:removeFromParent()
                count = count - 1
            end

            for i = 1, count do
                v:release()
            end


        end
    end
    table.sort(uid_list_un_relase)
    dump(uid_list_un_relase)
    print("检测是否有内存泄漏，结算")
end
---检测是否有内存泄漏---------------------------------

M.getById = function(id)
    return __packageInstById[id]
end

M.getByName = function(name)
    return __packageInstByName[name]
end

---@param assetPath string @文件路径
M.addPackage = function(assetPath)
    if __packageInstById[assetPath] then
        return __packageInstById[assetPath]
    end

    local pkg = M.new()
    pkg:_create(assetPath)

    __packageInstById[pkg:getId()] = pkg
    __packageInstById[assetPath] = pkg
    __packageInstByName[pkg:getName()] = pkg
    table.insert(__packageList, pkg)

    return pkg
end

M.removePackage = function(packageIdOrName)
    local pkg = M.getByName(packageIdOrName)
    if (not pkg) then
        pkg = M.getById(packageIdOrName);
    end

    if pkg then
        table.removebyvalue(__packageList, pkg)
        if pkg:getId() then
            __packageInstById[pkg:getId()] = nil
        end
        if pkg._assetPath then
            __packageInstById[pkg._assetPath] = nil
        end
        if pkg:getName() then
            __packageInstByName[pkg:getName()] = nil
        end

        pkg:doDestory()
    else
        print(string.format("FairyGUI: invalid package name or id: %s", packageIdOrName))
    end

end

M.removeAllPackages = function()
    for i, v in ipairs(__packageList) do
        v:doDestory()
    end

    __packageInstById = {}
    __packageInstByName = {}
    __packageList = {}
end

---@param pkgName string
---@param resName string
M.createObject = function(pkgName, resName)
    local pkg = M.getByName(pkgName)
    if pkg then
        return pkg:_createObject(resName)
    end
end

M.createObjectFromURL = function(url)
    local pi = M.getItemByURL(url)
    if pi then
        return pi.owner:_createObject(pi)
    else
        return nil
    end
end

M.getItemURL = function(pkgName, srcName)
    local pkg = M.getByName(pkgName)
    if pkg then
        local pi = pkg:getItemByName(srcName)
        if pi then
            return M.URL_PREFIX .. pkg:getId() .. pi.id
        end
    end
end

M.getItemByURL = function(url)
    if not url or url == "" then
        return nil
    end

    local pos = string.find(url, "/")
    if not pos then
        return nil
    end

    local tmp = string.sub(url, pos + 2)
    local pos2 = string.find(tmp, '/')
    if pos2 == nil then
        if string.len(url) > 13 then
            local pkgId = string.sub(url, 5 + 1, 5 + 8)
            local pkg = M.getById(pkgId)
            if pkg ~= nil then
                local srcId = string.sub(url, 13 + 1)
                return pkg:getItem(srcId)
            end
        end
    else
        local pkgName = string.sub(tmp, 1, pos2 - 1)
        local pkg = M.getByName(pkgName)
        if pkg ~= nil then
            local srcName = string.sub(tmp, pos2 + 1)
            return pkg:getItemByName(srcName)
        end
    end

    return nil
end

M.normalizeURL = function(url)
    if not url or url == "" then
        return url
    end

    local pos1 = string.find(url, "/")
    if not pos1 then
        return url
    end

    local tmp = string.sub(url, pos1 + 2)
    local pos2 = string.find(tmp, '/')
    if pos2 == nil then
        return url
    else
        local pkgName = string.sub(tmp, 1, pos2 - 1)
        local srcName = string.sub(tmp, pos2 + 1)
        return M.getItemURL(pkgName, srcName)
    end

end

--[[
static Texture2D* getEmptyTexture() { return _emptyTexture; }
--]]

---------分割线----get set--------------------------------------------------

function M:getId()
    return self._id
end

function M:getName()
    return self._name
end

function M:getItem(itemId)
    return self._itemsById[itemId]
end

function M:getItemByName(itemName)
    return self._itemsByName[itemName]
end

---------分割线----------------------------------------------------------------

function M:loadItem(item)
    if type(item) == "string" then
        item = self:getItemByName(item)
    end

    if not item then
        return
    end

    if item.type == T.PackageItemType.IMAGE then
        if item.decoded ~= true then
            item.decoded = true
            local sprite = self._sprites[item.id]
            if sprite then
                item.spriteFrame = self:_createSpriteTexture(sprite)
            else
                item.spriteFrame = cc.SpriteFrame:createWithTexture(__emptyTexture, cc.rect(0, 0, 2, 2));
            end

            item.spriteFrame:retain()
            UIPackage.markForRelease(item.spriteFrame,self.__cname)

            if item.scaleByTile == true then
                item.spriteFrame:getTexture():setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT)
            end

        end
    elseif item.type == T.PackageItemType.ATLAS then
        if item.decoded ~= true then
            item.decoded = true
            self:_loadAtlas(item)
        end
    elseif item.type == T.PackageItemType.SOUND then
        if item.decoded ~= true then
            item.decoded = true

            item.file = self._assetNamePrefix .. item.file

        end
    elseif item.type == T.PackageItemType.FONT then
        if item.decoded ~= true then
            item.decoded = true
            self:loadFont(item)
        end
    elseif item.type == T.PackageItemType.MOVIECLIP then
        if item.decoded ~= true then
            item.decoded = true

            self:_loadMovieClip(item)

        end
    elseif item.type == T.PackageItemType.COMPONENT then
        if item.decoded ~= true then
            item.decoded = true
            self:_loadComponent(item)
        end

        if self._loadingPackage ~= true and not item.displayList then
            self:_loadComponentChildren(item)
            self:_translateComponent(item)
        end

    end

end

function M:getPixelHitTestData(itemId)
    return self._hitTestDatas[itemId]
end

--[[
void UIPackage::setStringsSource(const char *xmlString, size_t nBytes)
{
    _stringsSource.clear();

    TXMLDocument* xml = new TXMLDocument();
    xml->Parse(xmlString, nBytes);

    TXMLElement* root = xml->RootElement();
    TXMLElement* ele = root->FirstChildElement("string");
    while (ele)
    {
        std::string key = ele->Attribute("name");
        std::string text = ele->GetText();
        size_t i = key.find("-");
        if (i == std::string::npos)
            continue;

        std::string key2 = key.substr(0, i);
        std::string key3 = key.substr(i + 1);
        ValueMap& col = _stringsSource[key2];
        col[key3] = text;

        ele = ele->NextSiblingElement("string");
    }

    delete xml;
}
--]]

--------私有函数----------------------------------------------------------------

function M:_create(assetPath)
    local fileUtil = cc.FileUtils:getInstance()

    local file = assetPath .. ".bytes"

    local fullPath = fileUtil:fullPathForFilename(file)

    local b = cc.FileUtils:getInstance():isFileExist(fullPath)

    local data_pacakge
    if b then
        data_pacakge = cc.HelperFunc:getFileData(fullPath)
    end

    if not data_pacakge or "" == data_pacakge then
        local msg = string.format("FairyGUI: cannot load package from '%s'", assetPath)
        print(msg)
        return
    end

    if __emptyTexture == nil then
        local c = cc.Director:getInstance():getTextureCache()
        c:addImage("res/miss.png")
        local tex = c:getTextureForKey("res/miss.png")
        __emptyTexture = tex
    end

    self._assetPath = assetPath;
    self._assetNamePrefix = assetPath .. "@";

    self:_decodeDesc(data_pacakge)

    self:_loadPackage()
end

---@param buffer string
function M:_decodeDesc(buffer)
    --local xxx = string.len(buffer)
    --print(buffer)
    local ba = ByteArray.new()
    ba:writeStringBytes(buffer)

    local pos = ba:getLen() - 22
    ba:setPos(pos + 10 + 1)

    local entryCount = ba:readShort()

    ba:setPos(pos + 16 + 1)
    pos = ba:readInt()

    for i = 1, entryCount do
        ba:setPos(pos + 28 + 1)
        local len = ba:readUShort()
        local len2 = ba:readUShort() + ba:readUShort()

        ba:setPos(pos + 46 + 1)
        local entryName = ba:readString(len)

        local last = string.sub(entryName, -1)
        if last ~= '/' and last ~= '\\' then
            ba:setPos(pos + 20 + 1)
            local size = ba:readInt()
            ba:setPos(pos + 42 + 1)
            local offset = ba:readInt() + 30 + len

            if size > 0 then
                local data = string.sub(buffer, offset + 1, offset + size)
                self._descPack[entryName] = data
            end
        end

        pos = pos + 46 + len + len2
    end
end

function M:_loadPackage()
    local fileUtil = cc.FileUtils:getInstance()

    local file = self._assetNamePrefix .. "sprites.bytes"

    local fullPath = fileUtil:fullPathForFilename(file)


    local data_sprites = cc.HelperFunc:getFileData(fullPath)

    if not data_sprites or data_sprites == "" then
        print(string.format("FairyGUI: cannot load package from '%s'", self._assetNamePrefix))
        return
    end

    self._loadingPackage = true

    local lines = string.split(data_sprites, "\n")
    local cnt = #lines

    for i = 1 + 1, cnt do
        while true do
            local line = lines[i]
            if string.len(line) == 0 then
                break
            end

            local arr = string.split(line, ' ')
            local sprite = {}

            local itemId = arr[1]
            local binIndex = checkint(arr[2])
            if binIndex >= 0 then
                sprite.atlas = "atlas" .. tostring(binIndex)
            else
                local pos = string.find(itemId, "_")
                if pos == nil then
                    sprite.atlas = "atlas_" .. itemId
                else
                    sprite.atlas = "atlas_" .. string.sub(itemId, pos)
                end
            end

            sprite.x = checkint(arr[3])
            sprite.y = checkint(arr[4])
            sprite.width = checkint(arr[5])
            sprite.height = checkint(arr[6])

            sprite.rotated = (arr[7] == "1")

            self._sprites[itemId] = sprite

            break
        end
    end

    local hitTestDataFilePath = self._assetNamePrefix .. "hittest.bytes"

    local hitTestDataFilePath_fullPath = fileUtil:fullPathForFilename(hitTestDataFilePath)
    local b = cc.FileUtils:getInstance():isFileExist(hitTestDataFilePath_fullPath)


    if b then

        local data_hitTestData = cc.HelperFunc:getFileData(hitTestDataFilePath_fullPath)

        if data_hitTestData and data_hitTestData ~= "" then
            local ba = ByteArray.new(ByteArray.ENDIAN_BIG)
            ba:writeStringBytes(data_hitTestData)

            ba:setPos(1)

            while ba:getAvailable() > 0 do
                local pht = PixelHitTestData.new()
                local l = ba:readUShort()
                local key = ba:readString(l)
                self._hitTestDatas[key] = pht
                pht:load(ba)
            end
        end
    end

    local xmlData = self._descPack["package.xml"]
    --local xml = xmlSimple.newParser():ParseXmlText(xmlData)
    local xml = self:getXMLNode(xmlData, "package.xml")

    local root = xml:children()[1]

    self._id = root["@id"]
    self._name = root["@name"]

    local rxml = root.resources
    if not rxml then
        print(string.format("FairyGUI: invalid package xml '%s'", self._assetNamePrefix))
        return
    end

    for i, cxml in ipairs(rxml:children()) do
        ---@type PackageItem
        local pi = PackageItem.new()
        pi.owner = self
        pi.type = cxml:name()
        pi.id = cxml["@id"]

        pi.name = cxml["@name"]
        pi.exported = cxml["@exported"]
        pi.file = cxml["@file"]

        local p = cxml["@size"]
        if p then
            local v2 = string.split(p, ",")
            pi.width = checkint(v2[1])
            pi.height = checkint(v2[2])
        end

        if pi.type == T.PackageItemType.IMAGE then
            local p = cxml["@scale"]
            if p then
                if p == "9grid" then
                    local p2 = cxml["@scale9grid"]
                    if p2 then
                        local v4 = string.split(p2, ',')
                        pi.scale9Grid = {}

                        pi.scale9Grid.x = checkint(v4[1]);
                        pi.scale9Grid.y = checkint(v4[2]);
                        pi.scale9Grid.width = checkint(v4[3]);
                        pi.scale9Grid.height = checkint(v4[4]);

                        pi.tileGridIndice = checkint(cxml["@gridTile"])
                    end
                elseif p == "tile" then
                    pi.scaleByTile = true
                end
            end
        elseif pi.type == T.PackageItemType.COMPONENT then
            UIObjectFactory.__resolvePackageItemExtension(pi);
        end

        table.insert(self._items, pi)

        self._itemsById[pi.id] = pi
        if pi.name then
            self._itemsByName[pi.name] = pi
        end

    end

    for i, v in ipairs(self._items) do
        self:loadItem(v)
    end

    self._loadingPackage = false

end

function M:_createSpriteTexture(sprite)
    local atlasItem = self:getItem(sprite.atlas)

    local atlasTexture

    if atlasItem then
        self:loadItem(atlasItem)
        atlasTexture = atlasItem.texture
    else
        atlasTexture = __emptyTexture
    end

    local spriteFrame = cc.SpriteFrame:createWithTexture(
            atlasTexture,
            cc.rect(sprite.x, sprite.y, sprite.width, sprite.height),
            sprite.rotated,
            cc.p(0, 0),
            cc.size(sprite.width, sprite.height)
    )
    return spriteFrame

end

function M:_loadAtlas(item)

    local filePath = self._assetNamePrefix .. (item.file and item.file or (item.id .. ".png"))

    local c = cc.Director:getInstance():getTextureCache()
    c:addImage(filePath)
    local tex = c:getTextureForKey(filePath)
    item.texture = tex

    local hasAlphaTexture
    --TODO
end

function M:_loadMovieClip(item)
    local xmlData = self._descPack[item.id .. ".xml"]
    --local doc = xmlSimple.newParser():ParseXmlText(xmlData)
    local doc = self:getXMLNode(xmlData, item.id .. ".xml")
    local xml = doc:children()[1]

    local interval = checknumber(xml["@interval"]) / 1000
    item.repeatDelay = checknumber(xml["@repeatDelay"]) / 1000
    local swing = (xml["@swing"] == "true")

    local frameCount = checkint(xml["@frameCount"])
    local frames = {}
    local animationSpriteFrameNameList = {}

    local idx = 0

    local mcSizeInPixels = cc.size(item.width, item.height)

    local contentScaleFactor = cc.Director:getInstance():getContentScaleFactor()
    local mcSize = cc.size(mcSizeInPixels.width / contentScaleFactor, mcSizeInPixels.height / contentScaleFactor)

    for i, v in ipairs(xml.frames:children()) do
        if v:name() == "frame" then
            local arr = string.split(v["@rect"], ",")
            local rect = cc.rect(
                    checkint(arr[1]),
                    checkint(arr[2]),
                    checkint(arr[3]),
                    checkint(arr[4])
            )
            local addDelay = checkint(v["@addDelay"]) / 1000

            local p = v["@sprite"]
            local spriteId
            if p then
                spriteId = item.id .. "_" .. p
            elseif rect.width ~= 0 then
                spriteId = item.id .. "_" .. idx
            end

            local spriteFrame

            local sp
            if spriteId then
                sp = self._sprites[spriteId]
                if sp then
                    local atlasItem = self:getItem(sp.atlas)
                    if atlasItem then
                        spriteFrame = self:_createSpriteTexture(sp)
                        spriteFrame:setOriginalSizeInPixels(mcSizeInPixels)
                        spriteFrame:setOriginalSize(mcSize)
                    end
                end

            end

            if spriteFrame == nil then
                spriteFrame = cc.SpriteFrame:createWithTexture(__emptyTexture, cc.rect(0, 0, 2, 2));
            end

            spriteFrame:setOffset(cc.p(
                    rect.x - (mcSize.width - rect.width) / 2,
                    -(rect.y - (mcSize.height - rect.height) / 2)
            ))

            cc.SpriteFrameCache:getInstance():addSpriteFrame(spriteFrame, spriteId)
            local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(spriteId)

            table.insert(frames, frame)
            table.insert(animationSpriteFrameNameList, spriteId)

            idx = idx + 1

        end
    end

    if swing == true then
        for i = #frames, 1 + 1, -1 do
            local f = frames[i]
            table.insert(frames, f)
        end
    end

    item.animation = cc.Animation:createWithSpriteFrames(frames, interval)
    item.animation:retain()
    UIPackage.markForRelease(item.animation,self.__cname)
    item.animationSpriteFrameNameList = animationSpriteFrameNameList
end

---@param item PackageItem
function M:loadFont(item)
    local fntData = self._descPack[item.id .. ".fnt"]

    local bitmapFont = GBitmapFont.new()
    bitmapFont:parseFntData(item.id,fntData,self)

    item.bitmapFont = bitmapFont

end

--[[
void UIPackage::loadFont(PackageItem * item)
{
    while (lines.next())
    {
        size_t len = lines.getTextLength();
        const char* line = lines.getText();
        if (len > 4 && memcmp(line, "info", 4) == 0)
        {
            props.start(line, len, ' ');
            while (props.next())
            {
                props.getKeyValuePair(keyBuf, sizeof(keyBuf), valueBuf, sizeof(valueBuf));

                if (strcmp(keyBuf, "face") == 0)
                {
                    ttf = true;

                    auto it = _sprites.find(item->id);
                    if (it != _sprites.end())
                    {
                        mainSprite = it->second;
                        PackageItem* atlasItem = getItem(mainSprite->atlas);
                        loadItem(atlasItem);
                        mainTexture = atlasItem->texture;
                    }
                }
                else if (strcmp(keyBuf, "size") == 0)
                    sscanf(valueBuf, "%d", &size);
                else if (strcmp(keyBuf, "resizable") == 0)
                    resizable = strcmp(valueBuf, "true") == 0;
                else if (strcmp(keyBuf, "colored") == 0)
                    canTint = strcmp(valueBuf, "true") == 0;
            }

            if (size == 0)
                size = lineHeight;
            else if (lineHeight == 0)
                lineHeight = size;
        }
        else if (len > 6 && memcmp(line, "common", 6) == 0)
        {
            props.start(line, len, ' ');
            while (props.next())
            {
                props.getKeyValuePair(keyBuf, sizeof(keyBuf), valueBuf, sizeof(valueBuf));

                if (strcmp(keyBuf, "lineHeight") == 0)
                    sscanf(valueBuf, "%d", &lineHeight);

                if (strcmp(keyBuf, "xadvance") == 0)
                    sscanf(valueBuf, "%d", &xadvance);
            }
        }
        else if (len > 4 && memcmp(line, "char", 4) == 0)
        {
            FontLetterDefinition def;
            memset(&def, 0, sizeof(def));

            int bx = 0, by = 0, charId = 0;
            int bw = 0, bh = 0;
            PackageItem* charImg = nullptr;

            props.start(line, len, ' ');
            while (props.next())
            {
                props.getKeyValuePair(keyBuf, sizeof(keyBuf), valueBuf, sizeof(valueBuf));

                if (strcmp(keyBuf, "id") == 0)
                    sscanf(valueBuf, "%d", &charId);
                else if (strcmp(keyBuf, "x") == 0)
                    sscanf(valueBuf, "%d", &bx);
                else if (strcmp(keyBuf, "y") == 0)
                    sscanf(valueBuf, "%d", &by);
                else if (strcmp(keyBuf, "xoffset") == 0)
                    sscanf(valueBuf, "%f", &def.offsetX);
                else if (strcmp(keyBuf, "yoffset") == 0)
                    sscanf(valueBuf, "%f", &def.offsetY);
                else if (strcmp(keyBuf, "width") == 0)
                    sscanf(valueBuf, "%d", &bw);
                else if (strcmp(keyBuf, "height") == 0)
                    sscanf(valueBuf, "%d", &bh);
                else if (strcmp(keyBuf, "xadvance") == 0)
                    sscanf(valueBuf, "%d", &def.xAdvance);
                else if (!ttf && strcmp(keyBuf, "img") == 0)
                    charImg = getItem(valueBuf);
            }

            if (ttf)
            {
                Rect tempRect = Rect(bx + mainSprite->rect.origin.x, by + mainSprite->rect.origin.y, bw, bh);
                tempRect = CC_RECT_PIXELS_TO_POINTS(tempRect);
                def.U = tempRect.origin.x;
                def.V = tempRect.origin.y;
                def.width = tempRect.size.width;
                def.height = tempRect.size.height;
                def.validDefinition = true;
            }
            else if (charImg)
            {
                loadItem(charImg);

                Rect tempRect = charImg->spriteFrame->getRectInPixels();
                bw = tempRect.size.width;
                bh = tempRect.size.height;
                tempRect = CC_RECT_PIXELS_TO_POINTS(tempRect);
                def.U = tempRect.origin.x;
                def.V = tempRect.origin.y;
                def.width = tempRect.size.width;
                def.height = tempRect.size.height;
                if (mainTexture == nullptr)
                    mainTexture = charImg->spriteFrame->getTexture();
                def.validDefinition = true;
            }
            fontAtlas->addLetterDefinition(charId, def);

            if (size == 0)
                size = bh;
            if (!ttf && lineHeight < size)
                lineHeight = size;
        }
    }

    fontAtlas->addTexture(mainTexture, 0);
    fontAtlas->setLineHeight(lineHeight);
    item->bitmapFont->_originalFontSize = size;
    item->bitmapFont->_resizable = resizable;
    item->bitmapFont->_canTint = canTint;
}
--]]

function M:_loadComponent(item)
    local xmlData = self._descPack[item.id .. ".xml"]
    --local doc = xmlSimple.newParser():ParseXmlText(xmlData)
    local doc = self:getXMLNode(xmlData, item.id .. ".xml")
    item.componentData = doc
end

function M:_loadComponentChildren(item)
    local listNode = item.componentData:children()[1].displayList

    item.displayList = {}

    if listNode then

        local displayListItem

        for i, cxml in ipairs(listNode:children()) do
            local p = cxml["@src"]
            if p then
                local src = p
                local pkgId = cxml["@pkg"] and p or ""

                local pkg
                if pkgId ~= "" and pkgId ~= item.owner:getId() then
                    pkg = M.getById(pkgId)
                else
                    pkg = item.owner
                end

                local pi = pkg and pkg:getItem(src) or nil
                if pi then
                    displayListItem = { packageItem = pi, type = "" }
                else
                    displayListItem = { packageItem = nil, type = cxml:name() }
                end
            else
                if cxml:name() == "text" and cxml["@input"] == "true" then
                    displayListItem = { packageItem = nil, type = "inputtext" }
                else
                    displayListItem = { packageItem = nil, type = cxml:name() }
                end
            end

            displayListItem.desc = cxml
            table.insert(item.displayList, displayListItem)
        end


    end

end

---@param item PackageItem
function M:_translateComponent(item)
    --[[
if (_stringsSource.empty())
        return;

    auto it = _stringsSource.find(_id + item->id);
    if (it == _stringsSource.end())
        return;

    const ValueMap& strings = it->second;
    std::string ename, elementId, value;
    const char* p;
    int dcnt = item->displayList->size();
    for (int i = 0; i < dcnt; i++)
    {
        TXMLElement* cxml = item->displayList->at(i)->desc;
        ename = cxml->Name();
        elementId = (p = cxml->Attribute("id")) ? p : STD_STRING_EMPTY;
        if (p = cxml->Attribute("tooltips"))
        {
            auto it = strings.find(elementId + "-tips");
            if (it != strings.end())
                cxml->SetAttribute("tooltips", it->second.asString().c_str());
        }

        TXMLElement* dxml = cxml->FirstChildElement("gearText");
        if (dxml != nullptr)
        {
            {
                auto it = strings.find(elementId + "-texts");
                if (it != strings.end())
                    dxml->SetAttribute("values", it->second.asString().c_str());
            }

            {
                auto it = strings.find(elementId + "-texts_def");
                if (it != strings.end())
                    dxml->SetAttribute("default", it->second.asString().c_str());
            }
        }

        if (ename == "text" || ename == "richtext")
        {
            {
                auto it = strings.find(elementId);
                if (it != strings.end())
                    cxml->SetAttribute("text", it->second.asString().c_str());
            }

            {
                auto it = strings.find(elementId + "-prompt");
                if (it != strings.end())
                    cxml->SetAttribute("prompt", it->second.asString().c_str());
            }
        }
        else if (ename == "list")
        {
            TXMLElement* exml = cxml->FirstChildElement("item");
            int j = 0;
            while (exml)
            {
                auto it = strings.find(elementId + "-" + Value(j).asString());
                if (it != strings.end())
                    exml->SetAttribute("title", it->second.asString().c_str());

                exml = exml->NextSiblingElement("item");
                j++;
            }
        }
        else if (ename == "component")
        {
            dxml = cxml->FirstChildElement("Button");
            if (dxml != nullptr)
            {
                {
                    auto it = strings.find(elementId);
                    if (it != strings.end())
                        dxml->SetAttribute("title", it->second.asString().c_str());
                }

                {
                    auto it = strings.find(elementId + "-0");
                    if (it != strings.end())
                        dxml->SetAttribute("selectedTitle", it->second.asString().c_str());
                }

                continue;
            }

            dxml = cxml->FirstChildElement("Label");
            if (dxml != nullptr)
            {
                {
                    auto it = strings.find(elementId);
                    if (it != strings.end())
                        dxml->SetAttribute("title", it->second.asString().c_str());
                }

                {
                    auto it = strings.find(elementId + "-prompt");
                    if (it != strings.end())
                        dxml->SetAttribute("prompt", it->second.asString().c_str());
                }

                continue;
            }

            dxml = cxml->FirstChildElement("ComboBox");
            if (dxml != nullptr)
            {
                {
                    auto it = strings.find(elementId);
                    if (it != strings.end())
                        dxml->SetAttribute("title", it->second.asString().c_str());
                }

                TXMLElement* exml = dxml->FirstChildElement("item");
                int j = 0;
                while (exml)
                {
                    auto it = strings.find(elementId + "-" + Value(j).asString());
                    if (it != strings.end())
                        exml->SetAttribute("title", it->second.asString().c_str());

                    exml = exml->NextSiblingElement("item");
                    j++;
                }

                continue;
            }
        }
    }
    --]]
end

function M:_createObject(item)
    if type(item) == "string" then
        item = self:getItemByName(item)
    end

    self:loadItem(item)

    ---@type GObject
    local g = UIObjectFactory.newObject(item)
    if not g then
        return
    end

    M._constructing = M._constructing + 1
    g:constructFromResource()
    M._constructing = M._constructing - 1

    return g

end

function M:getXMLNode(xmlData, key)
    local doc = self._descPackXMLNode[key]
    if not doc then
        doc = xmlSimple.newParser():ParseXmlText(xmlData)
        self._descPackXMLNode[key] = doc
    end
    return doc
end

return M

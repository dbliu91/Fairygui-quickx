---@class PackageItem
---@field public id string
---@field public name string
---@field public width number
---@field public height number
---@field public file string
---@field public decoded boolean
---@field public exported boolean
---@field public displayList std::vector<DisplayListItem*>*
---@field public extensionCreator  std::function<GComponent*()>
---@field public componentData TXMLDocument
---@field public owner GObject
local PackageItem = class("PackageItem")

function PackageItem:load()
    self.owner:loadItem(self)
end

function PackageItem:doDestory()
    if self.spriteFrame then
        self.spriteFrame:release()
        self.spriteFrame = nil
    end

    if self.animation then
        self.animation:release()
        self.animation = nil
    end
end

return PackageItem

local M = class("PixelHitTestData")

function M:load(ba)
    ba:readInt()
    self.pixelWidth = ba:readInt()
    self.scale = 1/ba:readByte()
    self.pixelsLength = ba:readInt()
    self.pixels = {}

    for i = 1, self.pixelsLength do
        self.pixels[i]=ba:readByte()
    end
end

return M
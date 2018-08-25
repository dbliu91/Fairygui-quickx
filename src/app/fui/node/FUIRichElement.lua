local M = class("FUIRichElement")

M.Type = {
    Text = 1;
    IMAGE = 2;
    LINK = 3;
}

function M:ctor(type)
    self._type = type
    self.width = 0
    self.height = 0
    self.link = nil
    self.text = ""
    self.textFormat = TextFormat.new()
end

return M
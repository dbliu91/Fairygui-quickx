local M = class("GObjectPool")

function M:ctor()
    self._pool = {}
end

function M:returnObject(obj)

    if not self._pool[obj:getResourceURL()] then
        self._pool[obj:getResourceURL()] = {}
    end

    table.insert(self._pool[obj:getResourceURL()],obj)
end

function M:getObject(url)
    local url2 = UIPackage.normalizeURL(url)
    if not url2 or url2=="" then
        return
    end

    local ret
    local arr = self._pool[url2]
    if arr and #arr>0 then
        ret = arr[#arr]
        table.remove(arr)
    else
        ret = UIPackage.createObjectFromURL(url2)
    end

    return ret

end

return M
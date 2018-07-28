
---@class GCoroutine
local M =  class("GCoroutine")

function M:ctor()
    self.routines = {}
    self.routine_dt = 0
    self.lastTime = nil
end

---你不resume协程，然后引用也不指向它，自然它会被gc掉
function M:PlayRoutine(func)
    local routine = coroutine.create(func)
    table.insert(self.routines, routine)
    return routine
end

---你不resume协程，然后引用也不指向它，自然它会被gc掉
function M:RemoveAllRoutine()
    self.routines = {}
end

function M:RemoveRoutine(routine_toremove)
    if routine_toremove then
        for i, routine in ipairs(self.routines) do
            if routine == routine_toremove then
                table.remove(self.routines, i)
                return
            end
        end
    end
end
function M:WaitRoutine(routine)
    while true do
        if coroutine.status(routine) == "dead" then
            return
        else
            coroutine.yield()
        end
    end
end
function M:WaitCondition(cond_func)
    while true do
        if cond_func() then
            return
        else
            coroutine.yield()
        end
    end
end
function M:WaitFrame(frame)
    while true do
        if frame == 0 then
            return
        else
            coroutine.yield()
        end
        frame = frame - 1
    end
end
function M:WaitTime(time)
    self:WaitRoutine(self:PlayRoutine(function()
        while true do
            time = time - self.routine_dt
            if time <= 0 then
                return
            else
                coroutine.yield()
            end
        end
    end))
end
function M:WaitRoutinesAll(...)
    local cos = {...}
    if #cos == 0 then
        return
    end
    while true do
        local all_dead = true
        for _, co in ipairs(cos) do
            if coroutine.status(co) ~= "dead" then
                all_dead = false
                break
            end
        end
        if all_dead then
            break
        else
            coroutine.yield()
        end
    end
end
function M:WaitRoutinesAny(...)
    local cos = {...}
    if #cos == 0 then
        return
    end
    while true do
        for _, co in ipairs(cos) do
            if coroutine.status(co) == "dead" then
                return
            end
        end
        coroutine.yield()
    end
end
function M:halt()
    while true do
        coroutine.yield()
    end
end

function M:updateCoroutine(dt)
    self.routine_dt = self.lastTime and (ToolSet.getCurrentTime() - self.lastTime) or dt
    self.lastTime = ToolSet.getCurrentTime()
    local new_routines = {}
    for _, routine in ipairs(self.routines) do
        if coroutine.status(routine) ~= "dead" then
            self:resumeCoroutine(routine)
            table.insert(new_routines, routine)
        end
    end
    self.routines = new_routines
end

function M:resumeCoroutine(routine)

    ---兼容在协程中调用了import
    local _import = import
    import = function(moduleName, currentModuleName)
        local theModule
        coroutine.yield(
                "import",
                function()
                    theModule = _import(moduleName, currentModuleName)
                end
        )
        return theModule
    end
    local _resume = coroutine.resume
    coroutine.resume = function(co, ...)
        local result, message, func = _resume(co, ...)
        assert(result, message)
        if message == "import" and type(func) == "function" then
            coroutine.yield(func)
        end
    end
    local result, message, func = _resume(routine)
    import = _import
    coroutine.resume = _resume

    if result~=true and message then
        print("报错了！！！")
        print("--------------------------------------------------------------")
        print(message)
        print("--------------------------------------------------------------")
        print("主线程",debug.traceback())
        print("--------------------------------------------------------------")
        print("当前协程",debug.traceback(routine))
        print("报错了日志结束！！！")
    end
    assert(result, message)
    if message == "import" and type(func) == "function" then
        func()
    end
end

return M
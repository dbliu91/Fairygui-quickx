-- Copyright (C) 2015 - 2017
-- @file        profiler.lua
-- 用法：
--local profiler = require("app.fui.utils.profiler").new()
--profiler:onStart()
--profiler:onSop()


-- define module
local profiler = class("fui_profiler")

profiler.m_reports = {}
profiler.m_reportsByTitle = {}
profiler.m_startTime = 0
profiler.m_stopTime = 0

-- get the function title
function profiler:onFuncTitle(funcinfo)

    -- check
    assert(funcinfo)

    -- the function name
    local name = funcinfo.name or 'anonymous'

    -- the function line
    local line = string.format("%d", funcinfo.linedefined or 0)

    -- the function source
    local source = funcinfo.short_src or 'C_FUNC'

    -- make title
    return string.format("%-30s: %s: %s", name, source, line)
end

-- get the function report
function profiler:onFuncReport(funcinfo)

    -- get the function title
    local title = self:onFuncTitle(funcinfo)

    -- get the function report
    local report = self.m_reportsByTitle[title]

    if not report then
        -- init report
        report =
        {
            title       = self:onFuncTitle(funcinfo)
        ,   callcount   = 0
        ,   totaltime   = 0
        }
        -- save it
        self.m_reportsByTitle[title] = report
        table.insert(self.m_reports, report)
    end
    -- ok
    return report
end

-- profiling call
function profiler:onProfilieCall(funcinfo)

    -- get the function report
    local report = self:onFuncReport(funcinfo)

    assert(report)

    -- save the call time
    report.calltime    = os.clock()

    -- update the call count
    report.callcount   = report.callcount + 1
end



-- profiling return
function profiler:onProfilieReturn(funcinfo)

    -- get the stoptime
    local stoptime = os.clock()

    -- get the function report
    local report = self:onFuncReport(funcinfo)

    assert(report)

    -- update the total time
    if report.calltime and report.calltime > 0 then
        report.totaltime = report.totaltime + (stoptime - report.calltime)
        report.calltime = 0
    end
end

-- the profiling handler
function profiler.onProfileHandler(hooktype)
    -- the function info
    local funcinfo = debug.getinfo(2, 'nS')

    -- dispatch it
    if hooktype == "call" then
        profiler:onProfilieCall(funcinfo)
    elseif hooktype == "return" then
        profiler:onProfilieReturn(funcinfo)
    end
end

-- the tracing handler
function profiler.onTraceHandler(hooktype)
    -- the function info
    local funcinfo = debug.getinfo(2, 'nS')
    -- is call
    if hooktype == "call" then

        local name = funcinfo.name
        local source = funcinfo.short_src or 'C_FUNC'

        if name and string.find(source, "%.lua") then--profiler.isfile(source) then

            -- the function line
            local line = string.format("%d", funcinfo.linedefined or 0)
            -- trace it
            print("%-30s: %s: %s", name, source, line)
        end
    end
end

-- start profiling
function profiler:onStart(mode)
    if mode and mode == "trace" then
        debug.sethook(profiler.onTraceHandler, 'cr')
    else
        debug.sethook(profiler.onProfileHandler, 'cr')
    end
end

-- stop profiling
function profiler:onStop(mode)
    -- trace
    if mode and mode == "trace" then
        debug.sethook()
    else
        -- save the stop time
        self.m_stopTime = os.clock()

        -- stop to hook
        debug.sethook()

        -- calculate the total time
        local totaltime = self.m_stopTime - self.m_startTime

        -- sort reports
        table.sort(self.m_reports, function(a, b)
            return a.totaltime > b.totaltime
        end)

        -- show reports
        for _, report in ipairs(self.m_reports) do
            -- calculate percent
            local percent = (report.totaltime / totaltime) * 100
            if percent < 1 then
                break
            end
            -- trace
            print(string.format("%0.3f, %6.2f, %d, %s", report.totaltime, percent, report.callcount, report.title))
        end
    end
end

-- return module
return profiler
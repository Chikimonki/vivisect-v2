-- anti_debug.lua
local function is_debugged()
    local status = io.open("/proc/self/status", "r")
    if not status then return false end
    
    local content = status:read("*a")
    status:close()
    
    local tracer = content:match("TracerPid:%s*(%d+)")
    return tracer and tonumber(tracer) > 0
end

if is_debugged() then
    print("Debugger detected. Self-destructing...")
    os.exit(1)
end

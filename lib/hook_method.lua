-- hook_method.lua
-- Choose best hooking method for target binary

local M = {}

function M.choose(binary_info, function_name)
    -- Priority order:
    -- 1. LD_PRELOAD (easiest, fastest)
    -- 2. PLT hijacking (works on dynamic binaries)
    -- 3. GOT patching (needs PIE knowledge)
    -- 4. Inline hooking (nuclear option)
    
    if not binary_info.is_static then
        -- Dynamic binary - can use LD_PRELOAD
        return {
            method = "LD_PRELOAD",
            reason = "Dynamic binary, cleanest approach",
            needs_root = false
        }
    end
    
    if not binary_info.is_pie then
        -- Fixed addresses - PLT hijacking
        local plt_addr = require("lib.binary_info").find_function_plt(binary_info.path, function_name)
        if plt_addr then
            return {
                method = "PLT_PATCH",
                reason = "Non-PIE binary with accessible PLT",
                target_addr = plt_addr,
                needs_root = true
            }
        end
    end
    
    -- Last resort - inline hooking
    return {
        method = "INLINE_HOOK",
        reason = "Static or stripped binary, full code patch needed",
        needs_root = true
    }
end

return M

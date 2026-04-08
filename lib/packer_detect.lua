-- lib/packer_detect.lua - FIXED VERSION
local M = {}

function M.is_upx_packed(path)
    -- Method 1: Check section names
    local handle = io.popen(string.format("readelf -S '%s' 2>/dev/null", path))
    local output = handle:read("*a")
    handle:close()
    
    if output:match("UPX") then
        return true, "UPX"
    end
    
    -- Method 2: Check for UPX magic signature
    local f = io.open(path, "rb")
    if not f then return false end
    
    local data = f:read(4096)
    f:close()
    
    if data and data:match("UPX!") then
        return true, "UPX"
    end
    
    return false
end

function M.detect_packer(path)
    print(string.format("[*] Analyzing: %s", path))
    
    -- Check for UPX
    local is_upx, name = M.is_upx_packed(path)
    if is_upx then
        return name
    end
    
    -- Check entropy
    local f = io.open(path, "rb")
    if not f then return nil end
    
    local data = f:read("*a")
    f:close()
    
    local entropy = M.calculate_entropy(data)
    print(string.format("[*] Entropy: %.2f (high entropy = likely packed)", entropy))
    
    if entropy > 7.5 then
        return "Unknown (high entropy)"
    end
    
    return nil
end

function M.calculate_entropy(data)
    local freq = {}
    local sample_size = math.min(#data, 100000)  -- Sample first 100KB
    
    for i = 1, sample_size do
        local byte = data:byte(i)
        freq[byte] = (freq[byte] or 0) + 1
    end
    
    local entropy = 0
    
    for _, count in pairs(freq) do
        local p = count / sample_size
        if p > 0 then
            entropy = entropy - (p * math.log(p, 2))
        end
    end
    
    return entropy
end

return M

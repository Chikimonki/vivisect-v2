-- terminus_pane_0_top_left.lua
local ffi = require("ffi")
ffi.cdef[[
    typedef long HRESULT;
    typedef struct IDXGISwapChain IDXGISwapChain;
    typedef HRESULT (__stdcall *PresentFn)(IDXGISwapChain*, unsigned int, unsigned int);
]]

local vtable = ffi.cast("void***", swapchain_ptr)[0]
local original = ffi.cast("PresentFn", vtable[8]) -- Present is index 8 in DX12

local function my_present(sc, sync, flags)
    -- we are now god
    imgui_render_here_lmao()
    return original(sc, sync, flags)
end

vtable[8] = ffi.cast("void*", my_present)
print("[+] SwapChain::Present now belongs to us")

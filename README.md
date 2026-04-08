# VIVISECT

Binary exploitation framework. LuaJIT + Zig.

## Quick Start

Open http://localhost:8080

## Tools

| Tool | What It Does |
|------|-------------|
| autohook | Runtime function hooking |
| debugger | ptrace-based debugger |
| tracer | Execution tracing + branch analysis |
| unpack | Automatic binary unpacking |
| rop_builder | ROP gadget finder |
| auto_pwn | AI-assisted exploit generation |

## Stack

- LuaJIT 2.1 (FFI, runtime scripting)
- Zig 0.15.2 (implant compilation)
- Capstone (disassembly)
- ptrace (process control)

## Usage
Analyze a binary
cd neural && luajit auto_pwn.lua ../targets/binary

Hook a process
cd hooks && sudo luajit autohook.lua ../targets/binary strcmp

Debug a process
cd hooks && sudo luajit debugger.lua <PID>

Trace execution
cd hooks && sudo luajit tracer.lua <PID>

text


## Requirements

- Linux (WSL2 works)
- LuaJIT 2.1+
- Zig 0.15.2+

## License

MIT

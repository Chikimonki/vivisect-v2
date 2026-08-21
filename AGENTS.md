# AGENTS.md — Vivisect v2.0

> **Read this first, agent.** Vivisect touches the kernel. Safety > speed.

## 1. What this repo is

**VIVISECT v2.0 — Zero-budget Linux kernel research & runtime analysis platform.**
- **Core strength:** Lua runtime analysis (`vivisect.lua`, `run_all_validators.lua`, `memfd_exec.lua`) + live `dumps/` + tracing — *real observation beats static guessing*.
- **Satellites:** `ebpf_rootkit/` (eBPF stealth), `chapter2_implant.zig` / `uefi_shell.c` (Zig/UEFI implants), `neural/` `web/` `c2/` (analysis/infra).
- **Budget:** $0 — WSL2 + Docker Desktop only. No QEMU host yet (see Lessons Learned).

## 2. Safety — non-negotiable

- **Never run validators on the host.** Always inside Docker:
  ```bash
  docker build -t vivisect:v2 .
  docker run --rm -it --privileged -v $(pwd):/vivisect vivisect:v2
  # Inside container:
  ./run_all_validators.lua 2>&1 | tee validator_run.log
  ```
- **Do not load `ebpf_rootkit/` or `uefi_shell.c` on host** — they are research artifacts, not for host kernel.
- **`ksmbd` “module not found” is environmental** — WSL kernel omits it. Do not “fix” by loading random ko. Use QEMU vanilla mainline if you need `tools/testing/selftests` + `LKDTM`.
- **Dumps are evidence, not exploits:** `dumps/*.bin` + `docs/texts/*.txt` contain observable responses, not reliable primitives. See `README → Hard Truths`.

## 3. How to work in this repo

**Quick verify (Fresh Forensics style):**
```bash
./forensics_capture.sh --no-build   # → forensics_report_YYYYMMDD_HHMMSS/
cheat vivisect  # if you installed gullwing cheat, or cat gullwing
```

**Structure:**
- `vivisect.lua`, `run_all_validators.lua`, `memfd_exec.lua` — Lua tracing
- `dumps/` — live captures (`live_dump.bin`, `oep_dump.bin`, `unpacked_fast.bin`) — **git-ignored for large bins, keep small samples**
- `docs/texts/` — `Blog_post.txt`, `The_Vision.txt`, `tree.txt`, `real_output.txt` etc. — root is clean
- `ebpf_rootkit/`, `chapter2_implant.zig`, `uefi_shell.c` — implants
- `neural/`, `web/`, `c2/`, `hooks/`, `implants/` — satellites
- `Dockerfile`, `deploy.sh` — reproducible env
- `docs/banner-1280x640.svg` — social preview

**Do NOT edit:**
- `final_dump.bin` etc. directly — regenerate via validators
- `README.md` hero without updating `docs/banner-1280x640.svg`

## 4. Commit style

- `docs: README refresh` — hero, video `hUZ9JTGYeQo`, Mermaid
- `chore: declutter root — move texts to docs/texts, bins to dumps`
- `exp: validator run 2026-08-21 — forensics_report`
- Keep `Budget: $0` honesty — no “exploit” claims without `validator_run.log` + dump.

## 5. For AI agents — prime directive

- Declare primary axis before editing: **Runtime Kernel Analysis via Lua** is the trunk; implants/C2/neural are branches.
- If you change kernel surface, also update `docs/texts/tree.txt` and `README → Architecture` Mermaid.
- Prefer `Docker` + `forensics_capture.sh` evidence over host `strace` alone.
- Ask before adding `ICM/` or `prime-agent/` — this repo is research, not financial compliance (see PartyVault’s `docs/ICM-PARTYVAULT-V9.md` for contrast).

---
*Author: Chikimonki — INTP systems explorer — Pan Enterprises, Liverpool — `pan283@gmail.com` — Demo: https://youtu.be/hUZ9JTGYeQo*
*Built with LuaJIT FFI + Zig + eBPF + Docker + WSL2 — honest, $0, reproducible.*

# VIVISECT v2.0

**Zero-budget Linux kernel research & runtime analysis platform.**

Explores kernel complexity through CVE-driven test generation, live interaction, Lua-based dynamic instrumentation, memory dumping/unpacking, eBPF, UEFI/Zig implants, and C2 scaffolding. Built entirely in WSL2 + Docker Desktop.

## Core Strength
The Lua runtime analysis layer (`vivisect.lua`, `run_all_validators.lua`, `memfd_exec.lua`, memory dumps, tracing) is the most developed capability. It enables real observation of kernel behavior at runtime rather than static guessing.

Video Demonstration: https://youtu.be/hUZ9JTGYeQo

## Directory Highlights
(See `Repo_Structure.txt`, `Final_Structure.txt`, `tree.txt`)

- `kernel/` + `run_all_validators.lua` – Validation suite
- `vivisect.lua`, `*.lua` – Dynamic instrumentation & tracing
- `dumps/` – Live memory captures, OEP dumping, unpacking artifacts
- `ebpf_rootkit/`, `uefi_implant/`, `chapter2_implant.zig` – Multi-layer implants
- `neural/`, `web/`, `c2/` – Supporting analysis and infrastructure
- `docker/`, `Dockerfile`, `deploy.sh` – Reproducible environments

## Docker Quick Start
```bash
docker build -t vivisect:v2 .
docker run --rm -it --privileged -v $(pwd):/vivisect vivisect:v2
# Inside: ./run_all_validators.lua 2>&1 | tee validator_run.log

# Lessons Learned – VIVISECT v2.0

**Author:** Chikimonki - An INTP systems explorer  
**Date:** April 2026  
**Budget:** $0

### What Was Achieved
- End-to-end pipeline: CVE parsing → synthetic payload generation (1024-byte owner patterns) → live kernel service interaction (NFSd 2049, io_uring, futex) → runtime classification.
- Strong runtime analysis capability via Lua scripting + targeted memory dumping (`live_dump.bin`, `oep_dump.bin`, `unpacked_fast.bin`) + tracing.
- Broad surface coverage (kernel, eBPF rootkits, UEFI implants, Zig payloads, neural components, web dashboard) in a single coherent project.
- Docker integration completed with zero cost using only open tools.

### Hard Truths
The three "VULNERABLE" flags from the earlier run indicate the test harness successfully exercised code paths and received observable kernel responses. They do **not** constitute proof of reliable exploits against a modern hardened kernel. The gap between "triggered behavior" and "bypassing all mitigations + reliable primitive" remains large and requires deep, experience-based knowledge that cannot be fully automated or LLM-generated.

ksmbd tests failing with "module not found" is purely environmental — Microsoft’s WSL kernel deliberately omits it. This is a meta-lesson: kernel `.config`, loaded modules, and build choices often dominate results more than validator logic.

### Key Intellectual Insights
1. LLMs are excellent at maintaining momentum, generating scaffolding across languages (Lua, Zig, C, shell), and suggesting creative connections. They are poor substitutes for the tactile feedback of actually running code against a live kernel.
2. Runtime observation (your Lua + dump infrastructure) beats pure static analysis for learning. The `trace.txt`, `real_output.txt`, and binary dumps contain the real signal.
3. Scope breadth vs. depth trade-off is real. The project contains many valuable threads. Future iterations benefit from declaring a primary axis (e.g. "Runtime Kernel Analysis via Lua") and treating implants/C2/neural pieces as satellite experiments.
4. Linux kernel really does have Perl-like surprises ("more than one way to do it"). The validation suite exposed some of them in a controlled way.
5. Docker + privileged containers + volume mounts give excellent reproducibility for userspace tooling and tracing, even if the kernel itself is shared with WSL.

### Recommended Path Forward
- Capture fresh output from `./run_all_validators.lua` inside Docker.
- Mine the resulting logs/dumps for deeper patterns.
- Add Linux kernel selftests (`tools/testing/selftests`) and LKDTM (Linux Kernel Dump Test Module) for more principled testing than custom validators.
- Consider moving heavier kernel work to a proper QEMU VM with vanilla mainline kernel for better debuggability.

This project has permanently increased my intuition about kernel attack surfaces, dynamic instrumentation, and the difference between research harnesses and production exploits. That alone makes the $0 investment worthwhile.

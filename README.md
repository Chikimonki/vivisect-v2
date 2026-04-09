# VIVISECT v2.0

**A zero-budget Linux kernel research, dynamic analysis, and implant development platform.**

Built entirely in WSL2 + Docker Desktop with no financial cost. Combines automated vulnerability validation, runtime kernel probing, reverse engineering automation (Lua + Vivisect), memory dumping/unpacking, eBPF rootkits, UEFI implants, Zig payloads, C2 infrastructure, neural-inspired components, and a web dashboard.

## Vision
The Linux kernel contains surprising complexity ("more than one way to do it" — similar to Perl). VIVISECT explores this complexity through practical experimentation: parsing CVEs, generating exploit primitives, live interaction with kernel subsystems, runtime memory analysis, and implant engineering. It is an educational and research platform, not a production weaponization tool.

## Directory Structure
(See `Repo_Structure.txt`, `Final_Structure.txt`, and `tree.txt` for full details)

- `kernel/` – Core validation suite (NFSv4, io_uring, futex, ksmbd tests)
- `ebpf_rootkit/` – eBPF-based persistence and hooking
- `uefi_implant/`, `chapter2_implant.zig`, `implants/` – Bootkits and userspace implants
- `vivisect.lua`, `memfd_exec.lua`, `terminus_pane_0_top_left.lua` – Dynamic analysis and instrumentation
- `dumps/` – Memory captures and unpacking artifacts
- `neural/`, `web/` – Analysis and visualization components
- `c2/`, `rop/`, `targets/` – Supporting infrastructure
- `docker/`, `Dockerfile`, `deploy.sh` – Containerization
- `scripts/`, `test.sh` – Automation

## Capabilities Proven
- CVE parsing and bug description extraction
- Automatic generation of exploit patterns (e.g. 1024-byte owner strings)
- Live kernel service interaction (NFSd port 2049, io_uring, futex)
- Runtime memory dumping, tracing, and analysis
- Response classification (patched / vulnerable / missing)
- Multi-layer implant development (UEFI → kernel → userspace)

## Validation Results (WSL 6.6.87.2-microsoft-standard-WSL2)
- NFSv4 LOCK heap overflow: ❌ VULNERABLE (harness triggered)
- io_uring OOB read: ❌ VULNERABLE
- futex flags mismatch: ❌ VULNERABLE
- ksmbd share_conf UAF: ⚠ MISSING (module unavailable)
- ksmbd signedness bug: ⚠ MISSING (module unavailable)

**Important Note**: These results reflect the behavior of the custom test harness against this specific kernel/config. They do not constitute confirmed production 0-days. Modern mitigations make reliable exploitation non-trivial.

## Quick Start
```bash
# Build environment
docker build -t vivisect .
./deploy.sh
./test.sh

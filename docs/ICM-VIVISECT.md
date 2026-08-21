# ICM — Vivisect v2.0 — Research Control Model

**Status:** Research — not financial compliance. Lightweight ICM for symmetry with `PartyVault ICM v9.0` and `Gullwing` prime-agent.

## Control Loop

```
CVE parsing (1024-byte owner patterns)
  → Synthetic payload (Zig + Lua)
    → Live interaction (NFSd:2049, io_uring, futex)
      → Lua instrumentation (vivisect.lua + run_all_validators.lua)
        → Dumps + tracing (live_dump.bin, oep_dump.bin, trace.txt)
          → Classification (VULNERABLE flags = observable response, not exploit)
            → Implants (eBPF rootkit / UEFI / Zig) as satellite experiments
```

**Primary axis:** Runtime Kernel Analysis via Lua — all else is satellite.

## Evidence

- `forensics_capture.sh` → `forensics_report_YYYYMMDD_HHMMSS/` (hashlist, SBOM, validator logs)
- `dumps/` + `docs/texts/real_output.txt` — tactile feedback, not static guess
- `Dockerfile` + `deploy.sh` — privileged, volume-mounted, reproducible

## Guardrails

- Host never touched — Docker only
- `ksmbd` missing = WSL .config, not logic bug
- Budget $0, honesty over hype — see `README → Lessons Learned → Hard Truths`

## Relation to other ICMs

- **PartyVault ICM v9.0:** `Perl → Zig → LuaJIT → Julia` for *financial* KYC/BLAKE3 + DORA Art.28
- **Gullwing prime-agent:** `prime-agent/skills/gullwing/__init__.py` — verify before deploy
- **Vivisect ICM:** `Lua → eBPF/Zig → dumps` for *kernel* observation

---
*Pan Enterprises, Liverpool — Chikimonki — pan283@gmail.com*

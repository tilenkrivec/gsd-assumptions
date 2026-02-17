# GSD Customizations

Local modifications to [GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done) workflows.

## What This Changes

**`discuss_mode: "assumptions"`** — Replaces the default discuss-phase interview flow with a codebase-first, assumption-driven approach:

| Default `discuss` mode | Custom `assumptions` mode |
|------------------------|--------------------------|
| Identifies gray areas, asks 4 questions per area | Reads codebase deeply, surfaces assumptions with evidence |
| User answers ~15-20 questions | User reviews assumptions, corrects what's wrong (~2-4 interactions) |
| Reads roadmap description only | Reads related files, patterns, adjacent code |
| Same CONTEXT.md output | Same CONTEXT.md output |

## Setup

### macOS / Linux

```bash
git clone git@github.com:tilenkrivec/gsd-assumptions.git
cd gsd-assumptions
./install.sh
```

### Windows (PowerShell)

```powershell
git clone git@github.com:tilenkrivec/gsd-assumptions.git
cd gsd-assumptions
powershell -ExecutionPolicy Bypass -File install.ps1
```

### Windows (Git Bash)

```bash
git clone git@github.com:tilenkrivec/gsd-assumptions.git
cd gsd-assumptions
./install.sh
```

### Enable in your project

Add to `.planning/config.json`:

```json
{
  "workflow": {
    "discuss_mode": "assumptions"
  }
}
```

## After GSD Updates

GSD updates overwrite workflow files. Re-run the install script after each `/gsd:update`:

```bash
# macOS / Linux / Git Bash
./install.sh

# Windows PowerShell
powershell -ExecutionPolicy Bypass -File install.ps1
```

## Platform Support

The install scripts detect the OS and replace hardcoded home directory paths automatically:

| Platform | Script | Home path format |
|----------|--------|-----------------|
| macOS | `install.sh` | `/Users/username` |
| Linux | `install.sh` | `/home/username` |
| Windows (Git Bash) | `install.sh` | `/c/Users/username` |
| Windows (PowerShell) | `install.ps1` | `C:/Users/username` |
| WSL | `install.sh` | Detects Windows-side `.claude` dir |

## Files Modified

- `workflows/discuss-phase.md` — Adds assumptions mode branch (config-driven)
- `workflows/plan-phase.md` — Updates step 4 messaging when assumptions mode active

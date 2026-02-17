# GSD Assumptions Mode

Custom [GSD](https://github.com/gsd-build/get-shit-done) workflow modifications that replace the default interview-style `discuss-phase` with a codebase-first, assumption-driven approach.

## The Problem

GSD's default `discuss-phase` identifies "gray areas" and asks 4 questions per area. In practice, ~90% of these questions have obvious answers if the codebase is read thoroughly first. This wastes time on questions like "What layout style?" when the answer is clearly "cards, like everything else in the app."

## The Solution

A config-driven `"assumptions"` mode that flips the workflow:

| Default `discuss` mode | Custom `assumptions` mode |
|------------------------|--------------------------|
| Identifies gray areas, asks 4 questions per area | Spawns subagent to read codebase deeply, surfaces assumptions with evidence |
| User answers ~15-20 questions | User reviews assumptions, corrects what's wrong (~2-4 interactions) |
| Reads roadmap description only | Reads related files, patterns, adjacent code (5-15 files) |
| All work in main context | Codebase analysis runs as Explore subagent (protects main context) |
| Same CONTEXT.md output | Same CONTEXT.md output |

## How It Works

### Flow with `--auto` flag

```
/gsd:discuss-phase 80 --auto
  |
  |-- [main context]    Init, validate phase, detect mode
  |-- [main context]    Read ROADMAP + REQUIREMENTS (small reads)
  |
  |-- [Explore subagent] Deep codebase analysis
  |   Returns structured summary only (no raw files in main context)
  |
  |-- [main context]    Present assumptions to user
  |-- [main context]    User corrections (AskUserQuestion)
  |-- [main context]    Write CONTEXT.md + git commit
  |
  +-- AUTO-ADVANCE
      +-- [Task subagent] plan-phase --auto
          |-- [nested subagent] researcher
          |-- [nested subagent] planner
          |-- [nested subagent] checker
          +-- AUTO-ADVANCE
              +-- [nested subagent] execute-phase --auto
                  +-- [nested subagents] executors per wave
```

### Config

Add to your project's `.planning/config.json`:

```json
{
  "workflow": {
    "discuss_mode": "assumptions"
  }
}
```

Set to `"discuss"` (or omit) to use the original interview flow.

### What the user sees

1. Banner: "ANALYZING CODEBASE FOR PHASE X"
2. Subagent reads 5-15 relevant files, returns structured summary
3. Banner: "PHASE X: NAME - ASSUMPTIONS" with:
   - Codebase patterns found (with file citations)
   - Assumptions grouped by area (Confident / Likely / Unclear)
   - Scope boundaries
4. MultiSelect: "Which assumptions need correction?"
5. One focused question per correction area
6. CONTEXT.md written (same format as default discuss-phase)
7. Next steps shown (or auto-advance to plan/execute)

## Files Modified

| File | What changed |
|------|-------------|
| `workflows/discuss-phase.md` | Added assumptions mode branch after `detect_mode` step. Spawns Explore subagent for codebase analysis. Original discuss flow preserved when config is `"discuss"`. |
| `workflows/plan-phase.md` | Step 4 checks config — shows "Gather context (assumptions mode)" instead of "Run discuss-phase first" when appropriate. |
| `workflows/progress.md` | Routes B and C check config — show correct description and `--auto` hint for assumptions mode. |
| `commands/gsd/discuss-phase.md` | Updated command description to document both modes. |

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

## After GSD Updates

GSD updates overwrite workflow files. Re-run the install script after each `/gsd:update`:

```bash
./install.sh              # macOS / Linux / Git Bash
# or
powershell -File install.ps1   # Windows PowerShell
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

## Related

- [Feature request on GSD repo](https://github.com/gsd-build/get-shit-done) — requesting this as a built-in config option

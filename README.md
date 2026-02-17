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

```bash
# Clone to any machine
git clone <repo-url> ~/Desktop/DEV/gsd-customizations

# Install (copies files into ~/.claude/get-shit-done/)
./install.sh

# Add to your project config (.planning/config.json)
# "workflow": { "discuss_mode": "assumptions" }
```

## After GSD Updates

GSD updates overwrite workflow files. Re-run `./install.sh` after each `/gsd:update`.

## Files Modified

- `workflows/discuss-phase.md` — Adds assumptions mode branch (config-driven)
- `workflows/plan-phase.md` — Updates step 4 messaging when assumptions mode active

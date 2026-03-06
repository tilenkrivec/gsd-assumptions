---
name: gsd:discuss-phase
description: Gather phase context before planning (mode depends on workflow.discuss_mode config)
argument-hint: "<phase> [--auto]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - Task
---

<objective>
Extract implementation decisions that downstream agents need — researcher and planner will use CONTEXT.md to know what to investigate and what choices are locked.

**Two modes (set via `workflow.discuss_mode` in .planning/config.json):**

**"discuss" (default):**
1. Analyze the phase to identify gray areas (UI, UX, behavior, etc.)
2. Present gray areas — user selects which to discuss
3. Deep-dive each selected area until satisfied
4. Create CONTEXT.md with decisions

**"assumptions":**
1. Spawn Explore subagent to deeply analyze the codebase + existing project research for this phase
2. If external APIs/libraries need documentation lookup, spawn targeted research subagent (Context7, WebSearch, WebFetch)
3. Surface assumptions with impact context (why this way, what changes if wrong — in plain language, with source attribution for research-backed items)
4. Ask user which assumptions are wrong — each correction question includes context and consequences
5. Create CONTEXT.md with confirmed assumptions + corrections + research findings for downstream agents

**Output:** `{phase_num}-CONTEXT.md` — decisions clear enough that downstream agents can act without asking the user again
</objective>

<execution_context>
@/Users/tilenkrivec/.claude/get-shit-done/workflows/discuss-phase.md
@/Users/tilenkrivec/.claude/get-shit-done/templates/context.md
</execution_context>

<context>
Phase number: $ARGUMENTS (required)

**Load project state:**
@.planning/STATE.md

**Load roadmap:**
@.planning/ROADMAP.md
</context>

<process>
1. Validate phase number (error if missing or not in roadmap)
2. Check if CONTEXT.md exists (offer update/view/skip if yes)
3. **Check config** — read `workflow.discuss_mode` to determine mode
4. **If "assumptions" mode:**
   - Read ROADMAP.md + REQUIREMENTS.md (small reads, main context)
   - Check for existing project research files + prior phase outputs
   - Spawn Explore subagent for deep codebase analysis (reads codebase + existing research, flags knowledge gaps)
   - If knowledge gaps exist (external APIs, new libraries): spawn targeted research subagent (Context7/WebSearch/WebFetch)
   - Merge research findings into analysis
   - Present structured assumptions to user (with source attribution for research-backed items)
   - Ask which assumptions need correction (multiSelect)
   - For each correction: one focused question
   - Write CONTEXT.md with confirmed assumptions + corrections + research findings
5. **If "discuss" mode:**
   - Analyze phase — identify domain and phase-specific gray areas
   - Present gray areas — multi-select: which to discuss?
   - Deep-dive each area — 4 questions per area, then offer more/next
   - Write CONTEXT.md — sections match areas discussed
6. Offer next steps (plan phase)

**CRITICAL: Scope guardrail**
- Phase boundary from ROADMAP.md is FIXED
- Discussion clarifies HOW to implement, not WHETHER to add more
- If user suggests new capabilities: "That's its own phase. I'll note it for later."
- Capture deferred ideas — don't lose them, don't act on them

**Do NOT ask about (Claude handles these):**
- Technical implementation
- Architecture choices
- Performance concerns
- Scope expansion
</process>

<success_criteria>
- Config checked for discuss_mode
- If assumptions mode: codebase + existing research analyzed via subagent, external documentation looked up for knowledge gaps, assumptions surfaced with plain-language impact context (why this way + what changes if wrong + source attribution), confidence assessed transparently (skip questioning with visible decision banner if all confident, otherwise gather corrections with consequence-aware questions)
- If discuss mode: gray areas identified, user chose which to discuss, each area explored
- Scope creep redirected to deferred ideas
- CONTEXT.md captures decisions, not vague vision
- User knows next steps
</success_criteria>

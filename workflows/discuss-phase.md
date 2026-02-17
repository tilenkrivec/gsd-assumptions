<purpose>
Extract implementation decisions that downstream agents need.

Two modes controlled by `workflow.discuss_mode` config:

- **"discuss" (default):** Identify gray areas, let user choose what to discuss, deep-dive each area with questions until satisfied.
- **"assumptions":** Read codebase deeply first, surface assumptions with evidence, ask user only to correct what's wrong.

Both modes produce identical CONTEXT.md output for downstream agents.

You are a thinking partner, not an interviewer. The user is the visionary — you are the builder. Your job is to capture decisions that will guide research and planning, not to figure out implementation yourself.
</purpose>

<downstream_awareness>
**CONTEXT.md feeds into:**

1. **gsd-phase-researcher** — Reads CONTEXT.md to know WHAT to research
   - "User wants card-based layout" → researcher investigates card component patterns
   - "Infinite scroll decided" → researcher looks into virtualization libraries

2. **gsd-planner** — Reads CONTEXT.md to know WHAT decisions are locked
   - "Pull-to-refresh on mobile" → planner includes that in task specs
   - "Claude's Discretion: loading skeleton" → planner can decide approach

**Your job:** Capture decisions clearly enough that downstream agents can act on them without asking the user again.

**Not your job:** Figure out HOW to implement. That's what research and planning do with the decisions you capture.
</downstream_awareness>

<philosophy>
**User = founder/visionary. Claude = builder.**

The user knows:
- How they imagine it working
- What it should look/feel like
- What's essential vs nice-to-have
- Specific behaviors or references they have in mind

The user doesn't know (and shouldn't be asked):
- Codebase patterns (researcher reads the code)
- Technical risks (researcher identifies these)
- Implementation approach (planner figures this out)
- Success metrics (inferred from the work)

**In discuss mode:** Ask about vision and implementation choices.
**In assumptions mode:** Present what you learned from the codebase, let user correct.

Both modes capture decisions for downstream agents.
</philosophy>

<scope_guardrail>
**CRITICAL: No scope creep.**

The phase boundary comes from ROADMAP.md and is FIXED. Discussion clarifies HOW to implement what's scoped, never WHETHER to add new capabilities.

**Allowed (clarifying ambiguity):**
- "How should posts be displayed?" (layout, density, info shown)
- "What happens on empty state?" (within the feature)
- "Pull to refresh or manual?" (behavior choice)

**Not allowed (scope creep):**
- "Should we also add comments?" (new capability)
- "What about search/filtering?" (new capability)
- "Maybe include bookmarking?" (new capability)

**The heuristic:** Does this clarify how we implement what's already in the phase, or does it add a new capability that could be its own phase?

**When user suggests scope creep:**
```
"[Feature X] would be a new capability — that's its own phase.
Want me to note it for the roadmap backlog?

For now, let's focus on [phase domain]."
```

Capture the idea in a "Deferred Ideas" section. Don't lose it, don't act on it.
</scope_guardrail>

<gray_area_identification>
Gray areas are **implementation decisions the user cares about** — things that could go multiple ways and would change the result.

**How to identify gray areas:**

1. **Read the phase goal** from ROADMAP.md
2. **Understand the domain** — What kind of thing is being built?
   - Something users SEE → visual presentation, interactions, states matter
   - Something users CALL → interface contracts, responses, errors matter
   - Something users RUN → invocation, output, behavior modes matter
   - Something users READ → structure, tone, depth, flow matter
   - Something being ORGANIZED → criteria, grouping, handling exceptions matter
3. **Generate phase-specific gray areas** — Not generic categories, but concrete decisions for THIS phase

**Don't use generic category labels** (UI, UX, Behavior). Generate specific gray areas:

```
Phase: "User authentication"
→ Session handling, Error responses, Multi-device policy, Recovery flow

Phase: "Organize photo library"
→ Grouping criteria, Duplicate handling, Naming convention, Folder structure

Phase: "CLI for database backups"
→ Output format, Flag design, Progress reporting, Error recovery

Phase: "API documentation"
→ Structure/navigation, Code examples depth, Versioning approach, Interactive elements
```

**The key question:** What decisions would change the outcome that the user should weigh in on?

**Claude handles these (don't ask):**
- Technical implementation details
- Architecture patterns
- Performance optimization
- Scope (roadmap defines this)
</gray_area_identification>

<process>

<step name="initialize" priority="first">
Phase number from argument (required).

```bash
INIT=$(node /Users/tilenkrivec/.claude/get-shit-done/bin/gsd-tools.cjs init phase-op "${PHASE}")
```

Parse JSON for: `commit_docs`, `phase_found`, `phase_dir`, `phase_number`, `phase_name`, `phase_slug`, `padded_phase`, `has_research`, `has_context`, `has_plans`, `has_verification`, `plan_count`, `roadmap_exists`, `planning_exists`.

**If `phase_found` is false:**
```
Phase [X] not found in roadmap.

Use /gsd:progress to see available phases.
```
Exit workflow.

**If `phase_found` is true:** Continue to check_existing.
</step>

<step name="check_existing">
Check if CONTEXT.md already exists using `has_context` from init.

```bash
ls ${phase_dir}/*-CONTEXT.md 2>/dev/null
```

**If exists:**
Use AskUserQuestion:
- header: "Context"
- question: "Phase [X] already has context. What do you want to do?"
- options:
  - "Update it" — Review and revise existing context
  - "View it" — Show me what's there
  - "Skip" — Use existing context as-is

If "Update": Load existing, continue to detect_mode
If "View": Display CONTEXT.md, then offer update/skip
If "Skip": Exit workflow

**If doesn't exist:**

Check `has_plans` and `plan_count` from init. **If `has_plans` is true:**

Use AskUserQuestion:
- header: "Plans exist"
- question: "Phase [X] already has {plan_count} plan(s) created without user context. Your decisions here won't affect existing plans unless you replan."
- options:
  - "Continue and replan after" — Capture context, then run /gsd:plan-phase {X} to replan
  - "View existing plans" — Show plans before deciding
  - "Cancel" — Skip discuss-phase

If "Continue and replan after": Continue to detect_mode.
If "View existing plans": Display plan files, then offer "Continue" / "Cancel".
If "Cancel": Exit workflow.

**If `has_plans` is false:** Continue to detect_mode.
</step>

<step name="detect_mode">
Check discuss_mode config:

```bash
DISCUSS_MODE=$(node /Users/tilenkrivec/.claude/get-shit-done/bin/gsd-tools.cjs config-get workflow.discuss_mode 2>/dev/null || echo "discuss")
```

**If `DISCUSS_MODE` is "assumptions":** Jump to step `deep_codebase_analysis`.
**If `DISCUSS_MODE` is "discuss" (or anything else):** Continue to step `analyze_phase` (original flow).
</step>

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- ASSUMPTIONS MODE (discuss_mode: "assumptions")                 -->
<!-- Reads codebase deeply, surfaces assumptions, asks corrections  -->
<!-- ═══════════════════════════════════════════════════════════════ -->

<step name="deep_codebase_analysis">
**This step is the core difference from the default discuss flow.**

Before surfacing any assumptions, thoroughly analyze the codebase to understand existing patterns, conventions, and architecture relevant to this phase.

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► ANALYZING CODEBASE FOR PHASE {X}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reading existing patterns, components, and architecture...
```

**1. Read the phase description from ROADMAP.md** — understand what capability is being delivered.

**2. Read REQUIREMENTS.md** — understand the specific requirements mapped to this phase.

**3. Identify related areas of the codebase** using Glob and Grep:
   - Find files related to the phase domain (components, routes, APIs, utilities)
   - Find similar features already built (how does the app handle comparable things?)
   - Find adjacent code this phase will connect to (what it imports from, what imports from it)
   - Find configuration patterns (how are similar things configured?)
   - Find UI patterns (if UI-related: what component libraries, layouts, styles are used?)

**4. Read the most relevant files** (aim for 5-15 files depending on complexity):
   - Existing components in the same domain
   - Route structure and layout patterns
   - GraphQL queries/mutations for related data
   - Type definitions and interfaces
   - Any prior phase outputs that feed into this phase

**5. Synthesize findings internally:**
   - What patterns does this codebase follow?
   - What conventions are established?
   - What already exists that this phase should build on?
   - What genuinely has no precedent and could go multiple ways?

**Key principle:** Spend time reading code NOW so you don't waste the user's time asking questions the codebase already answers.

Continue to surface_assumptions.
</step>

<step name="surface_assumptions">
Present findings and assumptions to the user in a scannable format.

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► PHASE {X}: {NAME} — ASSUMPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase boundary: [What this phase delivers — from ROADMAP.md]
```

**Group assumptions into categories relevant to this phase:**

### What I Found in the Codebase
- [Pattern/convention observed] — found in [file(s)]
- [Existing component/approach that applies] — found in [file(s)]
- [Architecture decision already established] — found in [file(s)]

### My Assumptions (Based on Codebase Analysis)

For each assumption, state:
- **What** you'd do
- **Why** (citing codebase evidence)
- **Confidence**: `Confident` (clear precedent), `Likely` (reasonable inference), `Unclear` (could go multiple ways)

Group by phase-relevant areas (NOT generic categories). Examples:

```
### Data Model & Storage
- Confident: I'd add a `xyz` table following the existing pattern in [file] with UUID PKs and cascade deletes
- Likely: I'd store config as JSONB like ad_batches.template_config

### UI & Layout
- Confident: I'd use the existing card layout pattern from [component]
- Unclear: The detail view could be a modal (like template selector) or a full page (like angle detail) — both patterns exist

### API & Integration
- Confident: I'd follow the existing /api/ route pattern with admin secret auth
- Likely: I'd use the same S3 upload utility from lib/storage/

### Scope Boundaries
- In scope: [capabilities from roadmap]
- Out of scope: [what this phase explicitly doesn't cover]
- Ambiguous: [things that could reasonably be in or out]
```

**Only flag items as "Unclear" when the codebase genuinely has no clear precedent.** The whole point is to minimize these by reading thoroughly first.

Continue to gather_corrections.
</step>

<step name="gather_corrections">
After presenting assumptions, ask the user for corrections.

Use AskUserQuestion (multiSelect: true):
- header: "Corrections"
- question: "Which assumptions need correction? Select any that are wrong or missing context."
- options: Generate 3-4 options based on the assumption groups that had `Likely` or `Unclear` items:
  - "[Area 1]" — Brief description of what's uncertain
  - "[Area 2]" — Brief description of what's uncertain
  - "[Area 3]" — Brief description of what's uncertain
  - "All good" — Assumptions are accurate, proceed to write context

**If user selects "All good":**
Display: "Assumptions confirmed. Writing context..."
Continue to write_context.

**If user selects areas to correct:**
For each selected area, ask ONE focused AskUserQuestion:
- header: "[Area]" (max 12 chars)
- question: Specific question about what's wrong with the assumption
- options: 2-3 concrete alternatives based on what you found + "Other"

After all corrections gathered, summarize:
```
## Corrections Applied

- [Area]: [Original assumption] → [User's correction]
- [Area]: [Original assumption] → [User's correction]

Anything else to adjust, or ready to write context?
```

Use AskUserQuestion:
- header: "Ready"
- question: "Create context with these corrections?"
- options:
  - "Create context" — Write CONTEXT.md with confirmed assumptions + corrections
  - "More corrections" — I have additional changes

If "More corrections": Ask what else needs changing (free text), then re-confirm.
If "Create context": Continue to write_context.
</step>

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- DEFAULT DISCUSS MODE (discuss_mode: "discuss")                 -->
<!-- Original gray-area interview flow — unchanged                  -->
<!-- ═══════════════════════════════════════════════════════════════ -->

<step name="analyze_phase">
Analyze the phase to identify gray areas worth discussing.

**Read the phase description from ROADMAP.md and determine:**

1. **Domain boundary** — What capability is this phase delivering? State it clearly.

2. **Gray areas by category** — For each relevant category (UI, UX, Behavior, Empty States, Content), identify 1-2 specific ambiguities that would change implementation.

3. **Skip assessment** — If no meaningful gray areas exist (pure infrastructure, clear-cut implementation), the phase may not need discussion.

**Output your analysis internally, then present to user.**

Example analysis for "Post Feed" phase:
```
Domain: Displaying posts from followed users
Gray areas:
- UI: Layout style (cards vs timeline vs grid)
- UI: Information density (full posts vs previews)
- Behavior: Loading pattern (infinite scroll vs pagination)
- Empty State: What shows when no posts exist
- Content: What metadata displays (time, author, reactions count)
```
</step>

<step name="present_gray_areas">
Present the domain boundary and gray areas to user.

**First, state the boundary:**
```
Phase [X]: [Name]
Domain: [What this phase delivers — from your analysis]

We'll clarify HOW to implement this.
(New capabilities belong in other phases.)
```

**Then use AskUserQuestion (multiSelect: true):**
- header: "Discuss"
- question: "Which areas do you want to discuss for [phase name]?"
- options: Generate 3-4 phase-specific gray areas, each formatted as:
  - "[Specific area]" (label) — concrete, not generic
  - [1-2 questions this covers] (description)

**Do NOT include a "skip" or "you decide" option.** User ran this command to discuss — give them real choices.

**Examples by domain:**

For "Post Feed" (visual feature):
```
☐ Layout style — Cards vs list vs timeline? Information density?
☐ Loading behavior — Infinite scroll or pagination? Pull to refresh?
☐ Content ordering — Chronological, algorithmic, or user choice?
☐ Post metadata — What info per post? Timestamps, reactions, author?
```

For "Database backup CLI" (command-line tool):
```
☐ Output format — JSON, table, or plain text? Verbosity levels?
☐ Flag design — Short flags, long flags, or both? Required vs optional?
☐ Progress reporting — Silent, progress bar, or verbose logging?
☐ Error recovery — Fail fast, retry, or prompt for action?
```

For "Organize photo library" (organization task):
```
☐ Grouping criteria — By date, location, faces, or events?
☐ Duplicate handling — Keep best, keep all, or prompt each time?
☐ Naming convention — Original names, dates, or descriptive?
☐ Folder structure — Flat, nested by year, or by category?
```

Continue to discuss_areas with selected areas.
</step>

<step name="discuss_areas">
For each selected area, conduct a focused discussion loop.

**Philosophy: 4 questions, then check.**

Ask 4 questions per area before offering to continue or move on. Each answer often reveals the next question.

**For each area:**

1. **Announce the area:**
   ```
   Let's talk about [Area].
   ```

2. **Ask 4 questions using AskUserQuestion:**
   - header: "[Area]" (max 12 chars — abbreviate if needed)
   - question: Specific decision for this area
   - options: 2-3 concrete choices (AskUserQuestion adds "Other" automatically)
   - Include "You decide" as an option when reasonable — captures Claude discretion

3. **After 4 questions, check:**
   - header: "[Area]" (max 12 chars)
   - question: "More questions about [area], or move to next?"
   - options: "More questions" / "Next area"

   If "More questions" → ask 4 more, then check again
   If "Next area" → proceed to next selected area
   If "Other" (free text) → interpret intent: continuation phrases ("chat more", "keep going", "yes", "more") map to "More questions"; advancement phrases ("done", "move on", "next", "skip") map to "Next area". If ambiguous, ask: "Continue with more questions about [area], or move to the next area?"

4. **After all areas complete:**
   - header: "Done"
   - question: "That covers [list areas]. Ready to create context?"
   - options: "Create context" / "Revisit an area"

**Question design:**
- Options should be concrete, not abstract ("Cards" not "Option A")
- Each answer should inform the next question
- If user picks "Other", receive their input, reflect it back, confirm

**Scope creep handling:**
If user mentions something outside the phase domain:
```
"[Feature] sounds like a new capability — that belongs in its own phase.
I'll note it as a deferred idea.

Back to [current area]: [return to current question]"
```

Track deferred ideas internally.
</step>

<!-- ═══════════════════════════════════════════════════════════════ -->
<!-- SHARED STEPS (both modes converge here)                        -->
<!-- ═══════════════════════════════════════════════════════════════ -->

<step name="write_context">
Create CONTEXT.md capturing decisions made.

**Find or create phase directory:**

Use values from init: `phase_dir`, `phase_slug`, `padded_phase`.

If `phase_dir` is null (phase exists in roadmap but no directory):
```bash
mkdir -p ".planning/phases/${padded_phase}-${phase_slug}"
```

**File location:** `${phase_dir}/${padded_phase}-CONTEXT.md`

**Structure the content by what was discussed/confirmed:**

```markdown
# Phase [X]: [Name] - Context

**Gathered:** [date]
**Status:** Ready for planning
**Mode:** [discuss | assumptions]

<domain>
## Phase Boundary

[Clear statement of what this phase delivers — the scope anchor]

</domain>

<decisions>
## Implementation Decisions

### [Category 1 that was discussed/confirmed]
- [Decision or preference captured]
- [Another decision if applicable]

### [Category 2 that was discussed/confirmed]
- [Decision or preference captured]

### Claude's Discretion
[Areas where user said "you decide" or confirmed Claude's assumption — note that Claude has flexibility here]

</decisions>

<codebase_evidence>
## Codebase Patterns (assumptions mode only)

[If assumptions mode: list the key patterns and files discovered during analysis that inform implementation. This helps downstream agents skip redundant research.]

[If discuss mode: omit this section]

</codebase_evidence>

<specifics>
## Specific Ideas

[Any particular references, examples, or "I want it like X" moments from discussion]

[If none: "No specific requirements — open to standard approaches"]

</specifics>

<deferred>
## Deferred Ideas

[Ideas that came up but belong in other phases. Don't lose them.]

[If none: "None — discussion stayed within phase scope"]

</deferred>

---

*Phase: XX-name*
*Context gathered: [date]*
```

Write file.
</step>

<step name="confirm_creation">
Present summary and next steps:

```
Created: .planning/phases/${PADDED_PHASE}-${SLUG}/${PADDED_PHASE}-CONTEXT.md

## Decisions Captured

### [Category]
- [Key decision]

### [Category]
- [Key decision]

[If deferred ideas exist:]
## Noted for Later
- [Deferred idea] — future phase

---

## ▶ Next Up

**Phase ${PHASE}: [Name]** — [Goal from ROADMAP.md]

`/gsd:plan-phase ${PHASE}`

<sub>`/clear` first → fresh context window</sub>

---

**Also available:**
- `/gsd:plan-phase ${PHASE} --skip-research` — plan without research
- Review/edit CONTEXT.md before continuing

---
```
</step>

<step name="git_commit">
Commit phase context (uses `commit_docs` from init internally):

```bash
node /Users/tilenkrivec/.claude/get-shit-done/bin/gsd-tools.cjs commit "docs(${padded_phase}): capture phase context" --files "${phase_dir}/${padded_phase}-CONTEXT.md"
```

Confirm: "Committed: docs(${padded_phase}): capture phase context"
</step>

<step name="update_state">
Update STATE.md with session info:

```bash
node /Users/tilenkrivec/.claude/get-shit-done/bin/gsd-tools.cjs state record-session \
  --stopped-at "Phase ${PHASE} context gathered" \
  --resume-file "${phase_dir}/${padded_phase}-CONTEXT.md"
```

Commit STATE.md:

```bash
node /Users/tilenkrivec/.claude/get-shit-done/bin/gsd-tools.cjs commit "docs(state): record phase ${PHASE} context session" --files .planning/STATE.md
```
</step>

<step name="auto_advance">
Check for auto-advance trigger:

1. Parse `--auto` flag from $ARGUMENTS
2. Read `workflow.auto_advance` from config:
   ```bash
   AUTO_CFG=$(node /Users/tilenkrivec/.claude/get-shit-done/bin/gsd-tools.cjs config-get workflow.auto_advance 2>/dev/null || echo "false")
   ```

**If `--auto` flag present AND `AUTO_CFG` is not true:** Persist auto-advance to config (handles direct `--auto` usage without new-project):
```bash
node /Users/tilenkrivec/.claude/get-shit-done/bin/gsd-tools.cjs config-set workflow.auto_advance true
```

**If `--auto` flag present OR `AUTO_CFG` is true:**

Display banner:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► AUTO-ADVANCING TO PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Context captured. Spawning plan-phase...
```

Spawn plan-phase as Task:
```
Task(
  prompt="Run /gsd:plan-phase ${PHASE} --auto",
  subagent_type="general-purpose",
  description="Plan Phase ${PHASE}"
)
```

**Handle plan-phase return:**
- **PLANNING COMPLETE** → Plan-phase handles chaining to execute-phase (via its own auto_advance step)
- **PLANNING INCONCLUSIVE / CHECKPOINT** → Display result, stop chain:
  ```
  Auto-advance stopped: Planning needs input.

  Review the output above and continue manually:
  /gsd:plan-phase ${PHASE}
  ```

**If neither `--auto` nor config enabled:**
Route to `confirm_creation` step (existing behavior — show manual next steps).
</step>

</process>

<success_criteria>
- Phase validated against roadmap
- Config checked for discuss_mode
- **If assumptions mode:**
  - Codebase thoroughly analyzed (5-15 relevant files read)
  - Assumptions surfaced with codebase evidence
  - Only genuinely unclear items flagged for user input
  - User corrections captured
- **If discuss mode:**
  - Gray areas identified through intelligent analysis (not generic questions)
  - User selected which areas to discuss
  - Each selected area explored until user satisfied
- Scope creep redirected to deferred ideas
- CONTEXT.md captures actual decisions, not vague vision
- Deferred ideas preserved for future phases
- STATE.md updated with session info
- User knows next steps
</success_criteria>

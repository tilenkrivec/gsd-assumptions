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
**In assumptions mode:** Present what you learned from the codebase WITH enough context for the user to evaluate it. The user didn't write the code — they don't know what tables exist, what components were built, or why one approach fits better than another. Every assumption must carry its own context: what exists, why you chose this path, and what changes if you're wrong.

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

Before surfacing any assumptions, thoroughly analyze the codebase. **This runs as a subagent to protect the main context window from file contents.**

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► ANALYZING CODEBASE FOR PHASE {X}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Spawning codebase analyzer...
```

### Read phase context first (main context — small reads)

Read the phase description from ROADMAP.md and the specific requirements from REQUIREMENTS.md. These are small and needed to construct the subagent prompt.

### Spawn Explore subagent for deep analysis

```
Task(
  prompt="Analyze the codebase for Phase {phase_number}: {phase_name}.

<objective>
Find existing patterns, conventions, components, and architecture relevant to this phase.
Return a structured summary — NOT raw file contents.
</objective>

<phase_context>
**Phase goal:** {goal from ROADMAP.md}
**Phase description:** {section from ROADMAP.md}
**Requirements:** {relevant requirements from REQUIREMENTS.md}
</phase_context>

<analysis_steps>
1. **Identify related areas** using Glob and Grep:
   - Files related to the phase domain (components, routes, APIs, utilities)
   - Similar features already built (how does the app handle comparable things?)
   - Adjacent code this phase will connect to (imports, consumers)
   - Configuration patterns (how are similar things configured?)
   - UI patterns (if UI-related: component libraries, layouts, styles)

2. **Read the most relevant files** (aim for 5-15 depending on complexity):
   - Existing components in the same domain
   - Route structure and layout patterns
   - GraphQL queries/mutations for related data
   - Type definitions and interfaces
   - Any prior phase outputs that feed into this phase

3. **Synthesize findings** — organize into this exact output format:
</analysis_steps>

<required_output_format>
Return your analysis in this EXACT structure:

## Codebase Patterns Found
- [Pattern/convention] — found in [file path(s)]
- [Pattern/convention] — found in [file path(s)]
(list all relevant patterns discovered)

## Assumptions by Area

### [Area 1 — name it based on what you found, e.g. 'Data Model', 'UI Layout', 'API Integration']
- **Assumption:** [Concrete decision statement — written as a decision, not a question]
- **Why this way:** [Plain-language explanation of why this over alternatives. Reference specific codebase evidence. The user may not have created this code — explain WHAT exists and WHY it points to this choice. e.g. "The app already stores user data in `user_profiles` (created during auth setup). Extending it keeps queries simple vs. creating a separate table that would need joins."]
- **If wrong:** [What concretely changes if the user corrects this. Not vague — specific consequences. e.g. "We'd create a new `user_preferences` table with a foreign key to users, and update the settings page queries to read from there instead."]
- **Confidence:** [Confident/Likely/Unclear]
- **Evidence:** [file path(s) and what they show]

### [Area 2]
- **Assumption:** [Concrete decision statement]
- **Why this way:** [Plain-language explanation referencing codebase evidence]
- **If wrong:** [What concretely changes]
- **Confidence:** [Confident/Likely/Unclear]
- **Evidence:** [file path(s) and what they show]

### [Area 3]
- **Assumption:** [Concrete decision statement]
- **Why this way:** [Plain-language explanation referencing codebase evidence]
- **If wrong:** [What concretely changes]
- **Confidence:** [Confident/Likely/Unclear]
- **Evidence:** [file path(s) and what they show]

### Scope Boundaries
- In scope: [capabilities from phase goal]
- Out of scope: [what this phase doesn't cover]
- Ambiguous: [things that could go either way]

## Genuinely Unclear Items
(List ONLY items where the codebase has no clear precedent and the user MUST weigh in.
The fewer items here, the better — that means you read thoroughly.
For each item, use this format:)
- **[Topic]:** [Why there's no clear answer — what you looked for and didn't find. Be specific: "No existing pattern for X" not "unclear"]
  - What the user will notice: [Plain-language description of how each option affects the end result — the visible/behavioral difference, not the technical mechanism]
  - Leaning toward: [your recommended approach] — because [reasoning in plain language]
  - Alternative: [other valid approach] — [when you'd pick this instead, described in terms of user-facing outcome]
</required_output_format>

<quality_bar>
- Cite specific file paths, not vague references
- Mark confidence levels honestly: Confident (clear precedent), Likely (reasonable inference), Unclear (multiple valid approaches exist)
- Minimize 'Unclear' items by reading thoroughly — the whole point is to avoid asking the user questions the code already answers
- Group by phase-relevant areas, NOT generic categories like 'UI' or 'Backend'
- CRITICAL — Every assumption MUST have 'Why this way' and 'If wrong':
  - 'Why this way' must be understandable by someone who didn't write the code. Don't say "use TableX instead of TableY" — explain what TableX IS, when it was created, what it contains, and why it fits better.
  - 'If wrong' must describe concrete implementation changes, not vague "it would be different." What files change? What gets created/modified? What behavior shifts?
  - The user is a visionary, not a codebase archaeologist. They need enough context to evaluate whether your assumption matches their intent.
- Avoid jargon-heavy assumptions. "Extend the Prisma schema with a new relation" means nothing — say "Add a 'favorites' list to each user's data, connected to existing posts."
</quality_bar>",
  subagent_type="Explore",
  description="Analyze codebase for Phase {phase}"
)
```

### Handle Explore subagent return

Store the returned analysis as `CODEBASE_ANALYSIS`. This is a structured summary — no raw file contents in main context.

Display: `◆ Codebase analysis complete.`

Continue to surface_assumptions, passing `CODEBASE_ANALYSIS`.
</step>

<step name="surface_assumptions">
Present the subagent's analysis (`CODEBASE_ANALYSIS`) to the user in a scannable format. Do NOT re-read files — the analysis is already done.

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► PHASE {X}: {NAME} — ASSUMPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase boundary: [What this phase delivers — from ROADMAP.md]
```

**Present the CODEBASE_ANALYSIS to the user, but reformat for scannability:**

1. **Skip "Codebase Patterns Found"** — don't dump raw pattern lists. The patterns are already woven into each assumption's "Why this way" field.

2. **For each assumption area, present as a clear block:**
   ```
   ### [Area Name]

   **I'll:** [assumption in plain language]
   **Because:** [why — referencing what exists in the codebase, explained for someone who didn't write it]
   **If that's wrong:** [what changes — concrete consequences]
   **Confidence:** [level]
   ```

3. **For "Genuinely Unclear" items**, present as open questions with your recommendation:
   ```
   ### Needs Your Input

   **[Topic]:** [Why there's no clear answer from the codebase]
   → I'd go with: [recommendation] because [reasoning]
   → Alternative: [other approach] — [when you'd pick this instead]
   ```

4. **Keep Scope Boundaries brief** — one line each for in/out/ambiguous.

**Presentation principles:**
- Write for someone who hasn't looked at the code in weeks (or ever). Don't assume they remember what tables, components, or patterns exist.
- Lead with the USER-VISIBLE consequence, not the technical mechanism. "Posts will appear in a scrollable list like the existing feed" not "Reuse the FlatList component from PostFeed.tsx".
- When referencing something Claude built in a previous phase, say so: "The auth system (built in Phase 2) already stores..." — this explains WHY something exists.

**Only flag items as "Unclear" when the codebase genuinely has no clear precedent.** The whole point of the subagent analysis is to minimize these.

Continue to gather_corrections.
</step>

<step name="gather_corrections">
After presenting assumptions, ask the user for corrections.

Use AskUserQuestion (multiSelect: true):
- header: "Corrections"
- question: "Which assumptions need correction? Select any that are wrong or missing context."
- options: Generate 3-4 options based on the assumption groups that had `Likely` or `Unclear` items. Each option MUST include the assumption AND its consequence — not just the area name:
  - "[Area]: [what Claude assumed] → [what this means in practice]"
  - e.g. "Data Model: add favorites to user profiles → each user gets a favorites list stored alongside their profile data"
  - e.g. "Navigation: new tab in bottom bar → the main navigation grows from 4 to 5 tabs"
  - e.g. "Layout: card grid like existing posts → same visual style as the posts feed, 2 columns"
  - "All good" — Assumptions are accurate, proceed to write context

**If user selects "All good":**
Display: "Assumptions confirmed. Writing context..."
Continue to write_context.

**If user selects areas to correct:**
For each selected area, ask ONE focused AskUserQuestion:
- header: "[Area]" (max 12 chars)
- question: Include THREE things: (1) What you assumed, (2) WHY you assumed it (brief — reference codebase context), (3) What you need from the user. Format: "I assumed [X] because [brief reason from codebase]. What should it be instead?"
  - Example: "I assumed we'd extend the existing user_profiles table (which already stores name, email, avatar) because it avoids a new table. Should we store favorites there, or somewhere separate?"
- options: 2-3 concrete alternatives. Each option should describe the USER-VISIBLE outcome, not just the technical mechanism. Mark your recommended option with "(Recommended)" suffix. AskUserQuestion adds "Other" automatically.
  - Example: ["Add to user profiles — simpler, favorites load with profile (Recommended)", "Separate favorites storage — more flexible if favorites get complex later", "Don't store — compute from activity history"]
  - BAD example: ["Use existing UserProfile table", "New dedicated table", "External service"] — these are meaningless without context

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
  - Every assumption includes plain-language "why this way" and "if wrong" context
  - Assumptions presented for someone who didn't write the code — no orphan technical references
  - Only genuinely unclear items flagged for user input
  - Correction questions include codebase context and user-visible consequences
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

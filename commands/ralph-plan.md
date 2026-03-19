ultrathink

You are going to create a phased execution plan for a Ralph project. The plan captures the *how* — step-by-step phases with checkboxes, code sketches, and test tasks — designed to be executed by the `ralph` loop one phase at a time.

## Project name and input

Parse `$ARGUMENTS` as follows:
- The **first word** is the project name (the folder name under `ralph/projects/`).
- Everything **after the first word** is additional context provided by the user — treat it as supplementary input for the plan (e.g., scope constraints, priorities, or details not in the design document).

If `$ARGUMENTS` is empty, ask the user: "What is the project name? (The folder name under `ralph/projects/`)"

## Bootstrap

Before creating any files, ensure the required directory structure exists:

```
ralph/
└── projects/
    └── <project-name>/
```

Create these directories if they do not exist. Do NOT error out or stop — just create them silently and continue.

## Prerequisites

Before writing the plan, read:

1. `ralph/projects/<project-name>/design.md` — the source of truth for architecture, trade-offs, and resolved decisions. If this file doesn't exist, ask the user to describe what they want to plan for. Use their description as the basis for the plan, and document key technical choices in the "Design Decisions" section of the plan.
2. Any relevant `CLAUDE.md` files in the repository — for project conventions, build commands, and coding standards.

## Your task

Create `ralph/projects/<project-name>/plan.md` following the structure below. The plan must be complete and concrete — no placeholder tasks, no deferred decisions.

---

## Plan Structure

### 1. Header

```markdown
# <Project Title> — Execution Plan

> **Design document:** [design.md](./design.md)
> **Status:** Not started
> **Current phase:** Phase 0
```

### 2. How to Use This Plan

Include this section verbatim (adapt the build/test command to match this project's actual tooling — check `CLAUDE.md` or ask the user if unclear):

```markdown
---

## How to Use This Plan

This plan is designed for the Ralph loop. Each phase:

1. Has **checkboxes** for every discrete task — mark `[x]` when done.
2. Has an **Observations** section — write notes, surprises, or decisions made during that iteration.
3. Is scoped so one phase fits comfortably in a single loop iteration.
4. Includes tests for all new logic introduced in that phase.
5. Ends with a **build + test gate** — confirm the project builds and all tests pass before moving on.

**After each loop iteration:** update the "Current phase" field at the top and record observations.

**Build + test gate (mandatory at the end of every phase):**
```<build-command> && <test-command>```
A phase is **not complete** until both commands succeed and **all** tests pass (including pre-existing tests). Fix failures before marking the phase done.
```

If you cannot determine the build/test commands from `CLAUDE.md` or context, ask the user before writing the plan.

### 3. Summary (optional)

Brief 2-3 sentence overview of what the plan accomplishes.

### 4. Design Decisions (optional)

For smaller features without a separate `design.md`, document key technical choices here. If there is a `design.md`, this section captures decisions made *during planning* that aren't in the design doc.

### 5. Phases

Each phase follows this template:

```markdown
---

## Phase N: <Short Title>

**Goal:** One sentence describing the phase's outcome.

### Tasks

- [ ] **N.1** <Task title>
  - File: `path/to/file.ext`
  - What to do, with code snippets if helpful

- [ ] **N.2** <Next task>
  ...

- [ ] **N.X** Build + test gate: `<build-command> && <test-command>` — all tests pass

### Observations

<!-- Agent: write notes here during execution -->
```

### 6. Files Changed Summary

```markdown
---

## Files Changed Summary

### New Files
| File | Phase | Purpose |
|------|-------|---------|

### Modified Files
| File | Phases | Changes |
|------|--------|---------|
```

### 7. Open Questions (optional)

If — and only if — there are genuine ambiguities, missing information, or decisions that could materially affect the plan's success, list them at the end. Do NOT include questions for the sake of completeness or to appear thorough. No questions is the expected default for a well-scoped plan with a clear design document.

```markdown
---

## Open Questions

- <Genuine question that blocks or risks a phase>
```

---

## Phase Design Guidelines

- **One phase = one loop iteration.** Each phase must be granular enough that an agent can complete it well within a single context window, without the system resorting to conversation compression. Context compression degrades performance and causes hallucinations — if a phase is large enough to trigger it, the phase is too large. Err on the side of smaller phases.
- **Build + test gate is the last task in every phase.** Never skip it.
- **Tests belong in the same phase as the code they test.** If tests exist or are part of the plan, they must be written and executed as part of verifying each phase's implementation — not batched into a later "add tests" phase. This applies to both unit and integration tests. Deferring test authoring to later phases masks bugs early and compounds risk.
- **Each phase should leave the codebase in a green state.** All existing tests continue to pass.
- **Task numbering:** `<phase>.<task>` (e.g., 2.3 = Phase 2, Task 3).
- **File paths in tasks:** Always include the file path so the agent doesn't have to search.
- **Code sketches in tasks:** Include implementation sketches for non-obvious logic.
- **Early phases establish scaffolding** that later phases fill in. Don't try to implement everything in Phase 0.
- **The final phase** should include a verification pass: code review, logging review, design compliance check, and a final build + test gate.

## What Makes a Good Phase Boundary

Split on these natural boundaries:
- **Interface then implementation:** Define the interface/contract in one phase, implement it in the next.
- **Core then consumers:** Build the new class/module first, then migrate callers.
- **Infrastructure then features:** Test helpers, configuration, or new abstractions first.
- **One concern per phase:** Don't mix unrelated changes.

## Common Pitfalls

- **Phase too large:** If a phase has more than ~10 tasks, it's probably too big. Split it.
- **Missing test tasks:** Every phase that adds logic needs test tasks.
- **Implicit dependencies:** If Phase 2 depends on a specific decision made in Phase 1, document it explicitly in Phase 2's task descriptions. The agent has no memory between iterations — only the plan file and observations carry context forward.

---

## When done

After creating the plan file, print:

```
Files created/modified:
- ralph/projects/<project-name>/plan.md
```

Then summarize the phases and estimated scope, and confirm the plan is ready to run with `ralph <project-name>`.

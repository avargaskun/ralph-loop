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

## Project extensions

Check for two optional repo-local extension files and read them if present:

1. `ralph/EXTENSIONS.md` — project-specific guidance for the ralph skills, organized in sections named after the skills. Read the `## General` section and the `## Plan` section; ignore all other sections. Treat the content as guidance layered on top of this skill — it extends these instructions and never replaces them. If it conflicts with this skill's protocol (output files, document structure, workflow), this skill wins.
2. `ralph/PROMPT.md` — the project-local addendum appended to execution subagent prompts. It is the most reliable source for this project's build/test commands — prefer commands found there for the build + test gates before asking the user.

Both files are optional — missing files are the normal case; continue silently.

## Prerequisites

Before writing the plan, read:

1. `ralph/projects/<project-name>/design.md` — the source of truth for architecture, trade-offs, and resolved decisions. If this file doesn't exist, ask the user to describe what they want to plan for. Use their description as the basis for the plan, and document key technical choices in the "Design Decisions" section of the plan.
2. Any relevant `CLAUDE.md` files in the repository — for project conventions, build commands, and coding standards.

## Assess design readiness

Before writing phases, judge whether the design lets you produce concrete, non-placeholder tasks. For each section you'll plan against, ask: *could a memory-less agent implement this without re-deriving a decision the design left open?*

Usually the answer is yes — the design is actionable; proceed. Only when a real gap would force you to invent an answer, route it by who can resolve it and where the answer must durably live:

- **Architectural decision you can settle by reading the code** → investigate (use sub-agents for independent areas), decide, and write the decision into `design.md` itself — the durable source of truth every loop iteration re-reads, not the plan. Note any such backfill in your final summary.
- **Cheap assumption verifiable at runtime** → don't guess; make confirming it the first task of the phase that depends on it (see Phase Design Guidelines).
- **Judgment call only the user can make** → leave it as an Open Question rather than inventing an answer.

This is the exception, not the default — the same bar as Open Questions: skip it when the design is actionable as written. Don't investigate to appear thorough.

## Your task

Create `ralph/projects/<project-name>/plan.md` following the structure below. The plan must be complete and concrete — no placeholder tasks, no deferred decisions. (A first-task investigation that resolves a known unknown and records the finding is not a placeholder; a vague "figure out X later" is.)

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

Include this section verbatim (adapt the build/test command to match this project's actual tooling — check `ralph/PROMPT.md` and `CLAUDE.md`, or ask the user if unclear):

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

*Baseline (every phase):* ```<build-command> && <unit-test-command>```

Phases that add or modify integration/E2E tests must also run them. Include any prerequisites (deployment, environment setup) as tasks before the gate, and add the integration test run command to the gate itself. The gate command may differ between phases — it must cover all tests that validate the phase's work.

A phase is **not complete** until the gate succeeds and **all** tests written or modified in that phase have been executed. Fix failures before marking the phase done.
```

If you cannot determine the build/test commands from `ralph/PROMPT.md`, `CLAUDE.md`, or context, ask the user before writing the plan.

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
- **Tests belong in the same phase as the code they test.** For each phase that introduces new behavior, actively consider both test types:
  - **Unit tests** are always expected for new logic.
  - **Integration/E2E tests** should be included in the same phase whenever the behavior is exercisable end-to-end at that point. If integration tests require deployment or environment setup, include those as tasks in the phase.
  - If integration tests for a phase's behavior **cannot** be written yet (e.g., the phase is pure scaffolding with no observable external behavior, or a required layer like the UI isn't built yet), note this explicitly in the phase description and state **which later phase** will add the integration test coverage for this behavior. This creates a traceable obligation rather than a silent omission.
  - Batching all integration tests into a dedicated final phase is the same anti-pattern as batching all unit tests — it delays validation and concentrates debugging risk.
- **Each phase should leave the codebase in a green state.** All existing tests continue to pass.
- **Task numbering:** `<phase>.<task>` (e.g., 2.3 = Phase 2, Task 3).
- **File paths in tasks:** Always include the file path so the agent doesn't have to search.
- **Content-based code references:** When tasks reference specific locations within a file, use content-based descriptions (function name, the code pattern to match) rather than line numbers alone. Line numbers shift as earlier phases modify files, making them unreliable for later phases. Line numbers may be included as supplementary context but should not be the primary identifier. Example: "In `checkParameters`, change `_.isEmpty(x)` to `!x`" rather than "Line 72: change…"
- **Code sketches in tasks:** Include implementation sketches for non-obvious logic.
- **Early phases establish scaffolding** that later phases fill in. Don't try to implement everything in Phase 0.
- **Investigation belongs at the head of a phase, not in its own phase — usually.** When a phase depends on a cheap fact you couldn't verify while planning (an API signature, whether a library supports X), make confirming it task N.1 and have the agent record the result in Observations; the phase's normal build + test gate still applies. Reserve a *standalone* investigation phase only when one finding gates several later phases — such a phase adds no logic, so its gate is the recorded finding plus the baseline build, and it earns its own Observations block that later phases reference.
- **Integration test phases need context room for troubleshooting.** Integration tests interact with deployed systems and have more failure modes than unit tests (network, timing, environment, deployment state). When a phase includes integration tests, keep the implementation work in that phase small enough that the agent has context room to investigate and fix test failures. If a phase has both substantial implementation work and integration tests, consider splitting it: implementation + unit tests in one phase, then integration tests (with deployment) in the next.
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
- **Integration tests batched at the end:** If the plan has a phase titled "Integration Tests" that covers all integration testing for the entire feature, the tests are too far from the code they validate. Integration tests should appear in the phase where the behavior becomes end-to-end testable, not in a catch-all phase at the end. Exception: a project's first integration test may need infrastructure setup (test helpers, SSH utilities, deployment tasks) — this scaffolding can be a dedicated phase, but the tests themselves should be in the phase where the tested behavior is introduced.

---

## When done

After creating the plan file, print:

```
Files created/modified:
- ralph/projects/<project-name>/plan.md
```

Then summarize the phases and estimated scope, and confirm the plan is ready to run with `ralph <project-name>`.

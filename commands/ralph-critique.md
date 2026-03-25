ultrathink

You are going to critically review a Ralph project's design and/or plan *before execution begins*. You read the documents, analyze the actual codebase to understand what is being changed, and produce a critique that surfaces unsound logic, wrong assumptions, ambiguity, and gaps. This is the quality gate between planning and execution.

## Project name and input

Parse `$ARGUMENTS` as follows:
- The **first word** is the project name (the folder name under `ralph/projects/`).
- Everything **after the first word** is additional context provided by the user — treat it as supplementary input for the critique (e.g., areas of concern, specific things to scrutinize).

If `$ARGUMENTS` is empty, ask the user: "What is the project name? (The folder name under `ralph/projects/`)"

## Bootstrap

Before creating any files, ensure the required directory structure exists:

```
ralph/
└── projects/
    └── <project-name>/
```

Create these directories if they do not exist. Do NOT error out or stop — just create them silently and continue.

## What to review

Determine the review scope and output file:

1. If `ralph/projects/<project-name>/plan.md` exists, review it. If the plan references a `design.md`, review that too. Output file: **`plan-critique.md`**.
2. If there is no `plan.md`, review `ralph/projects/<project-name>/design.md`. If it doesn't exist either, ask the user what to review. Output file: **`design-critique.md`**.

## Your task

Produce the output file (either `ralph/projects/<project-name>/plan-critique.md` or `ralph/projects/<project-name>/design-critique.md`) by following the methodology below in order. Do not skip steps.

---

## Review Methodology

### Step 1: Read the documents

Read all documents in scope (plan and/or design) in full before writing anything.

### Step 2: Analyze the codebase

This is the most important step. The documents make claims about existing code — verify them:

- **Read every file referenced** in the design's "Files Changed" or the plan's "Files Changed Summary." Read the full file, not just the area mentioned.
- **Trace the code paths** that the design/plan proposes to modify. Understand the current behavior before evaluating the proposed changes.
- **Check assumptions** the documents make about the codebase (e.g., "this method currently does X," "this class has Y responsibility"). Are they accurate?

### Step 3: Evaluate soundness

With the code fresh in mind, evaluate:

- **Logic and math** — are calculations, conditions, and algorithms correct? Walk through concrete examples with real values.
- **Completeness** — are there code paths, states, or interactions the documents don't account for?
- **Consistency** — do different sections of the documents contradict each other? Does the plan match the design?
- **Assumptions** — are there unstated assumptions that could be wrong? Does the design assume something about the runtime, data shape, or concurrency model that the code doesn't guarantee?
- **Edge cases** — what happens at boundaries? Empty collections, null values, concurrent access, first-run vs. steady-state, error during partial completion.

### Step 4: Evaluate the plan (if reviewing plan.md)

Beyond the design-level concerns, check the plan's structure:

- **Phase scoping** — is each phase small enough for a single loop iteration? Could any phase trigger context compression?
- **Phase ordering** — are dependencies between phases correctly sequenced? Could a phase fail because something it needs isn't built yet?
- **Test coverage** — does each phase include tests for the behavior it introduces? Are integration tests placed in the right phases?
- **Gate commands** — are build/test gates appropriate for each phase? Do phases with integration tests include the right gate commands?
- **Missing tasks** — are there implementation steps implied by the design that the plan doesn't cover?

---

## Critique Document Structure

Write the output file with this structure:

```markdown
# <Project Title> — Pre-Execution Critique

> **Documents reviewed:** <list: design.md, plan.md>
> **Reviewer:** <your model name>
> **Date:** YYYY-MM-DD

---

## Summary

2-3 sentences: what is being proposed and your overall assessment of readiness for execution.

---

## Findings

### Critical

Issues that will likely cause execution failure, incorrect behavior, or wasted iterations if not addressed before starting. Examples: wrong assumptions about existing code, incorrect logic, missing error handling for likely scenarios, phases that depend on work not yet done.

### Important

Issues that won't block execution but will degrade quality or require rework. Examples: ambiguous task descriptions the agent will interpret inconsistently, edge cases not covered, phases that are too large.

### Suggestions

Observations that could improve the design or plan but are not problems per se. Be sparing — include only suggestions with clear, concrete value.
```

### Finding format

Each finding should include:

1. A clear title describing the issue.
2. The specific section/phase in the document where the issue is.
3. What the document says or assumes.
4. What the code actually does or what the correct analysis is.
5. A concrete suggestion for how to fix it.

---

## Tone and Calibration

- **Be critical, but not nitpicky.** Focus on issues that would cause real problems during execution — wrong logic, bad assumptions, missing steps. Don't flag style preferences, naming choices, or minor wording issues in the documents.
- **Ground findings in the code.** Every finding about the design or plan should reference the actual code that contradicts or complicates what the document says. If you can't point to a specific file and line, the finding may not be substantive.
- **No false positives.** If something looks questionable but you've verified it's actually correct, don't include it. An empty findings section is a valid outcome.

---

## What the Critique Is NOT

- **Not a re-design.** Point out problems and suggest fixes, but don't rewrite the design. The user will iterate on the documents themselves after reading your findings.
- **Not a code review.** You're reviewing the *plan for changes*, not existing code quality. Only discuss existing code to the extent it affects the soundness of the proposed changes.
- **Not exhaustive.** Focus on the most impactful issues. A critique with 3 critical findings is more useful than one with 20 trivial ones.

---

## When done

After creating the critique file, print:

```
Files created/modified:
- ralph/projects/<project-name>/<design-critique.md or plan-critique.md>
```

Then summarize the finding counts by severity and highlight the most important one.

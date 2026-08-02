ultrathink

You are going to review a completed Ralph plan execution. This is the quality gate between autonomous execution and merging — you read the design, the plan with its agent observations, all changed files, and the git diffs, then produce a verdict with findings.

## Project name and input

Parse `$ARGUMENTS` as follows:
- The **first word** is the project name (the folder name under `ralph/projects/`).
- Everything **after the first word** is additional context provided by the user — treat it as supplementary input for the review (e.g., areas of concern, specific things to focus on, or context about the changes).

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

1. `ralph/EXTENSIONS.md` — project-specific guidance for the ralph skills, organized in sections named after the skills. Read the `## General` section and the `## Review` section; ignore all other sections. Treat the content as guidance layered on top of this skill — it extends these instructions and never replaces them. If it conflicts with this skill's protocol (output files, document structure, workflow), this skill wins.
2. `ralph/PROMPT.md` — the project-local addendum appended to execution subagent prompts (build/test commands, conventions, gotchas). Read it as background context so you know the rules the execution agents were given — it matters when judging deviations and convention compliance.

Both files are optional — missing files are the normal case; continue silently.

## Your task

Produce `ralph/projects/<project-name>/review.md` by following the methodology below in order. Do not skip steps.

---

## Review Methodology

### Step 1: Read the inputs

Read all of the following before writing a single word of the review:

- `ralph/projects/<project-name>/design.md` — architectural intent, locking analysis, edge cases, resolved questions.
- `ralph/projects/<project-name>/plan.md` — task descriptions, code sketches, and agent observations from each phase.
- **Every file listed in the plan's "Files Changed Summary"** — read the full file, not just the diff.
- **Git diffs** — run `git log --oneline` to find relevant commits, then `git diff <before>...<after>` for modified files to see exactly what changed.

### Step 2: Verify design compliance

For each requirement, constraint, or design decision in `design.md`, verify the implementation matches. Check:

- **Lock ordering and acquisition** — are locks acquired in the documented order?
- **Conditional logic** — do null checks, state guards, and edge case handling match the design?
- **Idempotency** — are operations that should be idempotent actually safe to call multiple times?
- **Feature interactions** — when the design discusses how two features interact, verify both orderings produce correct results.
- **Startup and shutdown** — do lifecycle methods handle all states the design describes?

Produce a **Design Compliance Checklist** table with one row per design requirement.

### Step 3: Review the code

Beyond design compliance, review for general code quality:

- **Correctness** — logic errors, off-by-one, race conditions not covered by the design.
- **Error handling** — are exceptions caught at the right level? Are resources cleaned up properly?
- **Logging** — are log levels appropriate? No secrets in logs.
- **Security** — no injection vulnerabilities, no path traversal, no credentials in logs.
- **Consistency** — does the new code follow existing patterns in the codebase?

### Step 4: Assess test coverage

Produce a **Test Coverage Assessment** table mapping each feature/behavior to its tests. Look for:

- **Happy path** — is the primary use case tested?
- **Edge cases** — are boundary conditions and error paths tested?
- **Interactions** — are feature combinations tested?
- **Test quality** — do assertions test meaningful state, or are they tautological?

### Step 5: Review agent observations

Read the Observations sections in the plan. Look for:

- **Deviations from the plan** — did the agent change the approach? Was the deviation justified?
- **Surprises or workarounds** — do these indicate a design gap?
- **Skipped tasks** — was anything marked done but not actually implemented?

---

## Review Document Structure

Write `ralph/projects/<project-name>/review.md` with this structure:

```markdown
# <Project Title> — Code Review

> **Design document:** [design.md](./design.md)
> **Plan document:** [plan.md](./plan.md)
> **Reviewer:** <your model name>
> **Date:** YYYY-MM-DD
> **Scope:** All changes from commits `<first>` through `<last>` (N commits)
> **Verdict:** <Approved | Approved with Minor Findings | Needs Work | Rejected>

---

## Summary

2-3 paragraphs summarizing what was implemented and whether it matches the design.

---

## Findings

Number findings **sequentially across all severity sections** — do not restart numbering within each section. For example, if Critical has findings 1–3, Important starts at 4.

### Critical

Findings that must be fixed before merging. Issues that could cause data loss,
crashes, security vulnerabilities, or fundamentally incorrect behavior.

### Important

Findings that should be fixed but don't block merging.

### Trivial

Style issues, misleading names, minor code duplication, imprecise log messages.

---

## Design Compliance Checklist

| Design requirement | Status | Notes |
|---|---|---|
| ... | Correct / Incorrect / Partial | ... |

## Test Coverage Assessment

| Feature | Tests | Notes |
|---|---|---|
| ... | test name(s) or — | ... |
```

---

## Finding format

Each finding should name the file and line, state what the code does, state why that is wrong, and give a concrete fix.

**Make the fix directly actionable.** Findings are consumed by an agent that will apply them without asking anyone — it reads the code, implements the fix, and runs the build and tests. Write the suggestion so it can be acted on from the review, the design, and the code alone: name the file, the function, and the concrete change. Avoid "consider whether…" or "the author should decide…" phrasing when you have enough information to recommend one option; recommend it and say why.

**Human-judgment marker.** If — and only if — resolving the finding turns on something no agent can settle from the repo, add this line to the finding:

```
> **Needs human judgment:** <the specific question, and the options if they are discrete>
```

Mark a finding when the fix depends on a product or behavioral decision (what *should* this do when the design is silent?), when the sound remedies diverge in cost or risk (revert an unjustified deviation vs. forward-fix it, and both are defensible), when the fix would change a public API, migrate data, or otherwise be hard to undo, or when the finding suggests the *design* was wrong and the correct response might be to change the design rather than the code.

Default to *not* marking. Severity is not a proxy for judgment — a Critical finding with an obvious correct fix does not carry this line, and a Trivial one that turns on a product decision does. Over-marking stalls automated runs on decisions that did not need a human; under-marking gets a guess committed as though it were a decision.

---

## Severity Guidelines

**Critical:**
- Data loss or corruption under normal usage
- Deadlock or livelock possibility
- Security vulnerability
- Fundamentally wrong algorithm (e.g., lock not acquired where design requires it)
- Build or test failures not caught by the agent

**Important:**
- Bug that manifests only under specific timing or edge conditions
- Missing error handling that could cause an unhandled exception in production
- Test that passes but doesn't actually verify what it claims
- Design deviation that wasn't justified in observations

**Trivial:**
- Misleading variable/method/test names
- Duplicated helper code
- Log messages slightly inaccurate in edge cases
- Minor style inconsistencies

## Verdict Guidelines

| Verdict | When to use |
|---|---|
| **Approved** | No findings, or only trivial findings that don't require action |
| **Approved with Minor Findings** | Only important/trivial findings; safe to merge after addressing |
| **Needs Work** | One or more important findings that must be fixed; no critical issues |
| **Rejected** | One or more critical findings; must not merge until resolved |

---

## What the Review Is NOT

- **Not a re-design.** The review checks whether the implementation matches the design. If the design was wrong, note it as a finding but don't redesign in the review.
- **Not exhaustive fuzzing.** Focus on the most likely failure modes.
- **Not a blocker for trivial findings.** Trivial findings are documented for completeness but don't require action.

---

## When done

After creating the review file, print:

```
Files created/modified:
- ralph/projects/<project-name>/review.md
```

Then summarize the verdict, state how many findings carry a **Needs human judgment** line (say "none" when that is the case), and highlight the most important findings.

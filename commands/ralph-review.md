ultrathink

You are going to review a completed Ralph plan execution. This is the quality gate between autonomous execution and merging — you read the design, the plan with its agent observations, all changed files, and the git diffs, then produce a verdict with findings.

## Project name

The project name is: **$ARGUMENTS**

If `$ARGUMENTS` is empty, ask the user: "What is the project name? (The folder name under `ralph/projects/`)"

## Bootstrap

Before creating any files, ensure the required directory structure exists:

```
ralph/
└── projects/
    └── <project-name>/
```

Create these directories if they do not exist. Do NOT error out or stop — just create them silently and continue.

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

Then summarize the verdict and the most important findings.

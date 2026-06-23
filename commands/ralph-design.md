ultrathink

You are going to create a design specification for a Ralph project. This is a structured document that captures the *what* and *why* of a feature — architecture, trade-offs, and resolved questions — written for a code agent that will execute it one phase at a time with no memory between iterations.

## Project name and input

Parse `$ARGUMENTS` as follows:
- The **first word** is the project name (the folder name under `ralph/projects/`, lowercase, hyphenated). Example: "partitioned-history-db".
- Everything **after the first word** is additional context provided by the user — treat it as the user's description of what they want designed. Use this text to inform the design document and to reduce the number of clarifying questions you need to ask.

If `$ARGUMENTS` is empty, ask the user: "What is the project name? (This will be the folder name under `ralph/projects/`)"

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

1. `ralph/EXTENSIONS.md` — project-specific guidance for the ralph skills, organized in sections named after the skills. Read the `## General` section and the `## Design` section; ignore all other sections. Treat the content as guidance layered on top of this skill — it extends these instructions and never replaces them. If it conflicts with this skill's protocol (output files, document structure, workflow), this skill wins.
2. `ralph/PROMPT.md` — the project-local addendum appended to execution subagent prompts (build/test commands, conventions, gotchas). Read it as background context so the design stays consistent with the rules the execution agents will follow.

Both files are optional — missing files are the normal case; continue silently.

## Prior exploration

Check if `ralph/projects/<project-name>/explore.md` exists. If it does, read it in full before writing anything. The exploration document contains codebase context, a strawman proposal, alternatives analysis, resolved and open questions, risks, and scope boundaries from an earlier brainstorming session. Use it to:

- **Start from the strawman.** Use it as the basis for the design rather than starting from scratch. The user has already reacted to it and refined it.
- **Incorporate resolved questions.** Decisions made during exploration should flow into the design as settled choices, not be re-opened as open questions.
- **Carry forward risks and scope boundaries.** The risk assessment and scope sketch should inform the design's edge case handling and "what stays the same" sections.

The exploration is input, not a substitute for your own analysis. The codebase may have changed since the exploration was written — verify claims about existing code rather than trusting them blindly. Do your own investigation of the code paths you'll be designing against; use the exploration's codebase context as a starting point, not a final answer.

## Your task

Create `ralph/projects/<project-name>/design.md` following the structure below. Engage with the user interactively: ask clarifying questions, surface trade-offs, and refine the document based on their responses. The design is ready when all Open Questions are marked `_Resolved_`.

---

## Design Document Structure

### 1. Header

```markdown
# <Project Title> — Design Specification

> **Status:** Draft
> **Date:** YYYY-MM-DD
```

### 2. Goal

One to three sentences stating what this design achieves and why it matters. Focus on the user-visible or system-level outcome, not implementation details.

### 3. Current State

Describe the relevant parts of the system as they exist today:

- **What exists:** Components, data flows, configurations involved.
- **Problems:** Numbered list of concrete, observable issues this design solves.

Use tables for structured comparisons (current vs. new, before vs. after).

### 4. Design Sections

The core of the document. Organize by feature, component, or concern — whatever makes the design easiest to follow. Each section should include enough detail for an agent to implement without guessing intent:

- **Data flow or lifecycle diagrams** in pseudocode or ASCII — show the sequence of operations and state transitions.
- **Locking/concurrency analysis** when the change touches shared state — state which locks are needed, why, and the ordering. Explicitly call out locks that are *not* needed and why.
- **Edge cases and error handling** — what happens when something is missing, corrupt, or racing?
- **Code sketches** for non-obvious implementations — class signatures, key method outlines, SQL statements. The agent can deviate but needs a starting point.

### 5. Interaction with Existing Code

When the design modifies existing components, document:

- **What changes** in each affected file/method.
- **What stays the same** — explicitly noting unchanged behavior prevents the agent from accidentally refactoring working code.
- **Migration path** if there's a transition from old to new behavior.

### 6. Test Plan

Before writing this section, inspect the project's existing test infrastructure:

- **Test framework and runner** — what tool runs tests (e.g., pytest, jest, go test, cargo test)? Check config files, `package.json` scripts, `Makefile` targets, CI workflows, etc.
- **Directory layout and naming** — where do test files live? What naming convention do they follow (e.g., `test_*.py`, `*.test.ts`, `*_test.go`)?
- **Patterns and utilities** — are there shared fixtures, factories, helpers, or base classes? What mocking/stubbing approach does the project use?
- **Coverage and CI** — are there coverage thresholds, linting rules, or CI gates that tests must satisfy?

If the project has no test infrastructure yet, note that explicitly and recommend a minimal setup consistent with the project's language and tooling.

Ground all test suggestions in what you find. Propose tests that follow the project's existing conventions — same framework, same directory structure, same patterns.

Enumerate the tests required to validate this design. Group by type:

- **Unit tests** — individual functions/methods in isolation.
- **Integration tests** — interactions between components, database queries, API calls.

Within each type, cover the following concerns as applicable:

- **Happy path** — expected inputs produce correct outputs.
- **Edge cases** — boundary conditions, error paths, malformed input, concurrency races.
- **Backward compatibility** — when the design changes existing behavior, verify that unchanged contracts still hold.

For each test, state:
- The file where it belongs (new or existing test file).
- What it asserts, in one sentence.
- Any fixtures, mocks, or setup it requires.

Omit types or concerns that don't apply to the design.

### 7. Files Changed

Summary table of all files that will be created or modified (including test files from the Test Plan above):

```markdown
## Files Changed

| File | Change |
|------|--------|
| `src/path/to/File.ext` | Add new method, update existing method |
| `src/path/to/NewClass.ext` | **New file.** Description of purpose |
```

### 8. Open Questions

After the first draft, list questions and concerns that need the user's input before the design is finalized:

```markdown
## Open Questions

1. **Should we migrate existing data?**
   _Resolved:_ No — both tables are ephemeral. Accept data loss on upgrade.

2. **Should the retry limit be configurable?**
   _(Open)_
```

Guidelines for good questions:
- **Surface trade-offs** — when there are multiple valid approaches, present the options and ask which the user prefers.
- **Flag data loss or breaking changes** — anything that could lose user data or break backward compatibility.
- **Call out assumptions** — if the design assumes something unconfirmed, ask.
- **Don't ask what you can answer** — research implementation mechanics and answer them yourself.

---

## Writing Guidelines

- **Be specific, not abstract.** "Acquire the write lock, close the connection, delete expired files, rebuild" is better than "clean up and refresh."
- **Name things early.** Decide on method names, property names, and file names in the design. The plan and the agent will use these names directly.
- **Document what you decided *not* to do.** If you considered an approach and rejected it, a brief note prevents the agent from rediscovering it.
- **Use tables for comparisons.** Current vs. new, option A vs. option B, before vs. after.
- **Keep the audience in mind.** The primary reader is a code agent executing one phase at a time with no memory between iterations. Everything it needs to make correct architectural decisions must be in this document or the plan's observations.
- **Concrete enough to plan against.** Before declaring the design done, check each section: could `/ralph-plan` write non-placeholder tasks against it without inventing an architectural decision? Where it couldn't, resolve the decision here now — backfilling it during planning is more expensive and easier to get wrong.

---

## When done

After creating or updating the design file, print:

```
Files created/modified:
- ralph/projects/<project-name>/design.md
```

Then summarize the key design decisions and list any Open Questions that still need the user's input.

ultrathink

You are going to create a design specification for a Ralph project. This is a structured document that captures the *what* and *why* of a feature — architecture, trade-offs, and resolved questions — written for a code agent that will execute it one phase at a time with no memory between iterations.

## Project name

The project name is: **$ARGUMENTS**

If `$ARGUMENTS` is empty, ask the user: "What is the project name? (This will be the folder name under `ralph/projects/`)"

Use the project name as the folder name (lowercase, hyphenated). Example: "partitioned-history-db".

## Bootstrap

Before creating any files, ensure the required directory structure exists:

```
ralph/
└── projects/
    └── <project-name>/
```

Create these directories if they do not exist. Do NOT error out or stop — just create them silently and continue.

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

### 6. Files Changed

Summary table of all files that will be created or modified:

```markdown
## Files Changed

| File | Change |
|------|--------|
| `src/path/to/File.ext` | Add new method, update existing method |
| `src/path/to/NewClass.ext` | **New file.** Description of purpose |
```

### 7. Open Questions

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

---

## When done

After creating or updating the design file, print:

```
Files created/modified:
- ralph/projects/<project-name>/design.md
```

Then summarize the key design decisions and list any Open Questions that still need the user's input.

ultrathink

You are going to explore and brainstorm an idea for a Ralph project. This is the divergent-thinking phase — you expand the option space, surface unknowns, and map the terrain *before* any design decisions are committed. The output is a lightweight briefing document that feeds into `/ralph-design`.

## Project name and input

Parse `$ARGUMENTS` as follows:
- The **first word** is the project name (the folder name under `ralph/projects/`, lowercase, hyphenated). Example: "partitioned-history-db".
- Everything **after the first word** is the user's description of their idea — what they want to build, change, or investigate. This is your starting point for exploration.

If `$ARGUMENTS` is empty, ask the user: "What is the project name and idea? (First word is the folder name under `ralph/projects/`, the rest is your idea)"

## Bootstrap

Before creating any files, ensure the required directory structure exists:

```
ralph/
└── projects/
    └── <project-name>/
```

Create these directories if they do not exist. Do NOT error out or stop — just create them silently and continue.

## Your task

Explore the idea through deep codebase analysis, produce `ralph/projects/<project-name>/explore.md` as a structured briefing, and then engage the user interactively to resolve questions and refine the direction. The exploration is ready when the user is satisfied and wants to move to `/ralph-design`.

---

## Exploration Methodology

### Step 1: Understand the idea

Before touching the codebase, restate the idea in your own words. Identify:
- What is the user trying to achieve? (the outcome, not the implementation)
- What are the implicit assumptions in how they described it?
- What do you *not* know that you need to find out from the codebase or the user?

### Step 2: Deep codebase exploration

This is the most important step. Explore broadly — the goal is to build a mental model of the relevant parts of the system so the strawman proposal is grounded in reality, not invented from first principles.

Investigate:
- **Relevant code paths** — trace the flows that the idea would touch or extend. Read the actual implementations, not just interfaces.
- **Adjacent features** — what exists today that is similar to or overlaps with the idea? Could an existing mechanism be extended rather than building something new?
- **Patterns and conventions** — how does the codebase handle similar concerns? (error handling, configuration, data flow, testing patterns). The strawman should work *with* these patterns, not against them.
- **Documentation and configuration** — `CLAUDE.md` files, READMEs, config files, CI/CD setup. These reveal constraints and conventions that code alone doesn't.
- **Dependencies** — what external libraries, APIs, or services are involved? What are their capabilities and limitations?
- **Test infrastructure** — how is similar functionality tested? What test utilities exist? This informs feasibility of the testing approach.

Use sub-agents for parallel exploration when investigating independent areas of the codebase. Cast a wide net — it's better to explore something irrelevant than to miss something important.

### Step 3: Produce the briefing

Create `ralph/projects/<project-name>/explore.md` following the structure below.

### Step 4: Interactive refinement

After producing the initial briefing, engage the user in conversation:
- Walk them through the strawman and key alternatives
- Ask the open questions — prioritize the ones that most affect scope and approach
- Refine the document as decisions are made during conversation
- Help the user draw the scope boundary — what's in, what's out, what's deferred

This is a working session, not a report handoff. Update `explore.md` as the conversation progresses.

---

## Briefing Document Structure

```markdown
# <Project Title> — Exploration

> **Status:** In progress
> **Date:** YYYY-MM-DD
```

### 1. Idea

Restate the idea as you understand it. One to three sentences focused on the *outcome* the user wants, not implementation details. Call out any assumptions you're making about intent.

### 2. Codebase Context

What you discovered during exploration that is relevant to the idea. This section grounds the rest of the document in reality. Organize by concern, not by file:

- **What exists today** — components, patterns, and data flows that the idea would interact with. Be specific: name the files, classes, and methods.
- **Adjacent features** — similar or overlapping functionality already in the codebase. Note whether these could be extended or must be worked around.
- **Constraints discovered** — things the code or infrastructure impose that the idea must respect (e.g., "the plugin system doesn't support async initialization," "all API routes go through middleware X").

### 3. Strawman

A concrete, opinionated first-cut proposal. Not the "right" answer — a starting point to react to. Include enough detail that someone could agree or disagree with specific choices:

- What would be built or changed
- How it fits into the existing architecture
- Key implementation approach

The strawman should be the simplest approach that could work. Complexity can be added during design if needed.

### 4. Alternatives

Other approaches that were considered. Present as a comparison — each alternative should be evaluated against the strawman, not in isolation.

For each alternative:
- **Approach** — what would be different from the strawman
- **Pros** — where this approach is better
- **Cons** — where this approach is worse or riskier
- **When to prefer** — under what conditions this would be the right choice

Use a table for quick comparison when there are 3+ alternatives. Include the "do nothing" option when it's a genuine possibility — sometimes exploration reveals that the status quo is acceptable or that the problem is smaller than assumed.

### 5. Open Questions

Things that need the user's input before a design can be written. Group by impact:

**Scope-defining** — answers that materially change what gets built:
- Questions here determine whether entire sections of the design exist or not

**Approach-defining** — answers that change *how* it gets built:
- Questions here choose between the strawman and alternatives

**Detail-level** — answers needed for the design but that don't change the overall shape:
- These can often wait until the design phase

For each question, state what you'd assume if the user doesn't have a strong opinion. This prevents questions from becoming blockers.

### 6. Risks

Potential problems, ordered by severity:

- **Show-stoppers** — issues that could make the idea infeasible. If you found any, lead with them — don't bury bad news.
- **High-risk areas** — parts of the approach where things are most likely to go wrong, take longer than expected, or require rework. Explain *why* the risk exists (not just that it does).
- **Unknowns** — things you couldn't determine from the codebase alone that could affect feasibility.

### 7. Scope Sketch

A rough boundary to start from — not final, but a stake in the ground:

- **In scope** — what the first version would include
- **Out of scope** — what is explicitly deferred (and why)
- **Complexity signal** — rough sense of scale. Is this a 3-phase plan or a 15-phase plan? What drives the complexity?

---

## Writing Guidelines

- **Be concrete, not hand-wavy.** "The `EventBus` class in `src/events/bus.ts` dispatches synchronously, so adding async subscribers would require changing the dispatch loop" is useful. "There might be event handling concerns" is not.
- **Show your work.** When you reference codebase context, include the file path and enough detail that the user can verify your understanding without re-reading the file themselves.
- **Opinionated strawman, balanced alternatives.** The strawman should take a clear position. The alternatives section is where balance lives.
- **Surface the non-obvious.** The user already knows their idea. Your value is in what the codebase reveals that they don't know yet — constraints, adjacent features, hidden complexity, simpler paths.
- **Resolve the obvious, preserve the genuinely ambiguous.** If exploration clearly shows one answer, state it as a recommendation rather than posing it as an open question. Reserve open questions for things where reasonable people would disagree or where only the user has the context to decide.

---

## When done

After creating or updating the exploration file, print:

```
Files created/modified:
- ralph/projects/<project-name>/explore.md
```

Then summarize the strawman in 2-3 sentences and highlight the most important open questions or risks that need the user's input before moving to `/ralph-design`.

# ralph-loop — Design Specification

> **Status:** Draft
> **Date:** 2026-03-11

## Goal

`ralph-loop` is a portable, shareable agentic development framework for Claude Code. It implements the "Ralph" playbook: a phase-by-phase plan executor where Claude autonomously works through a structured plan one phase at a time, committing after each one.

The project ships as a GitHub repository that users install once to their home directory. After installation, the loop CLI and seven interactive guide skills are available in every project on their machine — no per-project file copying required.

---

## Background & Problem Statement

The original Ralph implementation lives inside each project repository as a `ralph/` folder containing shell scripts, prompt templates, and guide documents. This has two problems:

1. **Not portable.** Every new project requires manually copying the entire `ralph/` folder. Updates to the framework must be propagated to each copy by hand.
2. **Not shareable.** There is no canonical distribution point. Other developers cannot adopt the playbook without receiving a copy from someone who already has it.

The goal of this project is to extract Ralph into a standalone, installable tool that any developer can install once and use everywhere.

---

## Architecture

Ralph-loop has two distinct functional layers that require different distribution mechanisms:

### Layer 1 — Interactive Guide Phases

The Design, Plan, Critique, Review, and Address phases are human-in-the-loop activities: the developer invokes a Claude Code slash command, Claude produces an artifact (a design doc, a plan, a critique, a review), and the developer reads and refines it interactively.

These phases map naturally to **Claude Code skills** — markdown prompt files stored in `~/.claude/commands/`. A skill is invoked with `/skill-name` in any Claude Code conversation and expands to the full prompt, with no per-project files needed.

**Skills:**
| Command | Purpose |
|---|---|
| `/ralph-explore` | Guide Claude to explore an idea and produce a briefing for design |
| `/ralph-design` | Guide Claude to produce a design specification |
| `/ralph-plan` | Guide Claude to produce a phased execution plan |
| `/ralph-critique` | Guide Claude to critically review design/plan before execution |
| `/ralph-review` | Guide Claude to review completed implementation |
| `/ralph-address` | Guide Claude to fix findings from a review |
| `/ralph-auto` | Coordinate the full design → plan → critique → loop → review flow |

### Layer 2 — Autonomous Loop

The Execute phase is fully automated: a shell script invokes `claude -p` headlessly in a loop, feeding it the plan and waiting for signals. This cannot be a skill because it runs *outside* of Claude, calling it as a subprocess.

**CLI tools:**
| Command | Purpose |
|---|---|
| `ralph <project> [max_iter]` | Run the phase-by-phase execution loop |
| `ralph-follow` | Tail and format the current iteration's JSONL log |

For users who cannot run external scripts (SSO-authenticated Claude Code, PortKey API keys), the `/ralph-loop` skill runs the same loop in-session by spawning sequential subagents from the current conversation.

---

## Installation Design

### No `sudo` Required

Everything installs to user-level locations. The installer never touches system directories.

| What | Where |
|---|---|
| CLI scripts | `~/.ralph/bin/` |
| Bundled prompt template | `~/.ralph/PROMPT.md` |
| Skill guide files | `~/.ralph/commands/` |
| Skill symlinks | `~/.claude/commands/ralph-*.md → ~/.ralph/commands/ralph-*.md` |

`~/.ralph/` is a git clone of this repository. The PATH entry (`~/.ralph/bin`) is appended to `~/.zshrc` (or `~/.bash_profile` / `~/.profile`) once by `install.sh`.

### Install

```bash
git clone https://github.com/<owner>/ralph-loop ~/.ralph
~/.ralph/install.sh
# Open a new shell (or source your RC file)
```

`install.sh` does exactly three things:
1. Creates `~/.ralph/bin/` symlinks (or copies) for `ralph` and `ralph-follow`
2. Creates symlinks `~/.claude/commands/ralph-*.md → ~/.ralph/commands/ralph-*.md`
3. Appends `export PATH="$HOME/.ralph/bin:$PATH"` to the user's shell RC file, guarded by a duplicate-entry check

### Update

```bash
cd ~/.ralph && git pull
```

Because `~/.claude/commands/ralph-*.md` are symlinks pointing into `~/.ralph/commands/`, a `git pull` in `~/.ralph` updates the skills automatically — no reinstall step needed. The CLI scripts update in-place for the same reason.

Optionally, `ralph update` can be a convenience alias for the above.

### Rollback

```bash
cd ~/.ralph && git checkout v1.2.0
```

---

## Repository Structure (installed at `~/.ralph/`)

```
~/.ralph/
├── install.sh              # One-time setup script
├── PROMPT.md               # Bundled generic loop prompt template
├── bin/
│   ├── ralph               # Loop script (loop.sh)
│   └── ralph-follow        # Log follower/formatter
└── commands/               # Claude Code skill files
    ├── ralph-explore.md
    ├── ralph-design.md
    ├── ralph-plan.md
    ├── ralph-critique.md
    ├── ralph-loop.md
    ├── ralph-review.md
    ├── ralph-address.md
    └── ralph-auto.md
```

---

## Per-Project Structure

After installation, projects using ralph-loop only need:

```
<repo-root>/
└── ralph/
    ├── PROMPT.md           # OPTIONAL: project-specific addendum (see below)
    ├── EXTENSIONS.md       # OPTIONAL: per-skill guidance for authoring/review skills (see below)
    ├── projects/
    │   └── <project-name>/
    │       ├── explore.md  # Created during /ralph-explore phase (optional)
    │       ├── design.md   # Created during /ralph-design phase
    │       ├── plan.md     # Created during /ralph-plan phase
    │       ├── design-critique.md  # Created by /ralph-critique (design only)
    │       ├── plan-critique.md    # Created by /ralph-critique (plan + design)
    │       └── review.md   # Created during /ralph-review phase
    └── logs/               # Auto-created; gitignored
```

No scripts, no guide documents, no prompt templates. Only project artifacts.

---

## PROMPT.md: Bundled Generic + Optional Addendum

The loop prompt (`PROMPT.md`) is split into two parts:

### 1. Bundled Generic Prompt (`~/.ralph/PROMPT.md`)

Ships with the repository. Contains all loop-protocol instructions that are project-agnostic:
- How to read plan and design files
- How to find and execute the next unchecked phase
- How to handle prior phase observations
- Build-and-test discipline (read before write, no placeholders)
- Long-running command handling (background tasks, polling, 20-minute ceiling)
- Context window management (stop early, commit, emit signal)
- How to record observations in the plan file
- Commit conventions (`Phase N: <message>`, no push, check for detached HEAD)
- Signal protocol (`RALPH_PHASE_COMPLETE` / `RALPH_ALL_COMPLETE`)

Placeholder tokens `{{DESIGN_FILE}}` and `{{PLAN_FILE}}` are substituted at runtime by the `ralph` script.

### 2. Project-Local Addendum (`ralph/PROMPT.md` in the repo)

An **optional** file that project maintainers commit to their repository. It is appended to the bundled generic prompt at runtime, after a `---` separator and a `## Project-Specific Instructions` heading. It does NOT replace the generic prompt.

**What belongs in the addendum:**
- Build system commands (e.g., `npm run gulp -- build --agent`)
- Framework-specific conventions (e.g., "register new .cs files in Plugin.csproj")
- Project-specific gotchas (e.g., "do not modify AssemblyInfo.cs directly")
- Tool flags required for the environment (e.g., `--agent` for sandboxed builds)

**What does NOT belong in the addendum:**
- Loop protocol instructions (already in the generic prompt)
- Signal handling or commit conventions (already covered)

If `ralph/PROMPT.md` is absent, the loop runs with only the generic prompt. This is the correct behavior for most projects.

The addendum is also read **as background context** (not appended) by the authoring/review skills (`/ralph-explore`, `/ralph-design`, `/ralph-plan`, `/ralph-critique`, `/ralph-review`, `/ralph-address`), so shared facts such as build/test commands are written once and seen by every phase of the SDLC.

### 3. Per-Skill Extensions (`ralph/EXTENSIONS.md` in the repo)

An **optional** file that extends the authoring/review skills the same way the addendum extends the executor. Two different consumption models drive the two-file split:

- The executor path consumes its extension by **verbatim prompt injection** (including via a plain shell script), so `ralph/PROMPT.md` stays a whole-file contract with no internal structure to parse.
- The interactive skills are **intelligent readers**, so `ralph/EXTENSIONS.md` can be one shared file organized in sections — each skill reads `## General` plus the section matching its name (`## Explore`, `## Design`, `## Plan`, `## Critique`, `## Review`, `## Address`, `## Auto`) and ignores the rest.

Rules, mirroring the addendum:

- **Extends, never replaces.** Section content is guidance layered on the skill; protocol (output files, document structures, signals, commit conventions) stays owned by the bundled skills so `git pull` upgrades keep propagating.
- **Never injected into executors.** Execution subagents receive only `ralph/PROMPT.md`. This keeps loop iterations lean and prevents authoring/review guidance from causing executor scope creep.
- **Boundary with `CLAUDE.md`.** Guidance that applies to all Claude work in the repo belongs in `CLAUDE.md`. `EXTENSIONS.md` is only for ralph-phase-specific guidance (e.g., "designs must include a rollout section", "reviews must check the accessibility checklist").
- Missing file or missing section is the normal case.

### Runtime Composition (pseudocode)

```bash
PROMPT = substitute_placeholders(bundled_PROMPT_md, design_path, plan_path)

if repo_local_addendum_exists:
    PROMPT += "\n\n---\n\n## Project-Specific Instructions\n\n" + addendum_contents

pipe PROMPT into: claude -p --dangerously-skip-permissions --model ... --output-format stream-json
```

---

## The `ralph` Script

### Invocation

```bash
ralph <project-name> [max_iterations]
```

- `project-name`: subdirectory under `ralph/projects/` containing `design.md` and `plan.md`
- `max_iterations`: safety ceiling (default: 50)

### Behavior Per Iteration

1. Compose the prompt (generic + optional addendum, with placeholder substitution)
2. Pipe the prompt to `claude -p` with `--dangerously-skip-permissions`, `--model claude-opus-4-6`, `--output-format stream-json`, `--verbose`
3. Tee all output to `ralph/logs/<project>_<timestamp>_iteration_<N>.jsonl`
4. Scan output for `RALPH_ALL_COMPLETE` → exit 0
5. Scan output for `RALPH_PHASE_COMPLETE` → continue to next iteration
6. If neither signal found → print warning, continue (allows recovery from unexpected output)
7. Sleep briefly between iterations (configurable, default 5 seconds)

### Branching

The loop commits directly to whatever branch is currently checked out. The operator is responsible for creating and switching to the right branch before running `ralph`. The script detects and prints the current branch at startup but does not create or switch branches.

### Resumability

Because each phase ends with a commit and a checkbox mark in `plan.md`, re-running `ralph <project>` after interruption picks up at the next unchecked phase automatically. No state is stored outside the repository.

---

## The `ralph-follow` Script

Watches `ralph/logs/` for `.jsonl` files and tails the most recently modified one, rendering it as human-readable colored output. Auto-switches when the loop script creates a new iteration log file — no restart needed.

**Rendering:**
- `THINK:` — gray, dimmed (extended thinking blocks)
- `TOOL: <name>` — yellow (with key details per tool type)
- `RESULT[OK/ERR]` — dim/red
- Text output — green
- Session start — cyan bold
- Rate limit events — red

Run in a second terminal alongside `ralph`:
```bash
ralph-follow                    # watches ralph/logs/ relative to CWD
ralph-follow /path/to/logs/     # explicit logs directory
```

---

## Signal Protocol

Claude emits one of two signals as a literal string on its own line at the end of each iteration:

| Signal | Meaning |
|---|---|
| `RALPH_PHASE_COMPLETE` | One phase completed; loop should invoke Claude again |
| `RALPH_ALL_COMPLETE` | All phases done; loop should exit 0 |

The loop detects these by scanning the full combined stdout+stderr of each `claude` invocation. Using literal strings (not JSON) makes them detectable even when Claude's output format changes.

---

## Claude Code Skills — Content Design

Each skill file is a self-contained guide that tells Claude how to produce the corresponding artifact. The skill embeds all necessary instructions inline — no `@file` references to external guide documents.

This is a deliberate trade-off: skills are slightly harder to read in raw form but require no per-project files. Users who want to customize a guide can edit the skill file directly in `~/.ralph/commands/` (though this will be overwritten on `git pull` — a known limitation).

### `/ralph-explore` — Idea Exploration Guide

Instructs Claude to explore an idea through deep codebase analysis before any design decisions are committed. Claude investigates relevant code paths, adjacent features, patterns, documentation, and constraints, then produces `ralph/projects/<name>/explore.md` — a lightweight briefing containing: restated idea, codebase context discovered, an opinionated strawman proposal, alternatives with pros/cons, open questions grouped by impact, risks and show-stoppers, and a scope sketch with complexity signal. The exploration is interactive: after the initial briefing, Claude engages the user to resolve questions, refine the strawman, and draw scope boundaries. The output feeds directly into `/ralph-design`.

### `/ralph-design` — Design Specification Guide

Instructs Claude to create `ralph/projects/<name>/design.md` following the Ralph design document format: Goal, Current State, Design Sections (with locking analysis, data flow, code sketches), Interaction with Existing Code, Files Changed summary, and Open Questions. Emphasizes naming things early, documenting rejected approaches, and writing for a code agent reader with no memory between iterations.

### `/ralph-plan` — Execution Plan Guide

Instructs Claude to create `ralph/projects/<name>/plan.md` following the Ralph plan format: header with status/current-phase fields, phased tasks with checkboxes, Observations section per phase, and optional Design Decisions section for smaller features. Emphasizes phase granularity (one phase = one iteration = one commit), no placeholder tasks, and structuring phases so early ones establish scaffolding that later ones fill in.

### `/ralph-critique` — Pre-Execution Critique Guide

Instructs Claude to critically review the design and/or plan before execution begins. If `plan.md` exists, it reviews the plan and any linked design, producing `plan-critique.md`. Otherwise, it reviews `design.md` alone, producing `design-critique.md`. Claude analyzes the actual codebase to verify assumptions, traces code paths being modified, checks logic and math with concrete examples, and surfaces ambiguity and gaps. Produces findings categorized as Critical / Important / Suggestions. The critique is a report — the developer reads it and iterates on the documents through normal conversation.

### `/ralph-review` — Post-Execution Review Guide

Instructs Claude to review completed implementation by reading the design, plan (including all observations), all changed files, and git diffs. Produces findings categorized as Critical / Important / Trivial, a design compliance checklist, and a test coverage assessment. Verdict is one of: Approved / Approved with Minor Findings / Needs Work / Rejected.

### `/ralph-address` — Fix Review Findings Guide

Instructs Claude to process findings from `review.md` sequentially: read each finding, implement the fix, build to verify, and append a `> **Resolution:**` blockquote directly below the finding in `review.md` — preserving the original finding text intact. Findings are processed one at a time to avoid file conflicts.

### `/ralph-auto` — Full-Lifecycle Coordinator

Instructs Claude to coordinate the entire design → plan → critique → loop → review flow from a single command, orchestrating the other skills rather than reimplementing them. Design and the loop run in the coordinator's own context; plan, critique, review, and per-finding fixes run as sequential background subagents carrying a headless override (never ask the user — record Open Questions in the artifact instead). User checkpoints are asymmetric: a design with gaps (or a requested brainstorm) triggers a conversation and an explicit ask before planning, a clean design continues automatically, and the loop never starts without an explicit yes after all critique findings are resolved. Critique and review findings are triaged into unambiguous (fixed sequentially, resolutions recorded with the `/ralph-address` blockquote convention) versus judgment calls (raised to the user). State lives entirely in the project artifacts, committed after every step, so an interrupted run resumes from the first incomplete artifact — and mixes freely with manual skill invocations. Every phase defaults to the coordinator's own model unless the user names an override for a specific phase.

---

## Key Design Decisions

### Why git clone to `~/.ralph/` rather than a package manager

A git clone gives users versioned, reproducible installs with trivial updates (`git pull`) and rollbacks (`git checkout <tag>`). It requires no build step, no npm/pip dependency, and no registry account. The trade-off is that users must have git installed, which is a safe assumption for developers.

### Why symlinks for skills rather than copies

Symlinks mean skills update automatically on `git pull` without a reinstall step. The downside is that users cannot locally modify a skill without having that change overwritten on next update. This is acceptable: users who need project-specific prompt behavior use the per-repo addendum mechanism instead of modifying shared skills.

### Why the addendum is appended rather than the bundled prompt being replaced

Replacement would require users to maintain a full copy of the loop protocol, making it hard to absorb upstream improvements. Addendum-only means users maintain only the delta (project conventions), and the stable loop protocol updates automatically.

### Why `--model claude-opus-4-6` is hardcoded in the loop

The loop performs complex multi-step reasoning across large codebases. Smaller/faster models have meaningfully worse results in practice. The model can be overridden by a flag if needed, but the default is intentionally the most capable model.

### Why `--dangerously-skip-permissions` is required

The loop is designed for autonomous operation in a controlled environment (the developer's own machine, on a feature branch). Requiring interactive permission approvals would break the automation. Users who are uncomfortable with this can run with standard permissions, at the cost of the loop pausing for approvals.

---

## Open Questions

All questions have been resolved during the design conversation.

1. **Should the project-local PROMPT.md replace or extend the generic one?**
   _Resolved:_ Extend (addendum only). Replacement would break upstream update propagation.

2. **Does installation require `sudo`?**
   _Resolved:_ No. Everything installs to user-level locations (`~/.ralph/`, `~/.claude/commands/`, shell RC file). No system directories are touched.

3. **Should skills be copies or symlinks in `~/.claude/commands/`?**
   _Resolved:_ Symlinks, so `git pull` in `~/.ralph` propagates updates automatically without reinstall.

4. **Where should the bundled `PROMPT.md` live after installation?**
   _Resolved:_ `~/.ralph/PROMPT.md` (the root of the git clone). The `ralph` script resolves its own location at runtime and reads `PROMPT.md` relative to it.

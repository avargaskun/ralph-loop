# ralph-loop

A portable, installable agentic development framework for Claude Code. Ralph implements a phase-by-phase plan executor where Claude autonomously works through a structured plan one phase at a time, committing after each one.

Install once to your home directory. The `ralph` CLI and the full set of ralph slash commands are then available in every project on your machine — no per-project file copying required.

## Installation

```bash
git clone https://github.com/avargaskun/ralph-loop ~/.ralph
~/.ralph/install.sh
# Open a new terminal (or: source ~/.zshrc)
```

## SDLC Workflow

Ralph projects follow a six-phase lifecycle: **Design → Plan → Critique → Execute → Review → Address**.

```
/ralph-design my-feature    # 1. Create design.md interactively
/ralph-plan my-feature      # 2. Create plan.md from the design
/ralph-critique my-feature  # 3. Pre-execution critique of design/plan
ralph my-feature            # 4. Execute the plan autonomously (shell-based)
/ralph-loop my-feature      # 4. OR execute in-session (for SSO/PortKey users)
/ralph-review my-feature    # 5. Review the implementation
/ralph-address my-feature   # 6. Fix review findings
```

Or run the whole lifecycle from a single command — see [Automated flow](#automated-flow--ralph-auto-project-name-instructions):

```
/ralph-auto my-feature
```

All of these slash commands are available in any Claude Code conversation after installation. Each one bootstraps the `ralph/projects/` folder if it doesn't exist yet.

### 1. Design — `/ralph-design [project-name]`

Guides Claude to create `ralph/projects/<name>/design.md`: a structured specification capturing the *what* and *why* — architecture, data flows, locking analysis, edge cases, and trade-offs. Claude engages interactively, surfaces trade-offs, and lists Open Questions for you to resolve. The design is ready when all questions are marked `_Resolved_`.

### 2. Plan — `/ralph-plan [project-name]`

Reads the design document and guides Claude to create `ralph/projects/<name>/plan.md`: a phased execution plan with checkboxes, code sketches, and build/test gates. Each phase is sized to fit in a single Claude Code context window (one phase = one commit).

### 3. Critique — `/ralph-critique [project-name]`

Guides Claude to critically review the design and/or plan *before execution begins*. If `plan.md` exists, it reviews the plan (and any linked design). Otherwise, it reviews `design.md` alone. Claude analyzes the actual codebase to verify assumptions, checks logic and math, surfaces ambiguity, and produces findings categorized as Critical / Important / Suggestions. Output is `design-critique.md` when reviewing design only, or `plan-critique.md` when reviewing the plan.

The critique is a report — after reading it, you iterate on the design/plan through normal conversation before starting execution.

### 4. Execute — `ralph <project-name>` or `/ralph-loop [project-name]`

Two ways to run the autonomous loop:

#### Shell-based execution: `ralph <project-name>`

Recommended for most users. Runs the loop as a shell script. Each iteration:

1. Substitutes project paths into the bundled prompt template
2. Pipes the composed prompt to `claude -p` headlessly
3. Claude finds the next unchecked phase, implements it, records observations, and commits
4. Outputs `RALPH_PHASE_COMPLETE` (loop continues) or `RALPH_ALL_COMPLETE` (loop exits)
5. Logs everything to `ralph/logs/<project>_<timestamp>_iteration_<N>.jsonl`

If interrupted, re-run the same command — the loop picks up at the next unchecked phase.

```bash
ralph my-feature            # Run until all phases complete (max 50 iterations)
ralph my-feature 10         # Run at most 10 iterations
```

#### In-session execution: `/ralph-loop [project-name] [max-iterations]`

For users who cannot run the shell-based `ralph` command (e.g., SSO-authenticated Claude Code, API keys through PortKey). Spawns sequential subagents within your current Claude session following the same `PROMPT.md` instructions.

Each subagent executes exactly one phase, then stops. The main agent detects the `RALPH_PHASE_COMPLETE` or `RALPH_ALL_COMPLETE` signal and continues or exits accordingly.

```
/ralph-loop my-feature      # Run until all phases complete (max 50 iterations)
/ralph-loop my-feature 10   # Run at most 10 iterations
```

**Note:** In-session execution is slower and consumes your current conversation context. Use the shell-based `ralph` command when possible.

### 5. Review — `/ralph-review [project-name]`

After all phases complete, guides Claude to produce `ralph/projects/<name>/review.md`: a full code review reading the design, plan observations, all changed files, and git diffs. Findings are categorized as Critical / Important / Trivial with a design compliance checklist and test coverage assessment.

### 6. Address — `/ralph-address [project-name]`

Guides Claude to fix findings from `review.md` sequentially — one finding at a time using sub-agents to preserve context. Each fix is followed by a build verification and a `> **Resolution:**` blockquote appended to the finding in the review document.

### Automated flow — `/ralph-auto [project-name] [instructions]`

Runs the entire lifecycle from a single command. Claude becomes the coordinator: it designs with you, then drives plan, critique, execution, and review — pausing only where your judgment is genuinely needed. You can keep talking to the coordinator the whole time; guidance you give mid-run is routed to the phases it applies to.

```
/ralph-auto my-feature
/ralph-auto my-feature brainstorm the design with me; run the review using fable
```

How it flows:

1. **Design** runs interactively in your session. If you asked for a brainstorm — or the draft surfaces gaps or an ambiguous choice that could lead down very different paths — Claude discusses the alternatives with you and asks before moving on. A clean design continues to planning automatically.
2. **Plan** and **critique** run as background subagents while the coordinator stays responsive.
3. **Critique findings** are triaged: unambiguous ones are fixed one at a time, judgment calls are raised to you. Claude always asks before starting the loop — the last checkpoint before code gets written.
4. **Execution** uses the in-session loop (the same machinery as `/ralph-loop`). Blocked phases and manual steps are raised to you.
5. If the loop runs to completion, **review** runs as a subagent and its findings are triaged the same way — unambiguous fixes are applied sequentially, `/ralph-address`-style, and the rest come to you.

The run is resumable: state lives entirely in the project artifacts, which are committed after every step. If a run is interrupted, re-run `/ralph-auto <project-name>` and it picks up where it left off — an existing `design.md` skips to planning, an existing `plan.md` skips to critique, unresolved findings resume the triage, and so on. This also means you can mix `/ralph-auto` freely with the individual commands.

Every phase defaults to the model your session is running. Name a model in the instructions (e.g., "run the review using fable") to override a specific phase.

---

## Project structure

After installation, projects using ralph-loop only need:

```
<your-repo>/
└── ralph/
    ├── PROMPT.md           # OPTIONAL: project-specific addendum (appended to bundled prompt)
    ├── EXTENSIONS.md       # OPTIONAL: per-skill guidance for the authoring/review skills
    ├── projects/
    │   └── <project-name>/
    │       ├── design.md   # Created by /ralph-design
    │       ├── plan.md     # Created by /ralph-plan
    │       ├── design-critique.md  # Created by /ralph-critique (design only)
    │       ├── plan-critique.md    # Created by /ralph-critique (plan + design)
    │       └── review.md   # Created by /ralph-review
    └── logs/               # Auto-created; gitignore this
```

No scripts, no guide documents, no prompt templates in your project — only artifacts.

### Project-specific addendum (`ralph/PROMPT.md`)

An optional file you commit to your project. It is **appended** to the bundled generic prompt at runtime — it does not replace it. Use it for:

- Build system commands (e.g., `npm run build`, `make test`)
- Framework-specific conventions the agent must follow
- Project-specific gotchas

```bash
# ralph/PROMPT.md (example)
Use `npm run build` to compile and `npm test` to run the test suite.
All new TypeScript files must be registered in tsconfig.json.
```

The authoring/review skills (`/ralph-explore`, `/ralph-design`, `/ralph-plan`, `/ralph-critique`, `/ralph-review`, `/ralph-address`) also read this file as background context — e.g., `/ralph-plan` takes the build/test gate commands from it instead of asking — so shared facts like build commands only need to be written here once.

### Per-skill extensions (`ralph/EXTENSIONS.md`)

An optional file you commit to your project to extend the *authoring and review* skills. It is organized in sections named after the skills; each skill reads `## General` plus its own section and ignores the rest:

```markdown
# ralph/EXTENSIONS.md (example)

## General
All ralph project documents must use British English spelling.

## Design
Every design must include a rollout/feature-flag section.

## Plan
Cap phases at 6 tasks — this codebase's build is slow.

## Review
Check the accessibility checklist in docs/a11y.md for any UI change.
```

Available sections: `## General`, `## Explore`, `## Design`, `## Plan`, `## Critique`, `## Review`, `## Address`, `## Auto`. The content extends the skills — it never replaces their protocol (output files, document structure, signals). This file is **never** injected into execution subagents; executors only receive `ralph/PROMPT.md`.

**Where does a rule go?**

| The rule applies to... | Put it in |
|---|---|
| Execution subagents, every loop iteration | `ralph/PROMPT.md` |
| A specific authoring/review phase | the matching section of `ralph/EXTENSIONS.md` |
| All Claude work in the repo (ralph or not) | `CLAUDE.md` |

---

## Watching a running loop

In a second terminal:

```bash
ralph-follow                    # watches ralph/logs/ under current directory
ralph-follow /path/to/logs/     # explicit logs directory
```

Renders the JSONL stream as colored human-readable output: thinking blocks (gray), tool calls (yellow), results (dim), text output (green), session start (cyan bold), rate limit events (red). Auto-switches to the newest log file when a new iteration starts.

---

## Repository layout (installed at `~/.ralph/`)

```
~/.ralph/
├── install.sh              # One-time setup script
├── PROMPT.md               # Bundled generic loop prompt template
├── bin/
│   ├── ralph               # Loop executor
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

`~/.claude/commands/ralph-*.md` are symlinks pointing into `~/.ralph/commands/`, so `git pull` in `~/.ralph` updates all skills automatically.

---

## Updating

```bash
cd ~/.ralph && git pull
```

Skills and CLI scripts update automatically — no reinstall step needed.

## Rollback

```bash
cd ~/.ralph && git checkout v1.2.0
```

---

## Key design decisions

**Why `git clone` rather than a package manager?** Versioned installs with trivial updates (`git pull`) and rollbacks (`git checkout <tag>`). No build step, no registry account, no runtime dependency beyond `git` and `claude`.

**Why symlinks for skills?** Skills update automatically on `git pull`. Users who need project-specific prompt behavior use the per-repo addendum (`ralph/PROMPT.md`) rather than modifying shared skills.

**Why `--model claude-opus-4-6`?** The loop performs complex multi-step reasoning across large codebases. The model can be overridden with a flag, but the default is intentionally the most capable model.

**Why `--dangerously-skip-permissions`?** Autonomous operation on the developer's own machine on a feature branch. Interactive permission approvals would break the automation.

---

## License

MIT

# ralph-loop

A portable, installable agentic development framework for Claude Code. Ralph implements a phase-by-phase plan executor where Claude autonomously works through a structured plan one phase at a time, committing after each one.

Install once to your home directory. The `ralph` CLI and four slash commands are then available in every project on your machine — no per-project file copying required.

## Installation

```bash
git clone https://github.com/avargaskun/ralph-loop ~/.ralph
~/.ralph/install.sh
# Open a new terminal (or: source ~/.zshrc)
```

## SDLC Workflow

Ralph projects follow a four-phase lifecycle: **Design → Plan → Execute → Review → Address**.

```
/ralph-design my-feature    # 1. Create design.md interactively
/ralph-plan my-feature      # 2. Create plan.md from the design
ralph my-feature            # 3. Execute the plan autonomously
/ralph-review my-feature    # 4. Review the implementation
/ralph-address my-feature   # 5. Fix review findings
```

All four slash commands are available in any Claude Code conversation after installation. Each one bootstraps the `ralph/projects/` folder if it doesn't exist yet.

### 1. Design — `/ralph-design [project-name]`

Guides Claude to create `ralph/projects/<name>/design.md`: a structured specification capturing the *what* and *why* — architecture, data flows, locking analysis, edge cases, and trade-offs. Claude engages interactively, surfaces trade-offs, and lists Open Questions for you to resolve. The design is ready when all questions are marked `_Resolved_`.

### 2. Plan — `/ralph-plan [project-name]`

Reads the design document and guides Claude to create `ralph/projects/<name>/plan.md`: a phased execution plan with checkboxes, code sketches, and build/test gates. Each phase is sized to fit in a single Claude Code context window (one phase = one commit).

### 3. Execute — `ralph <project-name>`

Runs the autonomous loop. Each iteration:

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

### 4. Review — `/ralph-review [project-name]`

After all phases complete, guides Claude to produce `ralph/projects/<name>/review.md`: a full code review reading the design, plan observations, all changed files, and git diffs. Findings are categorized as Critical / Important / Trivial with a design compliance checklist and test coverage assessment.

### 5. Address — `/ralph-address [project-name]`

Guides Claude to fix findings from `review.md` sequentially — one finding at a time using sub-agents to preserve context. Each fix is followed by a build verification and a `> **Resolution:**` blockquote appended to the finding in the review document.

---

## Project structure

After installation, projects using ralph-loop only need:

```
<your-repo>/
└── ralph/
    ├── PROMPT.md           # OPTIONAL: project-specific addendum (appended to bundled prompt)
    ├── projects/
    │   └── <project-name>/
    │       ├── design.md   # Created by /ralph-design
    │       ├── plan.md     # Created by /ralph-plan
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
    ├── ralph-design.md
    ├── ralph-plan.md
    ├── ralph-review.md
    └── ralph-address.md
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

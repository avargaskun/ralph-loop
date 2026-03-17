ultrathink

You are running the Ralph loop workflow within the current Claude session. This is an alternative to the shell-based `ralph` command for users who cannot run external scripts (e.g., SSO requirements, PortKey API keys).

## Project name and input

Parse `$ARGUMENTS` as follows:
- The **first word** is the project name (the folder name under `ralph/projects/`).
- The **second word** (optional) is the maximum number of iterations (default: 50).
- Everything **after** is additional context provided by the user — treat it as supplementary input.

If `$ARGUMENTS` is empty, ask the user: "What is the project name? (The folder name under `ralph/projects/`)"

## Bootstrap

Before doing anything, ensure the required directory structure exists:

```
ralph/
└── projects/
    └── <project-name>/
```

Create these directories if they do not exist. Do NOT error out or stop — just create them silently and continue.

## Prerequisites

Before starting the loop, verify:

1. `ralph/projects/<project-name>/plan.md` exists — this is required.
2. `ralph/projects/<project-name>/design.md` may or may not exist — note whether it's present.

If the plan file doesn't exist, tell the user to run `/ralph-plan <project-name>` first, then stop.

## Your task

Execute the Ralph loop workflow by spawning sequential subagents. Each subagent executes exactly one phase of the plan, following the same `PROMPT.md` instructions that the shell-based `ralph` command uses.

---

## Workflow

### Step 1: Read the prompt template

Read the bundled prompt template. The template is at:
- **Path:** `~/.ralph/PROMPT.md`

This template contains placeholders that you'll substitute:
- `{{PLAN_FILE}}` → `ralph/projects/<project-name>/plan.md`
- `{{DESIGN_FILE}}` → `ralph/projects/<project-name>/design.md` (or "(no design document)" if missing)
- `{{HAS_DESIGN}}` → `true` or `false`

### Step 2: Build the agent prompt

Substitute the placeholders in the template with the actual file paths:

```
PLAN_FILE = "ralph/projects/<project-name>/plan.md"
DESIGN_FILE = "ralph/projects/<project-name>/design.md" OR "(no design document)"
HAS_DESIGN = true OR false
```

**Optional:** If `ralph/PROMPT.md` exists in the repository (a project-local addendum), append it to the prompt after a separator:

```markdown
---

## Project-Specific Instructions

<contents of ralph/PROMPT.md>
```

### Step 3: Display starting information

Before starting the loop, output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ralph Loop (In-Session)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project:  <project-name>
  Design:   <path or "(none)">
  Plan:     ralph/projects/<project-name>/plan.md
  Max:      <max_iterations> iterations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Run the loop

Execute iterations sequentially using the Agent tool:

1. **Spawn a subagent** with:
   - `description: "Execute phase N of ralph project <project-name>"`
   - `prompt: <the composed prompt from Step 2>`
   - `model: "opus"` (use Opus for complex multi-step reasoning)
   - `run_in_background: false` (blocking — wait for completion)

2. **After the subagent completes**, examine its output for completion signals:
   - If output contains `RALPH_PHASE_COMPLETE`: The phase is done. Continue to the next iteration.
   - If output contains `RALPH_ALL_COMPLETE`: All phases are complete. Stop the loop and output success message.
   - If neither signal is found: Log a warning but continue to the next iteration.

3. **Preserve context between iterations** — after each subagent completes, read the plan file's "Current phase" field and record it in your own working notes so you know where the project stands. This helps you provide accurate status if the user asks or if the loop is interrupted.

4. **Output iteration status** before each agent:
   ```
   ┌──────────────────────────────────────────────
   │ Iteration N / <max_iterations>
   │ Current phase: <phase from plan file>
   └──────────────────────────────────────────────
   ```

5. **Repeat** until:
   - `RALPH_ALL_COMPLETE` is detected, OR
   - Maximum iterations reached

### Step 5: Final output

When the loop completes:

- If `RALPH_ALL_COMPLETE` was detected:
  ```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    All phases complete! Finished after N iterations.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```

- If max iterations reached:
  ```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Reached max iterations (<max_iterations>). Stopping.
    Use /ralph-loop <project-name> to continue from where it left off.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```

---

## Important Notes

- **Sequential execution only.** Do NOT spawn subagents in parallel — they will conflict on file modifications.
- **No session persistence across subagents.** Each subagent starts fresh with only the prompt and the plan/design files.
- **The subagent is autonomous.** It will NOT ask questions (per PROMPT.md instructions). It must make decisions based on the plan and design.
- **Completion signals are critical.** The loop depends on the agent outputting `RALPH_PHASE_COMPLETE` after each phase and `RALPH_ALL_COMPLETE` when all done.

---

## Error Handling

- If a subagent fails or produces an error, log the error and ask the user whether to:
  1. Continue to the next iteration (agent may have partially completed work)
  2. Stop the loop and investigate

- If the plan file is modified during execution and becomes unparseable, stop the loop and notify the user.

---

## When done

After the loop completes (successfully or via max iterations), read the plan file one final time and summarize:
- Total iterations run
- Current phase (from the plan file's "Current phase" field)
- Status (from the plan file's "Status" field)
- Next steps:
  - If all phases complete: `Use /ralph-review <project-name> to review the implementation`
  - If max iterations reached: `Use /ralph-loop <project-name> to continue from Phase X`
  - If error/warning occurred: Explain what happened and suggest next action

## Loop state tracking

To preserve your context across the loop and provide accurate status to the user:

1. **Before the loop starts**: Read the plan file and note the current phase and status.
2. **After each subagent completes**: Re-read the plan file to see what phase is now current and whether the status changed.
3. **Keep a running log** in your working notes of:
   - Iteration number
   - Phase executed
   - Completion signal detected (`RALPH_PHASE_COMPLETE`, `RALPH_ALL_COMPLETE`, or warning)
   - Any notable events (errors, missing signals, etc.)

This allows you to answer user questions mid-loop (e.g., "What phase are we on?") and provide accurate status at the end.

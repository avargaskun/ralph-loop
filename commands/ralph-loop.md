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

**Conditional — stuck protocol (Sonnet only):** When `SUBAGENT_MODEL` is `sonnet` (chosen in Step 3), append the following section to every spawned subagent's prompt after a separator, substituting `<N>` with the current iteration number:

```markdown
---

## When you are stuck

Declare yourself blocked rather than grinding on a hard problem. You are blocked if ANY of these occur:

- You have made 3 distinct attempts to fix the same failing test/build error and the error is unchanged, or you are alternating between the same two failure states.
- Progress requires something you cannot obtain (a missing credential, a broken external dependency, an ambiguous requirement that needs a human decision).

When blocked, do NOT keep trying. Instead:

1. Revert any half-finished changes that would leave the build broken. Keep completed, working tasks checked off.
2. Add an entry to the current phase's **Observations** section:
   `- **BLOCKED (iteration <N>):** <exact error or obstacle> — Tried: <distinct attempts made> — Hypothesis: <best guess at root cause>`
3. Commit the changes (following the git staging rule).
4. Do NOT advance the **Current phase** field and do NOT check off incomplete tasks.
5. End your output with `RALPH_BLOCKED` on its own line and stop.
```

### Step 3: Choose the subagent model

Determine which model to use for the phase-execution subagents:

1. If the user's extra arguments already name a model (`sonnet`, `opus`, or
   `fable`), use it and skip the question.
2. Otherwise ask, using the AskUserQuestion tool:
   - Question: "Which model should Ralph use for the phase-execution subagents?"
   - Options:
     - "opus" (Recommended) — strong multi-step reasoning; the loop's default
     - "fable" — most capable tier; highest cost, best for the hardest plans
     - "sonnet" — fastest and cheapest; fine for mechanical, well-specified plans
3. Record the choice as SUBAGENT_MODEL and use it for every iteration.
4. If a subagent fails to launch because the chosen model isn't available on
   this account, fall back to "opus", notify the user, and continue the loop.

### Step 4: Display starting information

Before starting the loop, output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ralph Loop (In-Session)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project:  <project-name>
  Design:   <path or "(none)">
  Plan:     ralph/projects/<project-name>/plan.md
  Model:    <SUBAGENT_MODEL>
  Max:      <max_iterations> iterations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Run the loop

Execute iterations sequentially using the Agent tool:

1. **Spawn a subagent** with:
   - `description: "Execute phase N of ralph project <project-name>"`
   - `prompt: <the composed prompt from Step 2>`
   - `model: <SUBAGENT_MODEL>` (chosen in Step 3)
   - `run_in_background: true` (non-blocking — you will be notified on completion)

   Then **record the iteration's identity and a pre-spawn baseline** — you'll need both to decide the outcome from ground truth:
   - Save the `agentId`/task-id the Agent tool returns as the **current expected agent** for this iteration. Only a notification whose task-id matches this may advance the loop.
   - Capture the **baseline**: `git rev-parse HEAD`, plus the plan file's `Status` and `Current phase` values. Real progress is a *change* from this baseline.

2. **When you are woken, decide the outcome from ground truth — never from the notification's text or signal token.** A `<task-notification>` (or any other wake) means only "go check"; its payload, including any `RALPH_*` token or prose summary, is an unreliable hint, not a decision.

   a. **Attribute by task-id.** Compare the notification's task-id to the current expected agent (recorded in 5.1). A notification from any *other* task-id is a prior/idle agent re-firing — ignore it for control flow and do not trust its summary (a finished agent re-firing and narrating later phases is noise, not progress). It may prompt you to run the liveness check (5.3), but it must never, on its own, advance the loop or declare completion.

   b. **Confirm against git + the plan file.** Re-read the plan and check `git log`, comparing to the baseline from 5.1:
      - **Phase complete** — the plan's `Current phase` has advanced past the spawned phase (or `Status` is `Complete`/`Done`) **and** that phase's task checkboxes are all `[x]`. For code-bearing phases a matching `Phase N:` commit in `git log` is corroborating evidence; **verification-only phases produce no commit — do not require one.** Advance to the next iteration. If every phase is `[x]` and `Status` is `Complete`, the project is done — emit the success message (do not require a literal `RALPH_ALL_COMPLETE` token to have appeared anywhere).
      - **Blocked** — a new `**BLOCKED**` entry has appeared in the current phase's Observations. Follow "Handling a blocked phase" below. (This preserves the prior `RALPH_BLOCKED` behavior; the Observations entry, not the token, is the ground truth.)
      - **Not done** — neither of the above. Do NOT advance. Run the liveness check (5.3) before deciding to keep waiting.

3. **Liveness check — never block indefinitely on the current agent.** Do not assume a completion notification will arrive: notifications can be **lost** (the real one never fires) or **misattributed** (only stale ones from already-finished agents fire). Reconcile actively rather than wait:
   - **On every wake**, regardless of which task-id fired, run a non-blocking liveness check on the current expected agent: `TaskOutput(<current task-id>, block=false)`.
   - **Also bound the wait.** If no authoritative outcome (per 5.2) for the current task-id has arrived within a sanity bound — noticeably longer than comparable phases have taken this run, or a hard ceiling of ~20–30 minutes — run the same liveness check rather than continuing to wait.
   - **Interpreting it:** if `TaskOutput` returns "No task found" (or shows the task completed without an authoritative outcome), the agent is **dead or already finished** — stop waiting and follow "Recovering from a dead or stalled agent" below. If it shows the agent still actively working, keep waiting and re-check on the next wake or when the bound elapses again.

4. **Preserve context between iterations** — after each subagent completes, read the plan file's "Current phase" field and record it in your own working notes so you know where the project stands. This helps you provide accurate status if the user asks or if the loop is interrupted.

5. **Output iteration status** before each agent:
   ```
   ┌──────────────────────────────────────────────
   │ Iteration N / <max_iterations>
   │ Current phase: <phase from plan file>
   └──────────────────────────────────────────────
   ```

6. **Repeat** until:
   - All phases are confirmed complete from the plan + git (per 5.2), OR
   - Maximum iterations reached, OR
   - The user asks you to stop

### Step 6: Final output

When the loop completes:

- If all phases are complete (confirmed from the plan + git per Step 5.2):
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

- If the user asked to stop:
  ```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Stopped by user after N iterations.
    Use /ralph-loop <project-name> to continue from where it left off.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```

- If the loop stopped on a blocked phase (user chose not to retry):
  ```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Blocked on <phase> after N iterations.
    See the BLOCKED entry in the plan's Observations.
    Use /ralph-loop <project-name> to continue once resolved.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```

---

## Handling a blocked phase

When a subagent reports `RALPH_BLOCKED`:

1. Re-read the plan file and find the new `**BLOCKED**` entry in the current phase's Observations.
2. Explain the blockage to the user in plain language: what the agent was attempting, what it tried, the exact error, and its hypothesis.
3. Ask the user how to proceed. Choose the form that fits the situation:
   - If the sensible remedies are discrete, the AskUserQuestion tool works well. Typical options: retry this phase with a stronger model (`opus`, or `fable` if not already in use); stop the loop to investigate manually; continue to the next iteration anyway.
   - If the blockage is ambiguous, or unblocking requires information only the user can provide (a decision, a credential, a clarified requirement), do NOT manufacture options for AskUserQuestion. Explain the issue in the chat and ask for open-ended input instead.
4. If the user chooses a retry with a stronger model: spawn the same phase with that model, prepending this line to the composed prompt: "A previous attempt at this phase was blocked — read the **BLOCKED** entry in the current phase's Observations before starting. If you get past the blocker, add an **UNBLOCKED:** note to Observations describing what worked." Revert to `SUBAGENT_MODEL` for subsequent iterations unless the user says otherwise.
5. If the user provides unblocking input in chat, pass it to the next attempt by appending it to the composed prompt as additional context.
6. Blocked attempts and retries count toward `max_iterations`.

---

## Recovering from a dead or stalled agent

When the liveness check (Step 5.3) shows the current expected agent is dead or vanished — `TaskOutput` returns "No task found", or the task completed without an authoritative outcome — do NOT keep waiting and do NOT trust any stale notification. Recover:

1. **Inspect the working tree** for the phase's on-disk work, and **run the phase's build + test gate** (the same gate `PROMPT.md` requires before a phase counts as done).
2. **If the gate is green:** the phase effectively completed. Check off the phase's tasks, add an Observations entry noting the recovery (e.g. `- **RECOVERED (iteration <N>):** agent terminated without signalling; build+test gate green — finishing the phase.`), advance the `Current phase`, and commit (following the git staging rule). Continue the loop.
3. **If the gate is red or the work is incomplete:** reset to the last clean phase commit (`git reset --hard <last good Phase N commit>`, discarding the dead agent's partial work) and relaunch the same phase as a fresh iteration — optionally with a stronger model (`opus`, or `fable`).
4. **Recovery attempts count toward `max_iterations`.**

**Signature of a stale re-fire.** A single task-id that notifies repeatedly with growing reported duration — especially one whose summary describes work outside its own phase (e.g. a finished Phase 3 agent narrating Phase 4, or repeatedly reporting it "came to rest with no live background children") — is a finished-but-idle agent re-firing, not progress. Ignore its payload and check the current expected agent's liveness (Step 5.3) instead.

---

## Important Notes

- **Stopping the loop.** Because the loop runs inside this Claude session, the user can stop it at any time — by interrupting (Esc) or by telling you to stop. You remain responsive between iterations, so when the user asks to stop, finish reporting status for the current iteration and halt gracefully without spawning the next subagent. The loop is resumable: re-running `/ralph-loop <project-name>` picks up from where it left off.
- **Sequential execution only.** Do NOT spawn subagents in parallel — they will conflict on file modifications. Wait for each background agent to complete before spawning the next.
- **Remain responsive between iterations.** While a background agent is running, you can answer user questions, provide status updates, or discuss the project. When the agent completes, proceed with the next iteration.
- **No session persistence across subagents.** Each subagent starts fresh with only the prompt and the plan/design files.
- **`ralph/EXTENSIONS.md` is not for executors.** That file extends the authoring/review skills (explore, design, plan, critique, review, address). Do NOT append it to subagent prompts — the only project-local content injected into execution subagents is `ralph/PROMPT.md`.
- **The subagent is autonomous.** It will NOT ask questions (per PROMPT.md instructions). It must make decisions based on the plan and design.
- **Completion is decided from ground truth, not from notifications.** The plan file and git history determine whether a phase finished — the `RALPH_PHASE_COMPLETE` / `RALPH_ALL_COMPLETE` / `RALPH_BLOCKED` tokens and notification summaries are only hints. A completed background agent may re-notify with a stale or fabricated payload (even narrating phases it never ran), and a real completion notification may never arrive at all. Always attribute a notification to the current expected agent's task-id, reconcile against `TaskOutput` + git + the plan, and never advance or report on the strength of a token or summary alone (see Steps 5.1–5.3).
- **Shell variant needs no analogous safeguard.** The shell-based `ralph` runs each iteration synchronously (`OUTPUT=$(echo "$PROMPT" | claude -p …)`) — it blocks on one foreground `claude` invocation per iteration, with no background agents, task-ids, or notifications. There is no dead-agent/stale-notification failure mode to guard against; a hung run is bounded by the per-iteration structure, `max_iterations`, and Ctrl+C. These robustness rules apply only to this in-session loop.

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
  - If blocked: Summarize the blocker from the BLOCKED entry and suggest an unblocking action
  - If error/warning occurred: Explain what happened and suggest next action

## Loop state tracking

To preserve your context across the loop and provide accurate status to the user:

1. **Before the loop starts**: Read the plan file and note the current phase and status.
2. **After each subagent completes**: Re-read the plan file to see what phase is now current and whether the status changed.
3. **Keep a running log** in your working notes of:
   - Iteration number
   - Phase executed
   - The current expected `agentId`/task-id and the pre-spawn baseline (HEAD, plan `Status`, plan `Current phase`) — so you can attribute notifications and detect real progress
   - How the outcome was confirmed (plan + git change), not merely which token appeared
   - Any notable events (errors, missing/misattributed notifications, liveness checks, recoveries, etc.)

This allows you to answer user questions mid-loop (e.g., "What phase are we on?" or "How long has this iteration been running?") and provide accurate status at the end.

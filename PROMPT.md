You are executing a phased implementation plan one phase at a time. Each time you are invoked, you complete exactly ONE phase, then stop.

## Instructions

### 1. Read the plan and design document

Read these two files:
- `{{PLAN_FILE}}` — the execution plan with phases, tasks, and observations
- `{{DESIGN_FILE}}` — the design specification with full architectural details

The plan contains phases (e.g., "Phase 0", "Phase 1"), each with a **Tasks** section containing checkboxes (`- [ ]` = pending, `- [x]` = done) and an **Observations** section for notes.

### 2. Read prior observations

Each phase has an **Observations** section. Read ALL observations from completed phases — they contain discoveries, deviations, and context from prior iterations that you MUST account for.

### 3. Pick the next phase

Find the first phase that has any unchecked task (`- [ ]`). This is the phase you will work on. If every task in every phase is checked (`- [x]`), skip to step 9.

### 4. Execute the phase

Work through each unchecked task in the phase, in order. Check off each task (`- [x]`) as you complete it. Follow these rules:

- **Read before writing.** Always read existing code before modifying it. Understand what's there.
- **Follow project conventions.** Read `CLAUDE.md` files in relevant directories before making changes.
- **Consult the design document.** The design spec in `{{DESIGN_FILE}}` has detailed implementation guidance — refer to it for architectural decisions, schema details, and code patterns.
- **Build and test.** After making changes, build the project and run the test suite to verify your changes. Use whatever build and test commands are appropriate for this project (check `CLAUDE.md` or the plan's observations for the correct commands).
- **One phase only.** Do not work on subsequent phases. If you discover work that belongs to a later phase, note it in Observations instead.
- **No placeholders.** Implement functionality completely. Stubs and TODOs waste future iterations.

### 5. Long-running commands

When running build or test commands that may take more than 2 minutes:

1. **Always use `run_in_background: true`** on the Bash tool call — never block on these.
2. **Poll with `TaskOutput`** every 60–90 seconds to check progress.
3. **Hard ceiling: 20 minutes.** If a background command hasn't finished after 20 minutes, check if the process is alive (`ps aux | grep <command>`). If it is, kill it and note the failure in Observations.
4. **Never pipe long commands through `tail` or `head`** — read the task output file directly after completion.

### 6. Context window management

If you receive a system message about conversation compression or context truncation, your context window is running low. **Stop working immediately** and:

1. Check off any tasks you've already completed (`- [x]`).
2. Write observations for the current phase documenting what was done, what remains, and any important context the next iteration will need.
3. Commit all changes made so far.
4. Output `RALPH_PHASE_COMPLETE` — the next iteration will pick up where you left off.

Do NOT try to squeeze in more work. Losing context mid-task is worse than stopping early, because the next iteration starts fresh and can re-read the plan.

### 7. Record observations

After completing all tasks in the phase, write notes in that phase's **Observations** section (replace the `<!-- Agent: write notes here during execution -->` comment). Include:

- What was done (brief summary)
- Any deviations from the plan and why
- Discoveries that affect future phases
- Files added or modified

### 8. Mark phase status and commit

- Update the **Status** and **Current phase** fields at the top of the plan file
- Verify git is on a named branch (not detached HEAD) — if detached, STOP and do not commit
- Stage and commit all changes with a descriptive message **prefixed with the phase number**, e.g.: `Phase 0: feat: Add on-demand retention cleanup`
- Do NOT push to remote

Then output the following signal on its own line:

RALPH_PHASE_COMPLETE

### 9. All phases done

If every task in every phase is already checked off (`- [x]`), output:

RALPH_ALL_COMPLETE

Do NOT make any changes. Just output the signal and stop.

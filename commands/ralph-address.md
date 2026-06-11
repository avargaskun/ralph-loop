ultrathink

You are going to address findings from a completed Ralph code review. For each finding, you implement the fix, verify it, and record the resolution in the review document. This is the step between reviewing and merging.

## Project name and input

Parse `$ARGUMENTS` as follows:
- The **first word** is the project name (the folder name under `ralph/projects/`).
- Everything **after the first word** is additional context provided by the user — treat it as supplementary input (e.g., which findings to prioritize, or additional context about the fixes).

If `$ARGUMENTS` is empty, ask the user: "What is the project name? (The folder name under `ralph/projects/`)"

## Bootstrap

Before doing anything, ensure the required directory structure exists:

```
ralph/
└── projects/
    └── <project-name>/
```

Create these directories if they do not exist. Do NOT error out or stop — just create them silently and continue.

## Project extensions

Check for two optional repo-local extension files and read them if present:

1. `ralph/EXTENSIONS.md` — project-specific guidance for the ralph skills, organized in sections named after the skills. Read the `## General` section and the `## Address` section; ignore all other sections. Treat the content as guidance layered on top of this skill — it extends these instructions and never replaces them. If it conflicts with this skill's protocol (output files, document structure, workflow), this skill wins.
2. `ralph/PROMPT.md` — the project-local addendum appended to execution subagent prompts (build/test commands, conventions, gotchas). Read it as background context — it documents the build/test commands used to verify each fix and the conventions fixes must follow.

Both files are optional — missing files are the normal case; continue silently.

## Your task

Read `ralph/projects/<project-name>/review.md`, fix each finding, and record resolutions inline. Follow the methodology below in order.

---

## Methodology

### Step 1: Read the review

Read `ralph/projects/<project-name>/review.md` in full. Identify all findings under the **Findings** section (Critical, Important, Trivial). Note the severity and order.

### Step 2: Read project conventions

Read the `CLAUDE.md` in the repository root and any relevant subdirectory roots before making changes.

### Step 3: Address findings sequentially

Process findings **one at a time, in severity order**: Critical first, then Important, then Trivial.

For each finding:

1. **Read the relevant code** referenced in the finding.
2. **Implement the fix.** Follow the review's suggested fix if one is provided, or use your best judgment.
3. **Build and test** after each fix to verify nothing is broken. Use this project's build/test commands (check `ralph/PROMPT.md`, `CLAUDE.md`, or the plan's observations).
4. **Update the review document** — append a `> **Resolution:**` blockquote immediately after the finding's description, and append `— **FIXED**` to the finding's title line.

### Step 4: Preserve original finding text

**Critical:** When updating the review document, do NOT replace or remove the original finding description. The finding text must remain intact. Only add the resolution blockquote after it.

The result should look like:

```markdown
**I1. Description of the finding** — **FIXED**

File: `path/to/File.ext:42`

Original description of the problem, including any code snippets
and analysis from the reviewer...

> **Resolution:** Brief description of what was changed to fix the finding.
```

### Step 5: Findings that don't need fixing

Not every finding requires a code change. If a finding is acceptable as-is (especially Trivial findings), record why:

```markdown
> **Resolution:** Accepted as-is — <reason why this is acceptable>.
```

### Step 6: Use sub-agents for each finding

**To preserve context:** use a **separate sub-agent for each finding**. Run sub-agents **sequentially, not in parallel** — they may modify the same files and will conflict if run concurrently.

Each sub-agent should:
1. Read the relevant source files
2. Implement the fix
3. Build to verify (when applicable)
4. Update the review document with the resolution blockquote

### Step 7: Commit when done

After all findings are addressed, commit the changes:

```
chore: Address review findings for <project-name>
```

---

## What This Step Is NOT

- **Not a second review.** Fix what was found; don't go looking for new issues.
- **Not optional for Critical/Important findings.** Critical findings must be fixed before merging. Important findings should be fixed. Trivial findings are at the user's discretion.
- **Not a rewrite.** Make minimal, targeted changes that address each finding. Don't refactor surrounding code.

---

## When done

After addressing all findings, print:

```
Files modified:
- ralph/projects/<project-name>/review.md
- <list of source files changed>
```

Then summarize how many findings were fixed, accepted-as-is, and whether any remain unresolved.

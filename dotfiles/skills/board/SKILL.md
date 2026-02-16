---
name: board
description: Add PR or Issue to an aenix-org project board with optional phase.
argument-hint: "[phase] [project-number]"
disable-model-invocation: true
---

Add PR or Issue to an aenix-org project board with optional phase.

## Arguments

Parse $ARGUMENTS for:

- Phase name (optional): `backlog`, `progress`, `review`, `done`
- Project (optional): number or full URL, defaults to 6

Examples:

- `/board` → last mentioned PR/Issue, default project 6, guess phase
- `/board progress` → project 6, "In progress" phase
- `/board review 32` → project 32, review phase

## Cached Project Metadata

**Project 6 (default):**

- Project ID: `PVT_kwDOCiHiS84AlKLi`
- Status Field ID: `PVTSSF_lADOCiHiS84AlKLizgdQWHE`
- Status Options:
  - `d26068eb` → Backlog
  - `f75ad846` → Planned
  - `8ff00666` → In progress
  - `fe7e6f98` → Review
  - `7eb36378` → Locked
  - `98236657` → Done

For other projects, fetch dynamically:

```bash
gh project view <NUMBER> --owner aenix-org --format json --jq '.id'
gh project field-list <NUMBER> --owner aenix-org --format json --jq '.fields[] | select(.name == "Status") | {id, options}'
```

## Execution

1. **Determine target entity (PR or Issue):**
   - Look in conversation context for recently mentioned GitHub URLs
   - Pattern: `github.com/<owner>/<repo>/issues/<number>` or `github.com/<owner>/<repo>/pull/<number>`
   - Also check for "Issue #N" or "PR #N" mentions with repo context
   - If found: use that URL
   - If NOT found: try `gh pr view` for current branch
   - If still nothing: use AskUserQuestion to ask "Which PR or Issue to add?"

2. **Parse arguments:**
   - Extract project number from URL or bare number (default: 6)
   - Remaining word is phase name

3. **Add entity to project:**

   ```bash
   gh project item-add <PROJECT_NUMBER> --owner aenix-org --url <ENTITY_URL> --format json
   ```

   Extract item ID from response `.id` field.

4. **Assign to current user:**

   ```bash
   # For issues:
   gh issue edit <NUMBER> --repo <OWNER>/<REPO> --add-assignee @me
   # For PRs:
   gh pr edit <NUMBER> --repo <OWNER>/<REPO> --add-assignee @me
   ```

5. **Determine phase:**
   - If phase argument provided, map to option ID:
     - `backlog` → `d26068eb`
     - `planned` → `f75ad846`
     - `progress` → `8ff00666`
     - `review` → `fe7e6f98`
     - `done` → `98236657`
   - Otherwise guess based on state:
     - Issue: default to `backlog`
     - PR draft: `progress`
     - PR open: `review`
     - PR/Issue merged/closed: `done`
   - If unclear: use AskUserQuestion with available options

6. **Set phase:**

   ```bash
   gh project item-edit --project-id <PROJECT_ID> --id <ITEM_ID> --field-id <STATUS_FIELD_ID> --single-select-option-id <PHASE_OPTION_ID>
   ```

7. **Report result:**

   Output: "Added <TYPE> #<NUMBER> to project <PROJECT_NUMBER> → <PHASE_NAME>"

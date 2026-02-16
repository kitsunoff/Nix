---
name: learn
description: Analyze the current session and extract key learnings worth preserving.
disable-model-invocation: true
---

Analyze the current session and extract key learnings worth preserving.

## Classification

Separate findings into two categories:

**Personal** (~/CLAUDE.md):

- General patterns and approaches that work across projects
- Tool/language insights not specific to this codebase
- Workflow preferences discovered

**Project** (CLAUDE.md):

- Architecture decisions specific to this codebase
- Project-specific conventions and patterns
- Codebase quirks and gotchas
- Integration details with project's stack

## Process

1. Read the target file before proposing changes
2. Check for duplicates or overlapping content — skip if already covered
3. Decide where each item fits best within existing structure (don't create new sections unless nothing fits)
4. Formulate concisely, matching the style of existing content

## Output

Show proposed additions grouped by file:

```text
~/CLAUDE.md:
  - [where in file] addition text

CLAUDE.md:
  - [where in file] addition text
```

Ask for confirmation. Accept: "y", "yes", or selective like "only project" / "skip personal".

After confirmation, apply changes.

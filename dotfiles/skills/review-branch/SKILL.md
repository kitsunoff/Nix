---
name: review-branch
description: Review current branch changes in isolation. Output starts with LGTM verdict — if no LGTM, the code is not ready to merge.
argument-hint: "[base-branch] [--nitpick] [--type go|node|python|rust] [--exclude pattern,pattern]"
context: fork
agent: general-purpose
---

**Important**: If the current directory is not a git repository, ask the user where the target repository is located before proceeding.

**CRITICAL**: NEVER run `git checkout`, `git switch`, or any command that changes the current branch. You MUST stay on whatever branch is active when you start. All analysis must use `git diff`, `git log`, and file reads — never branch switching.

## Arguments

Parse $ARGUMENTS for:

- Base branch name (positional, e.g. `develop`)
- `--nitpick` flag for pedantic mode
- `--type` project type (e.g. `go`, `node`, `python`, `rust`) — skips auto-detection
- `--exclude` additional exclude patterns, comma-separated (e.g. `docs/,*.gen.go`)

Examples:

- `/review-branch` → auto-detect everything
- `/review-branch develop` → compare with develop
- `/review-branch --nitpick` → pedantic mode
- `/review-branch --type go --exclude "api/generated/"` → Go project, extra excludes
- `/review-branch develop --nitpick --type node` → all combined

## Setup

**First, record the current branch** (you will need it throughout):

```bash
REVIEW_BRANCH=$(git branch --show-current)
```

All analysis MUST be performed from this branch. Use `git diff`, `git log`, `git show` for comparisons — these do NOT require switching branches.

Determine base branch:

1. If branch argument provided: use it
2. Otherwise: detect via `git rev-parse --abbrev-ref @{upstream}` (tracking branch)
3. If no tracking branch: try `main`, fallback to `master`
4. If neither exists: report error and stop

Find the fork point:

```bash
MERGE_BASE=$(git merge-base $REVIEW_BRANCH <base-branch>)
```

## Getting the diff

1. If `--type` provided, use it. Otherwise detect the project type (Go, Node, Python, Rust, etc.) and build an exclude list dynamically:
   - Lock files (go.sum, package-lock.json, yarn.lock, Cargo.lock, poetry.lock, etc.)
   - Vendored dependencies (vendor/, node_modules/, third_party/, .vendor/)
   - Generated code (*.generated.*, *_generated.*, zz_generated.*, *.pb.go, etc.)
   - Build artifacts, minified files, etc.

2. Append any `--exclude` patterns from arguments.

3. Run the diff excluding those patterns:

   ```bash
   git diff <MERGE_BASE> -- . ':!<pattern1>' ':!<pattern2>' ...
   ```

   (Note: no HEAD — this compares the working tree against the fork point, capturing all changes including uncommitted ones.)

## Understanding the changes

You are NOT limited to the diff. When the diff alone is not enough to understand the change:

- Read full files to see surrounding context
- Read project documentation, READMEs, or comments
- Use web search to understand libraries, APIs, or patterns you don't recognize
- Check tests, configs, or related files that help clarify intent

Do whatever is needed to review competently. The diff is the starting point, not the boundary.

## Review criteria

Review the diff for:

- Bugs and logic errors
- Security issues
- Leaked secrets (tokens, API keys, passwords, private keys, credentials, hardcoded connection strings, .env values)
- Error handling gaps
- Code clarity and maintainability
- Naming and structure
- Tests coverage (if applicable)
- Where issues are found: suggest specific tests that would prove/demonstrate the problem exists (e.g. "a test that calls X with empty input would expose this nil pointer")
- Adjacent issues: if you find a problem, look at the surrounding code in the same area. If there are related issues nearby that are worth fixing in the same PR, flag them (not a full codebase audit — just the neighborhood of the changes)

<if --nitpick>
Pedantic mode: include style nitpicks, naming suggestions, minor improvements.
Leave no stone unturned.
</if>

<if not --nitpick>
Be direct. If something is fine, don't mention it.
Focus on what matters, skip nitpicks.
</if>

## Output format

Start your review with one of:

- **LGTM** — code is correct, safe, clear, and well-tested. May have minor cosmetic notes (listed as recommendations, not blockers)
- **NOT LGTM** — there are issues that must be addressed before merging

LGTM is a high bar. It means: no bugs, no security issues, no missing error handling, no logic gaps, no untested paths. The ONLY things allowed to pass with LGTM are cosmetic issues (naming style, minor formatting) — and even those must be listed as "Recommended to fix" in the review. Everything else blocks. When in doubt, do not LGTM.

Then provide the review as free-form text, like a human reviewer would write.

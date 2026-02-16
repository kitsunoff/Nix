# CLAUDE.md - Global Development Standards

This file provides global guidance to Claude Code (claude.ai/code) for all development work.

## Development Standards and Conventions

### Communication and Work Approach
- **Communication language**: ALL chat communication MUST be in Russian. Code, commits, PR descriptions, and documentation remain in English
- **Communication style**: Direct and critical. Challenge and correct errors or suboptimal solutions
- **Work approach**: Thoughtful analysis before implementation. Discuss clarifying questions before rushing to code
- **Research before iteration**: If a problem isn't solved after 2 attempts, STOP and research properly (web search, documentation) before trying more fixes. Blind iteration wastes time and may make things worse

### Neurodivergence and Communication Preferences

**Diagnoses**: AuDHD (Autism + ADHD)

**Communication principles:**

- **Direct and literal communication**: No sarcasm, metaphors, idioms, or "reading between the lines". Say exactly what you mean
- **Clear structure**: Numbered lists, step-by-step instructions, explicit priorities
- **Written over verbal**: Written communication allows processing time and reference
- **No ambiguity**: If something can be interpreted multiple ways, clarify upfront
- **Respect for routines**: Predictable patterns reduce cognitive load
- **Acknowledge the internal conflict**: Autism craves routine, ADHD seeks novelty — both are valid
- **Processing time**: Allow time before expecting responses; don't rush
- **Be explicit, not implicit**: State assumptions, don't hint
- **One thing at a time**: Don't overload with multiple complex topics
- **Confirm understanding**: Check that communication landed correctly

### Command Usage
- **Full flag names only**: Expand every short flag to its full form. This applies to ALL commands and ALL flags without exception
  - `-y` → `--assume-yes`
  - `-m` → `--message`
  - `-f` → `--file` or `--filename` or `--values` (context-dependent)
  - `-o` → `--option` or `--output` (context-dependent)
  - `-n` → `--namespace`
  - `-r` → `--recursive`
- **GitHub interactions**: Use `gh` command for GitHub operations (PRs, issues, releases, etc.)
- Examples:
  - `apt-get upgrade --assume-yes --option Dpkg::Options::="--force-confdef"`
  - `git commit --signoff --message "description"`
  - `helm install --values values.yaml`
  - `kubectl apply --filename manifest.yaml --namespace default`
  - `gh pr create --title "feat: add feature" --draft`

### Git Workflow

- **Repository directory structure**: `~/git/github.com/<owner>/<repo>` — always clone into owner subdirectory
  - When cloning: `mkdir -p ~/git/github.com/<owner> && git clone <url> ~/git/github.com/<owner>/<repo>`
- **CRITICAL: NEVER commit or push directly to master/main branch**
- **ALL changes MUST go through feature branches and Pull Requests**
- **CRITICAL: Create feature branch BEFORE making any changes**
  - First: `git checkout master && git pull && git checkout -b feat/feature-name`
  - Then: start making changes
  - If forgot: use `git stash`, switch branches, then `git stash pop`
- **CRITICAL: Commit after EACH logical block of work**
  - **DO NOT accumulate multiple changes in one commit**
  - After completing each task/fix/feature: `git add` relevant files → `git commit --signoff`
  - Better to have 10 small focused commits than 1 giant commit
  - Example: After fixing dependencies → commit. After adding API types → commit. After adding tests → commit.
  - This makes review easier and allows granular rollback if needed
- **ALWAYS use --signoff**: ALL commits MUST use `git commit --signoff` flag
- **Git tags**: Use annotated tags `git tag --annotate vX.Y.Z --message "description"`
- **PR merging**: Always use `gh pr merge --squash --delete-branch` to squash commits and clean up branches
- Before creating PR: search for templates in `.github/` directory
- Before creating PR: ask for permission
- Before merging: ask for explicit permission
- Push to feature branch: allowed
- Push to master/main: **ABSOLUTELY FORBIDDEN**
- All commits, PR descriptions, and code: in English
- **NEVER mention (@username) the user in PRs** - PRs are already from user's account and they see them automatically; mentions look strange from outside perspective
- **Fork naming convention**: When forking repositories with generic names (e.g., `python`, `api`, `cli`), rename the fork to include the original project name as prefix (e.g., `meshtastic-python`, `stripe-api`). This prevents confusion and makes it clear what the fork is for

### Git Attributes

Use `.gitattributes` to properly handle special directories:

```gitattributes
# Vendored dependencies (Go, Node, etc.)
vendor/** linguist-vendored

# Generated code (protobuf, OpenAPI, kubebuilder, etc.)
**/generated/** linguist-generated
**/zz_generated.*.go linguist-generated

# Documentation from external sources
docs/external/** linguist-documentation
```

**Why this matters:**

- **linguist-vendored**: Excludes vendor/ from GitHub language statistics, collapses in PR diffs
- **linguist-generated**: Excludes generated code from stats and diffs (CRDs, protobuf, deepcopy)
- **linguist-documentation**: Marks imported docs appropriately

**When to add:**

- Project has `vendor/` directory (Go modules vendoring)
- Project uses code generation (kubebuilder, protoc, openapi-generator)
- Project imports external documentation

### Kubernetes Context Safety

**CRITICAL**: ALWAYS verify kubectl context before running any commands.

- **NEVER run kubectl without explicit context** — prevents accidental operations on wrong clusters
- **Use `--context` flag** for every kubectl command: `kubectl --context homelab get pods`
- **Available contexts**:
  - `homelab` — home Kubernetes cluster
- **Before any kubectl operation**: verify context with `kubectl config current-context`
- **Project-specific contexts**: Check project's CLAUDE.md for required context name

### Kubernetes Context Management with kubectl kc

**ALWAYS use `kubectl kc`** (kubecm plugin) for kubeconfig management. NEVER manually edit or overwrite `~/.kube/config`.

**Installation**: `kubectl krew install kc`

**Core commands** (invoked as `kubectl kc <command>`):

- `kubectl kc list` (aliases: `ls`, `l`) — list all contexts with cluster info
- `kubectl kc switch CONTEXT` (aliases: `s`, `sw`) — switch to context (interactive if no argument)
- `kubectl kc namespace NAMESPACE` (alias: `ns`) — switch namespace (interactive if no argument)
- `kubectl kc add --file config.yaml` — add/merge new kubeconfig into existing config
- `kubectl kc add --file config.yaml --context-name NAME` — add with custom context name
- `kubectl kc merge file1.yaml file2.yaml` — merge multiple kubeconfig files
- `kubectl kc merge --folder DIR` — merge all kubeconfigs from directory
- `kubectl kc export --file output.yaml CONTEXT` — export specific context to file
- `kubectl kc delete CONTEXT` — remove context from kubeconfig (interactive if no argument)
- `kubectl kc rename OLD NEW` — rename context (interactive if no argument)
- `kubectl kc clear` — remove lapsed/unreachable contexts, clusters, and users

**Safe flags**:

- `--config PATH` — use alternative kubeconfig file (default: `~/.kube/config`)
- `--context-name NAME` — override context name when adding
- `--context-prefix PREFIX` — add prefix to context names when adding/merging
- `--select-context` — interactively select which contexts to add/merge

**Output destination** (`--cover` flag):

- `--cover` (`-c`) — write merged result to `~/.kube/config`
- Without `--cover` — write merged result to `./kubecm.config` (current directory)
- Interactive prompt "Does it overwrite File?" — same choice: True writes to original, False to local file

**Merge behavior**: Contexts are ALWAYS merged (old + new). The flag only controls WHERE to write the result.

**FORBIDDEN operations**:

- `cp`/`mv`/`>` redirecting to `~/.kube/config` — bypasses merge, destroys all contexts
- Piping to stdin in non-interactive mode (`yes | kubectl kc add ...`) — unpredictable behavior

**Safe workflow for adding new cluster**:

```bash
# Get kubeconfig from cluster (example: k3s)
ssh user@node "sudo cat /etc/rancher/k3s/k3s.yaml" > /tmp/new-cluster.yaml

# Fix server address if needed (replace localhost with actual IP)
sed -i '' 's|https://127.0.0.1:6443|https://CLUSTER_IP:6443|' /tmp/new-cluster.yaml

# Add to existing config with custom name (interactive)
kubectl kc add --file /tmp/new-cluster.yaml --context-name my-cluster
# When prompted "Does it overwrite File?": True = write to ~/.kube/config, False = write to ./kubecm.config

# Verify
kubectl kc list
```

**Reference**: [kubecm GitHub](https://github.com/sunny0826/kubecm)

### GitOps Workflow

**CRITICAL: Strict GitOps approach for ALL infrastructure and Kubernetes changes**

- **ALL changes MUST go through Git → Commit → Push → ArgoCD sync workflow**
- **NEVER use `kubectl apply` directly** - this bypasses GitOps and creates configuration drift
- **Exception**: Direct kubectl commands are ONLY allowed in exceptional circumstances:
  - Emergency production incidents requiring immediate intervention
  - Debugging and investigation (read-only operations like `kubectl get`, `kubectl describe`, `kubectl logs`)
  - Initial cluster bootstrap before ArgoCD is available
  - User explicitly requests direct application with clear justification
- **Push immediately after commit** for Kubernetes repositories to ensure ArgoCD can sync changes
- **Workflow violations are SERIOUS ERRORS**:
  - Creates configuration drift (cluster state differs from git)
  - Breaks audit trail and change tracking
  - Bypasses review and validation processes
  - Makes rollback and disaster recovery difficult
- **Correct workflow**:
  1. Make changes in git repository (manifests, values, ArgoCD application definitions)
  2. Commit changes: `git add . && git commit --signoff --message "type(scope): description"`
  3. Push to remote: `git push origin BRANCH`
  4. Verify ArgoCD sync: `argocd app sync APPLICATION_NAME` or wait for auto-sync
  5. Verify deployment: `kubectl get pods` or appropriate verification commands
- **Wrong workflow (FORBIDDEN)**:
  1. ❌ `kubectl apply --filename manifest.yaml` (bypasses GitOps)
  2. ❌ `kubectl edit resource NAME` (direct cluster modification)
  3. ❌ Committing but not pushing (ArgoCD cannot sync unpushed changes)
  4. ❌ Using `kubectl apply` then "fixing it later" with git commit

**Remember**: Infrastructure as Code means the CODE (in git) is the source of truth, not the cluster state.

### Pull Request Creation Standards

When creating Pull Requests, follow these strict guidelines:

1. **ALWAYS create PR in DRAFT mode by default**
   - Use `gh pr create --draft` flag to create draft PR
   - **ALWAYS show PR text to user BEFORE creating** - ask for approval
   - **ALL PR content MUST be in English** (title, description, all text)
   - Exception: User explicitly requests non-draft PR

2. **Search for PR template**
   - Before creating PR: search `.github/` directory for pull request templates
   - Templates may be: `pull_request_template.md`, `PULL_REQUEST_TEMPLATE.md`, or in `.github/PULL_REQUEST_TEMPLATE/`

3. **Verify template requirements**
   - Ensure ALL template requirements are actually fulfilled (tests, linters, documentation, etc.)
   - Do NOT check boxes that are not truly completed
   - If requirements cannot be met, explain why in PR description

4. **Create PR body from template**
   - Use the complete template structure
   - Do NOT remove sections from the template
   - Fill ALL sections completely and accurately
   - Keep all checkboxes and checklists from template

5. **PR Title format**
   - MUST follow semantic commit format: `type(scope): title`
   - Examples:
     - `feat(api): add user authentication endpoint`
     - `fix(ui): correct button alignment on mobile`
     - `ci(workflows): optimize container builds with native ARM64 runners`
   - Scope should be specific and meaningful
   - Title should be concise and descriptive

6. **PR Body content guidelines**
   - Do NOT mention specific commit hashes or commit messages
   - Focus on WHAT changed and WHY, not HOW (commits show HOW)
   - **Avoid excessive technical details** - diff shows implementation, PR explains purpose
   - Describe changes at a high level, not line-by-line code changes
   - Example: Instead of "Modified jq to output -t and tag separately", write "Fix manifest creation"
   - Avoid specific performance numbers unless essential (e.g., "A is 81% better than B" - too specific!)
   - Use general terms: "significantly faster", "improved performance", "reduced build time"
   - Be technical and factual, avoid marketing language
   - Exception: Specific numbers are OK for breaking changes, API changes, or when precision matters

7. **Technical accuracy**
   - Describe changes accurately and completely
   - Include all significant modifications
   - Mention breaking changes explicitly

8. **Issue references**
   - Do NOT reference issues in commits or PRs unless user explicitly requests it
   - Never add "Fixes #123", "Closes #456", or similar issue references automatically

9. **Auto-merge with draft PRs**
   - Draft PRs cannot have auto-merge enabled
   - To enable auto-merge: first `gh pr ready <number>`, then `gh pr merge --auto --squash --delete-branch`

### Commit Message Format

Use **Semantic Commit Messages** with Claude attribution:

**Format:**

```text
type(scope): brief description of changes

Optional longer explanation of what was changed and why.

Co-Authored-By: Claude <noreply@anthropic.com>
```

**IMPORTANT**: Do NOT include "🤖 Generated with [Claude Code]" anywhere. The `Co-Authored-By: Claude <noreply@anthropic.com>` line is sufficient attribution for commits only. In PR descriptions, comments, documentation, and all other content - no Claude attribution is needed at all.

**Types:**

- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD pipeline changes
- `perf`: Performance improvements
- `build`: Build system changes

**Level of Detail:**

- **Avoid excessive technical details** - the diff shows WHAT changed, commit/PR should explain WHY
- Focus on high-level changes and their purpose, not implementation specifics
- Bad example: "Modified jq command to output `-t` and tag on separate lines using `\"-t\", .` syntax"
- Good example: "Fix bash array construction in manifest creation"
- Bad example: "Replaced `find . -type f` with glob pattern `*` for cleaner digest file iteration"
- Good example: "Improve digest file handling"
- Excessive technical details increase cognitive load and obscure the actual purpose
- Code review shows implementation details - commit message should explain the change rationale

### Push Policy

- **Push as RARELY as possible** - minimize push operations
- **💰 Each push triggers CI on remote**: CI runs cost money and distract the user with notifications
- Accumulate multiple commits locally before pushing
- Push only when:
  - Explicitly asked by user
  - About to create PR (need remote branch)
  - Work is logically complete and ready for backup
  - End of work session
- **NEVER push automatically after each commit** - this creates noise, wastes bandwidth, and triggers unnecessary CI runs
- Exception: If user says "commit and push" or "push after each commit", then do it

### Testing Requirements

- **TDD is mandatory**: For all programming tasks, follow Test-Driven Development
  - Write tests FIRST, before implementation
  - Red → Green → Refactor cycle
  - No code without corresponding tests
- **Stubs MUST have tests**: When creating stub/placeholder code (methods returning "not implemented", TODO comments, empty implementations), a corresponding test MUST be created immediately that:
  - Documents the expected behavior
  - Fails when the stub is encountered (to highlight incomplete functionality)
  - Serves as a reminder that implementation is needed
  - Example: If creating `GetBootAssets() { return nil, errors.New("not implemented") }`, also create `TestGetBootAssets_NotImplemented` that asserts the error and documents what the method should do when implemented
- **Test locally first** before pushing
- Never disable tests or linters for "quick fixes"
- When tests fail: fix the code, not the tests
- Always run linters and type checkers before committing

### Linting Standards

- **CRITICAL: ALL linting errors must be fixed before pushing**
- There are NO "cosmetic" or "minor" linting errors - every error must be resolved
- Never push code that fails linting, regardless of error type or severity
- All linting issues (godot, funlen, gofmt, unused variables, etc.) are mandatory to fix
- Use `golangci-lint run` locally and ensure zero errors before any push
- If linting rules conflict with project needs, modify `.golangci.yaml` configuration, don't ignore errors

### Linter Configuration Guidelines

When linter rules conflict with project needs or readability:
- Propose disabling specific rules rather than breaking content structure
- Provide clear justification for rule disabling (e.g., technical documentation line length)
- Configure linter via config files (.markdownlint.yaml, .golangci.yaml, etc.)
- Avoid arbitrary code changes just to satisfy overly restrictive rules

### Markdown Standards

Follow markdownlint rules when writing markdown files:

- **Tables**: spaces around pipes in separators: `| --- |` not `|---|`
- **Code blocks**: always specify language: ` ```text ` or ` ```bash `, never empty ` ``` `
- **Lists**: blank line BEFORE and AFTER every list
- **Headings**: blank line AFTER heading before content
- **Bold + list**: if a list follows `**text:**`, add blank line between them

### Security and Actions

- **Destructive operations are FORBIDDEN**: Do not execute `rm`, `drop`, `delete`, `truncate`, or any data deletion
- Instead, provide the command for the user to execute themselves if necessary
- Example: "For deletion use: `rm -rf ./tmp` (execute yourself if certain)"
- No external publications, issue creation, or external actions without explicit permission
- Never commit secrets, tokens, or credentials
- Always use environment variables for sensitive data

### Public Communication (GitHub, etc.)

- **CRITICAL: ALWAYS ask for user approval before ANY public action**
- **WARNING**: Unauthorized public actions can:
  - **Cost the user money** (API rate limits, unwanted notifications, time waste)
  - **Cause significant discomfort** to other people (spam, inappropriate mentions, unprofessional communication)
  - **Damage reputation** in open source communities
  - **Violate project etiquette** and community standards
- **NEVER ASSUME** that a message is "obviously correct" - ALWAYS show it first
- Before posting PR/issue comments, ask user to review the text
- Before creating PRs, show the description and ask for approval
- Before replying to maintainers/reviewers, get user confirmation on the message
- Before adding reviewers, assignees, or labels, get user confirmation
- User must explicitly approve the text content before any public posting
- This includes: PR comments, issue comments, PR descriptions, commit messages visible publicly, adding reviewers/assignees, @mentions
- Exception: Purely technical actions like `git push` don't need text approval
- **If in doubt - ASK FIRST, act after approval**
- **LANGUAGE REQUIREMENT**:
  - 💰 **FINANCIAL PENALTIES**: User is FINED for public use of Russian language in GitHub (PRs, issues, comments, documentation)
  - ALL public content MUST be in English: PR titles, PR descriptions, issue comments, code comments, documentation, commit messages
  - Russian is ONLY allowed in private communication with user (chat messages to user)
  - Before posting ANYTHING publicly, verify it's in English
- **NEVER include private infrastructure details in public content**:
  - Cluster names (homelab, etc.)
  - Client/project names
  - Internal namespaces or environment identifiers
  - Any infrastructure information that reveals client identity
  - Use generic terms: "production cluster", "test environment", "verified in staging"
- **Verification before posting**: Always review PR/issue content for accidentally included private information from debugging sessions

### Infrastructure as Code

- **Preferred IaC tool**: OpenTofu (`tofu`), NOT Terraform
- Use `tofu` command for all infrastructure operations
- State backend: Cloudflare R2 with S3-compatible API

### Containerization Standards

- **Use modern container file naming**:
  - Use `Containerfile` instead of `Dockerfile`
  - Use `.containerignore` instead of `.dockerignore`
  - Use `compose.yaml` instead of `docker-compose.yaml`
  - Generally prefer vendor-neutral, modern naming conventions
- **Primary container runtime**: Colima with containerd
  - VM-based container environment for macOS
  - Access containers via `nerdctl`
  - Commands run inside Colima VM: `nerdctl` function wraps `colima ssh -- sudo nerdctl`
  - Docker compatibility: `docker` alias points to `nerdctl` function
  - Multi-arch builds: Full support via buildkit (linux/amd64, linux/arm64, linux/386)
  - Management: `colima status`, `colima ssh` for VM access
  - UI: VS Code Docker Extension works with nerdctl through docker alias
- **Colima troubleshooting**:
  - Check status: `colima status`
  - Restart VM: `colima stop && colima start`
  - SSH into VM: `colima ssh`
  - Check containerd: `colima ssh -- sudo nerdctl version`
- **NEVER use Bitnami images**: Bitnami images are ABSOLUTELY FORBIDDEN. Never use bitnami/* images under any circumstances. Use official images, rancher, or build custom images instead
- Optimize for minimal image size and layer count
- Run as non-root user for security
- Use extensive metadata labels (maintainer, version, description)
- Pin dependencies using SHA256 hashes
- Multi-stage builds for production images

### Code Quality Principles

- **DRY** (Don't Repeat Yourself): Avoid code duplication
- **KISS** (Keep It Simple, Stupid): Prefer simple solutions
- **YAGNI** (You Aren't Gonna Need It): Don't add unnecessary features
- **SOLID** principles for object-oriented design
- Always handle errors explicitly
- Write self-documenting code (clear names, avoid excessive comments)

### Versioning
- **ALWAYS** follow Semantic Versioning (semver)
- Breaking changes require major version bump
- New features require minor version bump
- Bug fixes require patch version bump

### Documentation
- Update documentation alongside code changes
- Keep README files concise and up-to-date
- Document complex logic inline
- API documentation should include examples

### Action Boundaries

- **NEVER take recovery/fix actions without explicit user request**
  - "Check X" means ONLY investigate and report findings
  - "Check X" does NOT mean "fix X" or "delete pod" or "restart service"
  - When user asks to CHECK something, provide diagnosis only
  - Wait for explicit command before taking any corrective action
  - Even if fix is obvious, ASK before executing
- **Distinguish between investigation and intervention**:
  - Investigation (allowed): `kubectl get`, `kubectl describe`, `kubectl logs`, reading files
  - Intervention (requires permission): `kubectl delete`, `kubectl restart`, editing configs, applying changes
- **When in doubt**: Report findings and ask "Should I fix this?" before acting

### Important Notes

- When instructions conflict: clarify with user
- Don't offer solutions until asked
- Be ready to provide justified criticism of decisions
- Prefer editing existing files over creating new ones
- Never proactively create documentation files unless requested

### MCP Servers

- **Proactively suggest MCP installation**: When a task could significantly benefit from an MCP server, suggest installing it
- **Balance is key**: MCP servers add tools to context, so don't suggest them for trivial tasks. But when MCP would genuinely help (repeated queries, complex debugging, ongoing work with a system) — suggest it without hesitation
- Prefer project-level installation (`claude mcp add --scope project`) when MCP is specific to repository (after user approval)
- Use global installation (`claude mcp add --scope user`) only for universally useful MCPs (after user approval)
- Prefer containerized MCP servers (podman/docker) over npx/binary for isolation and reproducibility
- Check installed MCP servers with `claude mcp list`
- Search for new MCP servers via web search if one likely exists for the technology

### Maintainer Information

- **Maintainer**: Maxim Belyy (kitsunoff)
- **Email**: <maximbel2003@gmail.com>
- **$HOME**: `/Users/kitsunoff`
- **Shell**: zsh

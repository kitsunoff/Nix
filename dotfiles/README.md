# AI Tools Configuration

Configuration for AI coding assistants: OpenCode, Claude Code, Qwen Code.

## Structure

```
dotfiles/
├── agents/              # OpenCode agents (or shared)
├── agents-claude/       # Claude Code agents
├── agents-qwen/         # Qwen Code agents
└── README.md
```

## Supported Tools

- **OpenCode** → `~/.config/opencode/agents/`
- **Claude Code** → `~/.claude/agents/`
- **Qwen Code** → `~/.qwen/agents/`

## How It Works

Each tool has its own agents directory to support tool-specific formats:

- **Separate directories** - no format conflicts
- **Tool-specific features** - use what each tool supports best
- **Simple management** - edit files directly, no conversion needed

## Usage

### Add a prompt

```bash
echo "Your prompt content" > dotfiles/prompts/my-prompt.md
```

### Add an agent

```bash
echo "Agent configuration" > dotfiles/agents/my-agent.md
```

After adding files, run rebuild or files become available automatically (via symlinks).

## Benefits

✓ Single source of truth for all tools
✓ Version control with Git
✓ Automatic deployment
✓ Works on both macOS and NixOS

## OpenCode Configuration

OpenCode configuration is dynamically generated from Nix options in your system config.

### Current Configuration

```nix
programs.opencode = {
  enable = true;
  plugins = [
    "opencode-alibaba-qwen3-auth"  # Qwen OAuth plugin (2,000 free requests/day)
  ];
  defaultModel = "alibaba/coder-model";
};
```

### Adding Plugins

Edit your system configuration (e.g., `darwin/MacBook-Pro-Maxim/default.nix`):

```nix
programs.opencode.plugins = [
  "opencode-alibaba-qwen3-auth"
  "your-other-plugin"
];
```

Then run `darwin-rebuild switch` to apply changes.

### Configuration File Location

Generated at: `~/.config/opencode/opencode.json`

The file is automatically created/updated on system rebuild.

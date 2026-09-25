# My default values for AI assistants
# Can be overridden per-host in homeConfig
{ lib, ... }:
{
  flake.homeModules.ai-assistants-defaults =
    { ... }:
    {
      programs.aiCodeAssistants = {
        enable = lib.mkDefault true;

        vibeKanban.enable = lib.mkDefault true;
        context7.enable = lib.mkDefault true;
        nixos.enable = lib.mkDefault true;

        opencode = {
          enable = lib.mkDefault true;
          agentsPath = lib.mkDefault ../../dotfiles/agents;
          skillsPath = lib.mkDefault ../../dotfiles/skills;
        };

        claudeCode = {
          enable = lib.mkDefault true;
          agentsPath = lib.mkDefault ../../dotfiles/agents-claude;
          claudeMdPath = lib.mkDefault ../../dotfiles/CLAUDE.md;
          skillsPath = lib.mkDefault ../../dotfiles/skills;
          marketplaces = lib.mkDefault {
            claude-code-companions.repo = "lexfrei/ccc";
            claude-plugins-official.repo = "anthropics/claude-plugins-official";
            # Switch to `cozystack/ccp` on main once https://github.com/cozystack/ccp/pull/3
            # is merged (drop the `branch` field and change `repo` to `cozystack/ccp`).
            cozystack-ccp = {
              repo = "kitsunoff/ccp";
              branch = "feat/cozy-external-app-skill";
            };
            # Private repo; cloned via the gh git-credential helper.
            # Drop the `branch` field once https://github.com/kitsunoff/agent-plugins/pull/1 is merged.
            agent-plugins = {
              repo = "kitsunoff/agent-plugins";
              branch = "feat/research-kit";
            };
          };
          enabledPlugins = lib.mkDefault [
            # Skills
            "review-toolkit@claude-code-companions"
            "tldrpr@claude-code-companions"
            # Hooks
            "trailer-guard@claude-code-companions"
            # MCP servers
            "mcp-loki@claude-code-companions"
            "mcp-tg@claude-code-companions"
            "playwright@claude-plugins-official"
            "telegram@claude-plugins-official"
            # Cozystack plugins
            "cozy-deploy@cozystack-ccp"
            "cozy-external-app@cozystack-ccp"
            # Research plugins
            "research-kit@agent-plugins"
          ];
        };

        qwenCode = {
          enable = lib.mkDefault true;
          agentsPath = lib.mkDefault ../../dotfiles/agents-qwen;
        };

        claudeDesktop.enable = lib.mkDefault true;
      };
    };
}

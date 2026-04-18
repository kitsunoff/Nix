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
          };
          enabledPlugins = lib.mkDefault [
            # Agents
            "task-orchestrator@claude-code-companions"
            "tech-oracle@claude-code-companions"
            "gopher-builder@claude-code-companions"
            "snake-charmer@claude-code-companions"
            "templ-weaver@claude-code-companions"
            "kube-pilot@claude-code-companions"
            "chart-builder@claude-code-companions"
            "docker-smith@claude-code-companions"
            "code-guardian@claude-code-companions"
            "doc-curator@claude-code-companions"
            # Skills
            "review-toolkit@claude-code-companions"
            "git-tools@claude-code-companions"
            "genname@claude-code-companions"
            "tldrpr@claude-code-companions"
            "learn@claude-code-companions"
            "renovate-check@claude-code-companions"
            "agent-father@claude-code-companions"
            # MCP servers
            "mcp-loki@claude-code-companions"
            "mcp-transmission@claude-code-companions"
            "mcp-tg@claude-code-companions"
          ];
        };

        qwenCode = {
          enable = lib.mkDefault true;
          agentsPath = lib.mkDefault ../../dotfiles/agents-qwen;
        };
      };
    };
}

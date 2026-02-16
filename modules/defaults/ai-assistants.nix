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
          agentsPath = lib.mkDefault ../dotfiles/agents;
          skillsPath = lib.mkDefault ../dotfiles/skills;
        };

        claudeCode = {
          enable = lib.mkDefault true;
          agentsPath = lib.mkDefault ../dotfiles/agents-claude;
          claudeMdPath = lib.mkDefault ../dotfiles/CLAUDE.md;
          skillsPath = lib.mkDefault ../dotfiles/skills;
        };

        qwenCode = {
          enable = lib.mkDefault true;
          agentsPath = lib.mkDefault ../dotfiles/agents-qwen;
        };
      };
    };
}

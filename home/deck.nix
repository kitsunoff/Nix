# Home Manager configuration for Steam Deck user deck
{
  pkgs,
  lib,
  ...
}:

{
  # Allow unfree packages (claude-code)
  nixpkgs.config.allowUnfree = true;

  imports = [
    # Import our custom home-manager modules
    ../modules/home-manager/opencode.nix
    ../modules/home-manager/ai-code-assistants.nix
  ];

  # Home Manager configuration
  home = {
    username = "deck";
    homeDirectory = lib.mkForce "/home/deck";

    stateVersion = "24.11";

    packages = with pkgs; [
      # VSCode
      vscode

      # Task management
      beads # AI coding agent memory system with graph-based issue tracking
      lazybeads # TUI for beads (vim-style navigation)
    ];
  };

  # Programs configuration
  programs = {
    # AI Code Assistants configuration
    aiCodeAssistants = {
      enable = true;

      # ========== Built-in MCP Servers ==========
      vibeKanban.enable = true;
      context7.enable = true;
      nixos.enable = true;

      # ========== OpenCode configuration ==========
      opencode = {
        enable = true;
        agentsPath = ../dotfiles/agents;
        plugins = [ ];
        defaultModel = null;
        extraConfig = { };
        skillsPath = ../dotfiles/skills;
      };

      # ========== Claude Code configuration ==========
      claudeCode = {
        enable = true;
        agentsPath = ../dotfiles/agents-claude;
      };
    };

    # Git configuration
    git = {
      enable = true;
      settings = {
        user = {
          name = "deck";
          email = "deck@steamdeck.local"; # Update with your email
        };
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };

    # GitHub CLI
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings = {
        git_protocol = "https";
        editor = "code";
      };
    };

    # Let Home Manager install and manage itself
    home-manager.enable = true;
  };
}

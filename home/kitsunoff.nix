# Home Manager configuration for user kitsunoff
# User-specific configuration separated from system configuration
{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Import our custom home-manager modules
    ../modules/home-manager/opencode.nix # OpenCode extension module
    ../modules/home-manager/ai-code-assistants.nix # Unified AI assistants module
  ];

  # Home Manager configuration
  home = {
    # Home Manager needs a bit of information about you and the paths it should manage
    username = "kitsunoff";
    homeDirectory = lib.mkForce "/Users/kitsunoff";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "24.11";

    # User-specific packages (not system-wide)
    packages = with pkgs; [
      # Add user-specific packages here
    ];
  };

  # Programs configuration
  programs = {
    # AI Code Assistants configuration
    aiCodeAssistants = {
      enable = true;

      # ========== Built-in MCP Servers ==========
      vibeKanban.enable = true; # Канбан доска для AI агентов (+ CLI)
      context7.enable = true; # Актуальная документация библиотек
      nixos.enable = true; # NixOS пакеты, опции, Home Manager

      # ========== OpenCode configuration ==========
      opencode = {
        enable = true;
        agentsPath = ../dotfiles/agents;
        plugins = [
          "opencode-alibaba-qwen3-auth"
        ];
        defaultModel = "alibaba/coder-model";
        extraConfig = { };

        # Native OpenCode skills (uses ~/.opencode/skill/ directory)
        skillsPath = ../dotfiles/skills;
      };

      # ========== Claude Code configuration ==========
      claudeCode = {
        enable = true;
        agentsPath = ../dotfiles/agents-claude;
      };

      # ========== Qwen Code configuration ==========
      qwenCode = {
        enable = true;
        agentsPath = ../dotfiles/agents-qwen;
      };
    };

    # Git configuration (example of user-level config)
    git = {
      enable = true;

      # Use new settings format (old userName/userEmail deprecated)
      settings = {
        user = {
          name = "kitsunoff";
          email = "kitsunoff@example.com"; # Update with your email
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
        editor = "nvim";
      };
    };

    # Let Home Manager install and manage itself
    home-manager.enable = true;
  };

  # Zsh configuration
  # Note: Existing .zshrc found, not managing through home-manager
  # To enable home-manager zsh management:
  # 1. Backup: mv ~/.zshrc ~/.zshrc.backup
  # 2. Uncomment below and add content to initExtra

  # programs.zsh = {
  #   enable = true;
  #   enableCompletion = true;
  #
  #   initExtra = ''
  #     # Homebrew
  #     eval "$(/opt/homebrew/bin/brew shellenv)"
  #     export PATH="$HOME/.local/bin:$PATH"
  #
  #     # Yandex Cloud
  #     [ -f '/Users/kitsunoff/yandex-cloud/path.bash.inc' ] && source '/Users/kitsunoff/yandex-cloud/path.bash.inc'
  #     [ -f '/Users/kitsunoff/yandex-cloud/completion.zsh.inc' ] && source '/Users/kitsunoff/yandex-cloud/completion.zsh.inc'
  #
  #     # OpenCode
  #     export PATH=/Users/kitsunoff/.opencode/bin:$PATH
  #   '';
  #
  #   shellAliases = {
  #     ll = "ls -la";
  #   };
  #
  #   oh-my-zsh = {
  #     enable = true;
  #     theme = "robbyrussell";
  #     plugins = [ "git" "docker" "kubectl" ];
  #   };
  # };
}

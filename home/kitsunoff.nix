# Home Manager configuration for user kitsunoff
# User-specific configuration separated from system configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    # Import our custom home-manager modules
    ../modules/home-manager/opencode.nix          # OpenCode extension module
    ../modules/home-manager/ai-code-assistants.nix # Unified AI assistants module
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "kitsunoff";
  home.homeDirectory = lib.mkForce "/Users/kitsunoff";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # User-specific packages (not system-wide)
  home.packages = with pkgs; [
    # Add user-specific packages here
  ];

  # AI Code Assistants configuration
  # Each tool has its own agents directory
  programs.aiCodeAssistants = {
    enable = true;
    
    # OpenCode configuration
    opencode = {
      enable = true;
      agentsPath = ../dotfiles/agents;
      plugins = [ 
        "opencode-alibaba-qwen3-auth"
        "opencode-skills"  # Skills plugin by malhashemi
      ];
      defaultModel = "alibaba/coder-model";
      extraConfig = {};
      
      # Skills configuration (opencode-skills plugin)
      # Each skill directory will be mapped to ~/.config/opencode/skills/<skill-name>/
      skills = {
        enable = true;
        sources = [
          # Your dotfiles skills (flat mapping)
          # dotfiles/skills/example-skill/ → ~/.config/opencode/skills/example-skill/
          {
            name = "dotfiles";  # Just a label
            package = ../dotfiles/skills;
            skillsDir = ".";
          }
          
          # Superpowers skills from obra/superpowers
          {
            name = "superpowers";
            package = pkgs.fetchFromGitHub {
              owner = "obra";
              repo = "superpowers";
              rev = "main";
              sha256 = "sha256-1zVdDfdmyp2rKnrhSPfnNLkYF5ZJpjLE33LBVj7iC5g=";
            };
            skillsDir = "skills";
          }
        ];
      };
    };
    
    # Claude Code configuration
    # Agents will be symlinked to ~/.claude/agents/
    claudeCode = {
      enable = true;
      agentsPath = ../dotfiles/agents-claude;
    };
    
    # Qwen Code configuration
    # Agents will be symlinked to ~/.qwen/agents/
    qwenCode = {
      enable = true;
      agentsPath = ../dotfiles/agents-qwen;
    };
  };

  # Git configuration (example of user-level config)
  programs.git = {
    enable = true;
    
    # Use new settings format (old userName/userEmail deprecated)
    settings = {
      user = {
        name = "kitsunoff";
        email = "kitsunoff@example.com";  # Update with your email
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
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

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # DEBUG: Test file to verify home.file works
  home.file.".config/opencode/TEST_FILE.txt".text = "This is a test file from home-manager";
}

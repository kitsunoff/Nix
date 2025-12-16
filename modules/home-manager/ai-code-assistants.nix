# AI Code Assistants module
# Separate configuration for OpenCode, Claude Code, Qwen Code
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.aiCodeAssistants;

  # Simple helper to create agents attrset from directory
  mkAgentsFromDir = agentsPath: 
    if agentsPath == null then {}
    else
      let
        agentFiles = builtins.readDir agentsPath;
        agentsAttrset = lib.mapAttrs' (name: type:
          let
            agentName = lib.removeSuffix ".md" name;
          in
            lib.nameValuePair agentName (agentsPath + "/${name}")
        ) (lib.filterAttrs (name: type: 
          type == "regular" && lib.hasSuffix ".md" name
        ) agentFiles);
      in
        agentsAttrset;

in {
  options.programs.aiCodeAssistants = {
    enable = mkEnableOption "AI Code Assistants configuration";

    opencode = {
      enable = mkEnableOption "OpenCode";
      
      agentsPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "./dotfiles/agents-opencode";
        description = "Path to OpenCode agents directory";
      };
      
      plugins = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "opencode-alibaba-qwen3-auth" ];
        description = "List of OpenCode plugins";
      };

      defaultModel = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "alibaba/coder-model";
        description = "Default model for OpenCode";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Extra configuration for OpenCode";
      };

      superpowers = {
        enable = mkEnableOption "Superpowers plugin for OpenCode";
        
        package = mkOption {
          type = types.package;
          default = pkgs.fetchFromGitHub {
            owner = "obra";
            repo = "superpowers";
            rev = "main";  # You can pin to specific commit for reproducibility
            sha256 = "sha256-160bw8z5dhbjvz2359j9jqbiif9lwzvliqbs5amrvjk6yw6msdfp";
          };
          description = ''
            Superpowers plugin package source.
            Default: fetches from official GitHub repository (main branch).
            
            You can override this with your own derivation or specific version:
            - Pin to specific commit for reproducibility
            - Use your own fork
            - Point to local directory during development
          '';
          example = literalExpression ''
            # Pin to specific commit
            pkgs.fetchFromGitHub {
              owner = "obra";
              repo = "superpowers";
              rev = "abc123...";  # specific commit hash
              sha256 = "sha256-...";
            }
            
            # Or use local directory for development
            /path/to/local/superpowers
          '';
        };

        # Skills sources to install
        skills = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name of the skills source (used for directory naming)";
                example = "superpowers";
              };

              package = mkOption {
                type = types.package;
                description = "Package source for skills";
                example = literalExpression ''
                  pkgs.fetchFromGitHub {
                    owner = "username";
                    repo = "my-skills";
                    rev = "main";
                    sha256 = "sha256-...";
                  }
                '';
              };

              skillsDir = mkOption {
                type = types.str;
                default = "skills";
                description = "Path to skills directory inside the package";
                example = "skills";
              };
            };
          });
          default = [];
          description = ''
            Skills sources to install.
            Each source will be symlinked to ~/.config/opencode/skills/<name>/
            
            To install official superpowers skills, add them explicitly to the list.
            
            Skills priority (highest to lowest):
            1. Project skills (.opencode/skills/)
            2. Personal skills (~/.config/opencode/skills/)
            3. Installed skills sources (in order of list)
          '';
          example = literalExpression ''
            [
              # Official superpowers skills
              {
                name = "superpowers";
                package = pkgs.fetchFromGitHub {
                  owner = "obra";
                  repo = "superpowers";
                  rev = "main";
                  sha256 = "sha256-...";
                };
                skillsDir = "skills";
              }
              # Your custom skills
              {
                name = "my-custom";
                package = pkgs.fetchFromGitHub {
                  owner = "username";
                  repo = "my-skills";
                  rev = "main";
                  sha256 = "sha256-...";
                };
                skillsDir = "skills";
              }
              # Company/team skills
              {
                name = "company-standards";
                package = pkgs.fetchFromGitHub {
                  owner = "company-org";
                  repo = "ai-skills";
                  rev = "v1.2.0";
                  sha256 = "sha256-...";
                };
                skillsDir = "opencode/skills";
              }
              # Local development skills
              {
                name = "local";
                package = /path/to/local/skills;
                skillsDir = ".";
              }
            ]
          '';
        };
      };
    };

    claudeCode = {
      enable = mkEnableOption "Claude Code";
      
      agentsPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "./dotfiles/agents-claude";
        description = "Path to Claude Code agents directory";
      };
    };

    qwenCode = {
      enable = mkEnableOption "Qwen Code";
      
      agentsPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "./dotfiles/agents-qwen";
        description = "Path to Qwen Code agents directory";
      };
    };
  };

  config = mkIf cfg.enable {
    # OpenCode configuration
    programs.opencode = mkIf cfg.opencode.enable {
      enable = true;
      agents = mkAgentsFromDir cfg.opencode.agentsPath;
      settings = {
        plugin = cfg.opencode.plugins;
      } // (optionalAttrs (cfg.opencode.defaultModel != null) {
        model = cfg.opencode.defaultModel;
      }) // cfg.opencode.extraConfig;
    };

    # Superpowers plugin + skills - declarative installation via symlinks to Nix store
    home.file = mkMerge [
      # Superpowers plugin
      (mkIf (cfg.opencode.enable && cfg.opencode.superpowers.enable) {
        ".config/opencode/plugin/superpowers.js" = {
          source = "${cfg.opencode.superpowers.package}/.opencode/plugin/superpowers.js";
        };
      })
      
      # Skills sources - create symlinks for each source
      # Structure: ~/.config/opencode/skills/<source-name>/ -> /nix/store/.../<skillsDir>/
      (mkIf (cfg.opencode.enable && cfg.opencode.superpowers.enable && cfg.opencode.superpowers.skills != []) (
        lib.listToAttrs (map (source: {
          name = ".config/opencode/skills/${source.name}";
          value = {
            source = "${source.package}/${source.skillsDir}";
            recursive = true;  # Symlink entire directory
          };
        }) cfg.opencode.superpowers.skills)
      ))
    ];

    # Claude Code configuration
    home.activation.claudeAgents = mkIf (cfg.claudeCode.enable && cfg.claudeCode.agentsPath != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.claude
        $DRY_RUN_CMD rm -rf $VERBOSE_ARG ${config.home.homeDirectory}/.claude/agents
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${cfg.claudeCode.agentsPath} ${config.home.homeDirectory}/.claude/agents
      ''
    );

    # Qwen Code configuration  
    home.activation.qwenAgents = mkIf (cfg.qwenCode.enable && cfg.qwenCode.agentsPath != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.qwen
        $DRY_RUN_CMD rm -rf $VERBOSE_ARG ${config.home.homeDirectory}/.qwen/agents
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${cfg.qwenCode.agentsPath} ${config.home.homeDirectory}/.qwen/agents
      ''
    );
  };

  meta.maintainers = [ ];
}

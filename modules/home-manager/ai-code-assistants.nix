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

      # Skills configuration (opencode-skills plugin)
      skills = {
        enable = mkEnableOption "opencode-skills plugin";
        
        # Skills sources (local, GitHub, or other)
        sources = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name of the skills source (used for directory naming)";
                example = "company-standards";
              };

              package = mkOption {
                type = types.either types.package types.path;
                description = "Package or path source for skills";
                example = literalExpression ''
                  # Local path
                  ./dotfiles/skills
                  
                  # Or GitHub package
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
                default = ".";
                description = "Path to skills directory inside the package";
                example = "skills";
              };
            };
          });
          default = [];
          description = ''
            Skills sources to install (local paths, GitHub repos, etc).
            Each skill directory inside the source will be symlinked directly to:
            ~/.config/opencode/skills/<skill-name>/
            
            This creates a flat structure where all skills from all sources
            are at the same level.
            
            opencode-skills plugin auto-discovers skills from:
            1. .opencode/skills/ (project-local, highest priority)
            2. ~/.opencode/skills/ (global user skills)
            3. ~/.config/opencode/skills/ (XDG location - where we symlink)
            
            Example structure:
              dotfiles/skills/example-skill/  → ~/.config/opencode/skills/example-skill/
              dotfiles/skills/another-skill/  → ~/.config/opencode/skills/another-skill/
          '';
          example = literalExpression ''
            [
              # Your dotfiles skills
              {
                name = "dotfiles";  # Just for reference, not used in paths
                package = ./dotfiles/skills;
                skillsDir = ".";
              }
              # GitHub skills
              {
                name = "company";
                package = pkgs.fetchFromGitHub {
                  owner = "company-org";
                  repo = "ai-skills";
                  rev = "v1.2.0";
                  sha256 = "sha256-...";
                };
                skillsDir = "skills";
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
      # Don't use settings - we'll manage opencode.json directly via home.file
    };

    # OpenCode files (config + skills)
    home.file = mkMerge [
      # OpenCode config file (opencode.json)
      (mkIf cfg.opencode.enable {
        ".config/opencode/opencode.json" = {
          text = builtins.toJSON ({
            "$schema" = "https://opencode.ai/config.json";
            plugin = cfg.opencode.plugins;
          } // (optionalAttrs (cfg.opencode.defaultModel != null) {
            model = cfg.opencode.defaultModel;
          }) // cfg.opencode.extraConfig);
        };
      })

      # Skills configuration (opencode-skills plugin)
      # Map each skill directory to a flat structure in ~/.config/opencode/skills/
      (mkIf (cfg.opencode.enable && cfg.opencode.skills.enable && cfg.opencode.skills.sources != []) (
        lib.mkMerge (map (source:
          let
            skillsBase = "${source.package}/${source.skillsDir}";
            skillDirs = builtins.readDir skillsBase;
            
            # Filter only directories (each is a skill)
            skills = lib.filterAttrs (name: type: type == "directory") skillDirs;
          in
            # Create symlink for each skill directory
            lib.mapAttrs' (skillName: type:
              lib.nameValuePair ".config/opencode/skills/${skillName}" {
                source = skillsBase + "/${skillName}";
                recursive = true;
              }
            ) skills
        ) cfg.opencode.skills.sources)
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

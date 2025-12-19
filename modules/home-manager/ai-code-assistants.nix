# AI Code Assistants module
# Unified configuration for OpenCode, Claude Code, Qwen Code
# With MCP server support via mcp-servers-nix
{ config, lib, pkgs, mcp-servers-nix, ... }:

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

  # Get enabled MCP servers
  enabledMcpServers = lib.filterAttrs (n: s: s.enable) cfg.mcpServers;

  # Convert MCP server config to Claude Code / Qwen Code format
  # { command = "..."; args = [...]; env = {...}; }
  mkStdioMcpConfig = servers:
    lib.mapAttrs (name: srv: {
      command = srv.command;
      args = srv.args;
    } // (optionalAttrs (srv.env != {}) {
      env = srv.env;
    })) servers;

  # Convert MCP server config to OpenCode format
  # { type = "local"; command = [...]; enabled = true; environment = {...}; }
  mkOpenCodeMcpConfig = servers:
    lib.mapAttrs (name: srv: {
      type = "local";
      command = [ srv.command ] ++ srv.args;
      enabled = true;
    } // (optionalAttrs (srv.env != {}) {
      environment = srv.env;
    })) servers;

  # MCP server submodule type
  mcpServerType = types.submodule {
    options = {
      enable = mkEnableOption "this MCP server";

      command = mkOption {
        type = types.str;
        description = "Command to run the MCP server";
        example = "npx";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Arguments for the MCP server command";
        example = [ "-y" "@upstash/context7-mcp" ];
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the MCP server";
        example = { API_KEY = "your-key"; };
      };
    };
  };

in {
  options.programs.aiCodeAssistants = {
    enable = mkEnableOption "AI Code Assistants configuration";

    # ========== MCP Servers ==========
    mcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = ''
        MCP servers configuration shared across all AI code assistants.
        Each enabled server will be configured for Claude Code, OpenCode, and Qwen Code.

        Use packages from mcp-servers-nix overlay (available in pkgs after overlay):
        - pkgs.mcp-server-context7
        - pkgs.mcp-server-nixos
        - pkgs.mcp-server-fetch
        - pkgs.mcp-server-filesystem
        - etc.
      '';
      example = literalExpression ''
        {
          context7 = {
            enable = true;
            command = "''${pkgs.mcp-server-context7}/bin/mcp-server-context7";
            args = [];
          };
          nixos = {
            enable = true;
            command = "''${pkgs.mcp-server-nixos}/bin/mcp-server-nixos";
            args = [];
          };
          vibe-kanban = {
            enable = true;
            command = "npx";
            args = [ "-y" "vibe-kanban" "mcp" ];
          };
        }
      '';
    };

    # ========== OpenCode ==========
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

        sources = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name of the skills source";
                example = "company-standards";
              };

              package = mkOption {
                type = types.either types.package types.path;
                description = "Package or path source for skills";
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
          description = "Skills sources to install";
        };
      };
    };

    # ========== Claude Code ==========
    claudeCode = {
      enable = mkEnableOption "Claude Code";

      agentsPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "./dotfiles/agents-claude";
        description = "Path to Claude Code agents directory";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Extra configuration merged into ~/.claude.json";
      };
    };

    # ========== Qwen Code ==========
    qwenCode = {
      enable = mkEnableOption "Qwen Code";

      agentsPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "./dotfiles/agents-qwen";
        description = "Path to Qwen Code agents directory";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Extra configuration merged into ~/.qwen/settings.json";
      };
    };
  };

  config = mkIf cfg.enable {
    # ========== OpenCode Configuration ==========
    programs.opencode = mkIf cfg.opencode.enable {
      enable = true;
      agents = mkAgentsFromDir cfg.opencode.agentsPath;
    };

    # ========== Home Files ==========
    home.file = mkMerge [
      # ----- OpenCode config (opencode.json) -----
      (mkIf cfg.opencode.enable {
        ".config/opencode/opencode.json" = {
          text = builtins.toJSON ({
            "$schema" = "https://opencode.ai/config.json";
            plugin = cfg.opencode.plugins;
          }
          // (optionalAttrs (cfg.opencode.defaultModel != null) {
            model = cfg.opencode.defaultModel;
          })
          // (optionalAttrs (enabledMcpServers != {}) {
            mcp = mkOpenCodeMcpConfig enabledMcpServers;
          })
          // cfg.opencode.extraConfig);
        };
      })

      # ----- OpenCode skills -----
      (mkIf (cfg.opencode.enable && cfg.opencode.skills.enable && cfg.opencode.skills.sources != []) (
        lib.mkMerge (map (source:
          let
            skillsBase = "${source.package}/${source.skillsDir}";
            skillDirs = builtins.readDir skillsBase;
            skills = lib.filterAttrs (name: type: type == "directory") skillDirs;
          in
            lib.mapAttrs' (skillName: type:
              lib.nameValuePair ".config/opencode/skills/${skillName}" {
                source = skillsBase + "/${skillName}";
                recursive = true;
              }
            ) skills
        ) cfg.opencode.skills.sources)
      ))

      # ----- Claude Code config (~/.claude.json) -----
      (mkIf (cfg.claudeCode.enable && enabledMcpServers != {}) {
        ".claude.json" = {
          text = builtins.toJSON ({
            mcpServers = mkStdioMcpConfig enabledMcpServers;
          } // cfg.claudeCode.extraConfig);
        };
      })

      # ----- Qwen Code config (~/.qwen/settings.json) -----
      (mkIf (cfg.qwenCode.enable && enabledMcpServers != {}) {
        ".qwen/settings.json" = {
          text = builtins.toJSON ({
            mcpServers = mkStdioMcpConfig enabledMcpServers;
          } // cfg.qwenCode.extraConfig);
        };
      })
    ];

    # ========== Activation Scripts ==========
    # Claude Code agents symlink
    home.activation.claudeAgents = mkIf (cfg.claudeCode.enable && cfg.claudeCode.agentsPath != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.claude
        $DRY_RUN_CMD rm -rf $VERBOSE_ARG ${config.home.homeDirectory}/.claude/agents
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${cfg.claudeCode.agentsPath} ${config.home.homeDirectory}/.claude/agents
      ''
    );

    # Qwen Code agents symlink
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

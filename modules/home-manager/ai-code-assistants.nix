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

  # Built-in MCP servers (auto-configured when enabled)
  builtinMcpServers =
    (optionalAttrs cfg.vibeKanban.enable {
      vibe-kanban = {
        enable = true;
        command = "${pkgs.vibe-kanban}/bin/vibe-kanban-mcp";
        args = [];
        env = {};
      };
    })
    // (optionalAttrs cfg.context7.enable {
      context7 = {
        enable = true;
        command = "${pkgs.context7-mcp}/bin/context7-mcp";
        args = [];
        env = {};
      };
    })
    // (optionalAttrs cfg.nixos.enable {
      nixos = {
        enable = true;
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        args = [];
        env = {};
      };
    });

  # Merge built-in and custom MCP servers
  allMcpServers = builtinMcpServers // cfg.mcpServers;

  # Get enabled MCP servers
  enabledMcpServers = lib.filterAttrs (n: s: s.enable) allMcpServers;

  # Convert MCP server config to Claude Code / Qwen Code format
  mkStdioMcpConfig = servers:
    lib.mapAttrs (name: srv: {
      command = srv.command;
      args = srv.args;
    } // (optionalAttrs (srv.env != {}) {
      env = srv.env;
    })) servers;

  # Convert MCP server config to OpenCode format
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
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the MCP server";
      };
    };
  };

in {
  options.programs.aiCodeAssistants = {
    enable = mkEnableOption "AI Code Assistants configuration";

    # ========== Built-in MCP Servers ==========
    vibeKanban = {
      enable = mkEnableOption "VibeKanban - local kanban board for AI agents";
    };

    context7 = {
      enable = mkEnableOption "Context7 - up-to-date library documentation";
    };

    nixos = {
      enable = mkEnableOption "NixOS MCP - packages, options, Home Manager info";
    };

    # ========== Custom MCP Servers ==========
    mcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = ''
        Additional MCP servers configuration.
        Built-in servers (vibeKanban, context7, nixos) are configured separately.
      '';
      example = literalExpression ''
        {
          filesystem = {
            enable = true;
            command = "''${pkgs.mcp-server-filesystem}/bin/mcp-server-filesystem";
            args = [ "/home/user/projects" ];
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
        description = "Path to OpenCode agents directory";
      };

      plugins = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of OpenCode plugins";
      };

      defaultModel = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default model for OpenCode";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Extra configuration for OpenCode";
      };

      skills = {
        enable = mkEnableOption "opencode-skills plugin";

        sources = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name of the skills source";
              };

              package = mkOption {
                type = types.either types.package types.path;
                description = "Package or path source for skills";
              };

              skillsDir = mkOption {
                type = types.str;
                default = ".";
                description = "Path to skills directory inside the package";
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
    # ========== Packages ==========
    home.packages = lib.optionals cfg.vibeKanban.enable [ pkgs.vibe-kanban ];

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

      # ----- Claude Code MCP config (~/.claude/settings.json) -----
      # Note: ~/.claude.json is managed by Claude Code itself
      # We use ~/.claude/settings.json for user MCP servers
      (mkIf (cfg.claudeCode.enable && enabledMcpServers != {}) {
        ".claude/settings.json" = {
          force = true;  # Override existing file
          text = builtins.toJSON ({
            mcpServers = mkStdioMcpConfig enabledMcpServers;
          } // cfg.claudeCode.extraConfig);
        };
      })

      # ----- Qwen Code config (~/.qwen/settings.json) -----
      (mkIf (cfg.qwenCode.enable && enabledMcpServers != {}) {
        ".qwen/settings.json" = {
          force = true;  # Override existing file
          text = builtins.toJSON ({
            mcpServers = mkStdioMcpConfig enabledMcpServers;
          } // cfg.qwenCode.extraConfig);
        };
      })
    ];

    # ========== Activation Scripts ==========
    home.activation.claudeAgents = mkIf (cfg.claudeCode.enable && cfg.claudeCode.agentsPath != null) (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.claude
        $DRY_RUN_CMD rm -rf $VERBOSE_ARG ${config.home.homeDirectory}/.claude/agents
        $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${cfg.claudeCode.agentsPath} ${config.home.homeDirectory}/.claude/agents
      ''
    );

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

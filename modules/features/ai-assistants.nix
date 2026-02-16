# Unified AI assistants configuration
# Combines ai-code-assistants.nix + opencode.nix functionality
{ ... }:
{
  # Export as official home-manager module
  flake.homeModules.ai-assistants =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = config.programs.aiCodeAssistants;

      # Simple helper to create agents attrset from directory
      mkAgentsFromDir =
        agentsPath:
        if agentsPath == null then
          { }
        else
          let
            agentFiles = builtins.readDir agentsPath;
            agentsAttrset = lib.mapAttrs' (
              name: _type:
              let
                agentName = lib.removeSuffix ".md" name;
              in
              lib.nameValuePair agentName (agentsPath + "/${name}")
            ) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) agentFiles);
          in
          agentsAttrset;

      # Built-in MCP servers (auto-configured when enabled)
      builtinMcpServers =
        (optionalAttrs cfg.vibeKanban.enable {
          vibe-kanban = {
            enable = true;
            command = "${pkgs.vibe-kanban}/bin/vibe-kanban-mcp";
            args = [ ];
            env = { };
          };
        })
        // (optionalAttrs cfg.context7.enable {
          context7 = {
            enable = true;
            command = "${pkgs.context7-mcp}/bin/context7-mcp";
            args = [ ];
            env = { };
          };
        })
        // (optionalAttrs cfg.nixos.enable {
          nixos = {
            enable = true;
            command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
            args = [ ];
            env = { };
          };
        });

      # Merge built-in and custom MCP servers
      allMcpServers = builtinMcpServers // cfg.mcpServers;

      # Get enabled MCP servers
      enabledMcpServers = lib.filterAttrs (_n: s: s.enable) allMcpServers;

      # Convert MCP server config to Claude Code / Qwen Code format
      mkStdioMcpConfig =
        servers:
        lib.mapAttrs (
          _name: srv:
          {
            inherit (srv) command args;
          }
          // (optionalAttrs (srv.env != { }) {
            inherit (srv) env;
          })
        ) servers;

      # Convert MCP server config to OpenCode format
      mkOpenCodeMcpConfig =
        servers:
        lib.mapAttrs (
          _name: srv:
          {
            type = "local";
            command = [ srv.command ] ++ srv.args;
            enabled = true;
          }
          // (optionalAttrs (srv.env != { }) {
            environment = srv.env;
          })
        ) servers;

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
            default = [ ];
            description = "Arguments for the MCP server command";
          };

          env = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Environment variables for the MCP server";
          };
        };
      };

    in
    {
      # Define options for home-manager module
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
          default = { };
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
            default = [ ];
            description = "List of OpenCode plugins";
          };

          defaultModel = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Default model for OpenCode";
          };

          extraConfig = mkOption {
            type = types.attrs;
            default = { };
            description = "Extra configuration for OpenCode";
          };

          skillsPath = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ''
              Path to directory containing native OpenCode skills.
              Each subdirectory should contain a SKILL.md file with YAML frontmatter.
              Skills will be symlinked to ~/.opencode/skill/
            '';
            example = literalExpression "./dotfiles/skills";
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

          claudeMdPath = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ''
              Path to CLAUDE.md file for global instructions.
              Will be symlinked to ~/.claude/CLAUDE.md
            '';
            example = literalExpression "./dotfiles/CLAUDE.md";
          };

          skillsPath = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ''
              Path to directory containing Claude Code skills.
              Each subdirectory should contain a SKILL.md file.
              Skills will be symlinked to ~/.claude/skills/
            '';
            example = literalExpression "./dotfiles/skills";
          };

          extraConfig = mkOption {
            type = types.attrs;
            default = { };
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
            default = { };
            description = "Extra configuration merged into ~/.qwen/settings.json";
          };
        };
      };

      config = mkIf cfg.enable {
        # ========== OpenCode Configuration ==========
        programs.opencode = mkIf cfg.opencode.enable {
          enable = true;
          agents = mkAgentsFromDir cfg.opencode.agentsPath;
          settings = mkMerge [
            {
              "$schema" = "https://opencode.ai/config.json";
            }
            (mkIf (cfg.opencode.plugins != [ ]) {
              plugin = cfg.opencode.plugins;
            })
            (mkIf (cfg.opencode.defaultModel != null) {
              model = cfg.opencode.defaultModel;
            })
            (mkIf (enabledMcpServers != { }) {
              mcp = mkOpenCodeMcpConfig enabledMcpServers;
            })
            cfg.opencode.extraConfig
          ];
        };

        # ========== Home Configuration ==========
        home = {
          # Packages
          packages =
            lib.optionals cfg.vibeKanban.enable [ pkgs.vibe-kanban ]
            ++ lib.optionals cfg.claudeCode.enable [ pkgs.claude-code ];

          # Files
          file = mkMerge [
            # ----- OpenCode native skills (symlink to ~/.opencode/skill/) -----
            (mkIf (cfg.opencode.enable && cfg.opencode.skillsPath != null) (
              let
                skillDirs = builtins.readDir cfg.opencode.skillsPath;
                skills = lib.filterAttrs (_name: type: type == "directory") skillDirs;
              in
              lib.mapAttrs' (
                skillName: _type:
                lib.nameValuePair ".opencode/skill/${skillName}" {
                  source = cfg.opencode.skillsPath + "/${skillName}";
                  recursive = true;
                }
              ) skills
            ))

            # ----- Claude Code MCP config (~/.claude/settings.json) -----
            (mkIf (cfg.claudeCode.enable && enabledMcpServers != { }) {
              ".claude/settings.json" = {
                force = true;
                text = builtins.toJSON (
                  {
                    mcpServers = mkStdioMcpConfig enabledMcpServers;
                  }
                  // cfg.claudeCode.extraConfig
                );
              };
            })

            # ----- Claude Code global CLAUDE.md (~/.claude/CLAUDE.md) -----
            (mkIf (cfg.claudeCode.enable && cfg.claudeCode.claudeMdPath != null) {
              ".claude/CLAUDE.md".source = cfg.claudeCode.claudeMdPath;
            })

            # ----- Claude Code skills (symlink to ~/.claude/skills/) -----
            (mkIf (cfg.claudeCode.enable && cfg.claudeCode.skillsPath != null) (
              let
                skillDirs = builtins.readDir cfg.claudeCode.skillsPath;
                skills = lib.filterAttrs (_name: type: type == "directory") skillDirs;
              in
              lib.mapAttrs' (
                skillName: _type:
                lib.nameValuePair ".claude/skills/${skillName}" {
                  source = cfg.claudeCode.skillsPath + "/${skillName}";
                  recursive = true;
                }
              ) skills
            ))

            # ----- Qwen Code config (~/.qwen/settings.json) -----
            (mkIf (cfg.qwenCode.enable && enabledMcpServers != { }) {
              ".qwen/settings.json" = {
                force = true;
                text = builtins.toJSON (
                  {
                    mcpServers = mkStdioMcpConfig enabledMcpServers;
                  }
                  // cfg.qwenCode.extraConfig
                );
              };
            })
          ];

          # Activation Scripts
          activation = {
            claudeAgents = mkIf (cfg.claudeCode.enable && cfg.claudeCode.agentsPath != null) (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.claude
                $DRY_RUN_CMD rm -rf $VERBOSE_ARG ${config.home.homeDirectory}/.claude/agents
                $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${cfg.claudeCode.agentsPath} ${config.home.homeDirectory}/.claude/agents
              ''
            );

            qwenAgents = mkIf (cfg.qwenCode.enable && cfg.qwenCode.agentsPath != null) (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${config.home.homeDirectory}/.qwen
                $DRY_RUN_CMD rm -rf $VERBOSE_ARG ${config.home.homeDirectory}/.qwen/agents
                $DRY_RUN_CMD ln -sf $VERBOSE_ARG ${cfg.qwenCode.agentsPath} ${config.home.homeDirectory}/.qwen/agents
              ''
            );
          };
        };
      };
    };
}

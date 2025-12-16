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

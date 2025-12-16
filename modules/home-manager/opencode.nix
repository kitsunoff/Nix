# OpenCode home-manager module extension
# Extends built-in home-manager opencode module with additional features
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.opencode;

in {
  # Add custom options to the existing programs.opencode
  options.programs.opencode = {
    # Custom option: simple plugins list
    plugins = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "opencode-alibaba-qwen3-auth" ];
      description = ''
        List of OpenCode plugins (convenience option).
        Automatically adds to settings.plugin.
      '';
    };

    # Custom option: default model shorthand
    defaultModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "alibaba/coder-model";
      description = ''
        Default model (convenience option).
        Automatically sets settings.model.
      '';
    };

    # Custom option: agents path as a directory
    agentsPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./dotfiles/agents";
      description = ''
        Path to custom OpenCode agents directory.
        All .md files in this directory will be automatically imported as agents.
        The filename (without .md) becomes the agent name.
      '';
    };

    # Custom option: extra config merged into settings
    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      example = {
        theme = "dark";
        autoSave = true;
      };
      description = ''
        Additional configuration merged into settings.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Merge our custom options into the built-in settings
    programs.opencode.settings = mkMerge [
      # Add plugins to settings.plugin
      (mkIf (cfg.plugins != []) {
        plugin = cfg.plugins;
      })
      
      # Add defaultModel to settings.model
      (mkIf (cfg.defaultModel != null) {
        model = cfg.defaultModel;
      })
      
      # Merge extraConfig
      cfg.extraConfig
    ];

    # If agentsPath is set, convert directory to agents attrset
    # Read all .md files from the directory and create an attrset
    programs.opencode.agents = mkIf (cfg.agentsPath != null) (
      let
        # List all files in the agents directory
        agentFiles = builtins.readDir cfg.agentsPath;
        
        # Filter only .md files and create attrset
        # { "agent-name.md" = "regular"; } -> { agent-name = ./path/agent-name.md; }
        agentsAttrset = lib.mapAttrs' (name: type:
          let
            # Remove .md extension from filename
            agentName = lib.removeSuffix ".md" name;
          in
            lib.nameValuePair agentName (cfg.agentsPath + "/${name}")
        ) (lib.filterAttrs (name: type: 
          type == "regular" && lib.hasSuffix ".md" name
        ) agentFiles);
      in
        mkForce agentsAttrset
    );
  };

  meta.maintainers = [ ];
}

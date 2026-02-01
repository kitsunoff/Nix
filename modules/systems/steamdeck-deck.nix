# Steam Deck - Standalone home-manager configuration
{ config, inputs, lib, ... }:
let
  system = "x86_64-linux";
in
{
  # Using official home-manager flakeModule
  # Docs: https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-flake-parts-module
  flake.homeConfigurations."deck@steamdeck" = inputs.home-manager.lib.homeManagerConfiguration {
    # Create pkgs with overlays
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        # Reuse centrally-defined overlays
        config.flake.overlays.rocksdb-fix
        inputs.mcp-servers-nix.overlays.default
        config.flake.overlays.custom-packages

        # OpenCode (system-specific)
        (final: _prev: {
          opencode = inputs.opencode.packages.${system}.default;
        })
      ];
    };

    extraSpecialArgs = {
      inherit inputs;
    };

    modules = [
      # Import feature modules
      config.flake.homeModules.ai-assistants
      config.flake.homeModules.git

      # System-specific configuration
      ({ pkgs, ... }: {
        home = {
          username = "deck";
          homeDirectory = lib.mkForce "/home/deck";
          stateVersion = "24.11";

          packages = with pkgs; [
            vscode
            beads
            lazybeads
          ];
        };

        nixpkgs.config.allowUnfree = true;

        # AI assistants configuration
        programs.aiCodeAssistants = {
          enable = true;

          vibeKanban.enable = true;
          context7.enable = true;
          nixos.enable = true;

          opencode = {
            enable = true;
            agentsPath = ../../dotfiles/agents;
            plugins = [ ];
            skillsPath = ../../dotfiles/skills;
            extraConfig = { };
          };

          claudeCode = {
            enable = true;
            agentsPath = ../../dotfiles/agents-claude;
          };
        };

        # Git configuration
        programs.git.settings.user = {
          name = "deck";
          email = "deck@steamdeck.local";
        };

        programs.gh.settings.editor = "code";

        programs.home-manager.enable = true;
      })
    ];
  };
}

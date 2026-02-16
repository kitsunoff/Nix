# MacBook Pro Maxim - Darwin configuration
{ config, inputs, lib, ... }:
let
  system = "aarch64-darwin";
in
{
  # Using official nix-darwin flakeModule
  flake.darwinConfigurations."MacBook-Pro-Maxim" = inputs.nix-darwin.lib.darwinSystem {
    inherit system;

    specialArgs = {
      inherit inputs;
    };

    modules = [
      # Import feature modules
      config.flake.darwinModules.nix-settings
      config.flake.darwinModules.homebrew
      config.flake.darwinModules.defaults
      config.flake.darwinModules.linux-builder
      config.flake.darwinModules.workstation

      # Apply overlays (reuse centrally-defined overlays from infrastructure/overlays.nix)
      (
        { pkgs, ... }:
        {
          nixpkgs = {
            hostPlatform = system;
            config.allowUnfree = true;
            overlays = [
              config.flake.overlays.rocksdb-fix
              inputs.mcp-servers-nix.overlays.default
              config.flake.overlays.custom-packages

              # OpenCode (system-specific)
              (final: _prev: {
                opencode = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
              })
            ];
          };
        }
      )

      # Include home-manager integration
      inputs.home-manager.darwinModules.home-manager

      # System-specific configuration
      {
        networking = {
          hostName = "MacBook-Pro-Maxim";
          computerName = "MacBook Pro Maxim";
        };

        environment.systemPackages = with inputs.nixpkgs.legacyPackages.${system}; [ nix-tree ];

        system = {
          primaryUser = "kitsunoff";
          configurationRevision = null;
          stateVersion = 6;
        };

        # Home-manager integration
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";

          users.kitsunoff = {
            imports = [
              config.flake.homeModules.ai-assistants
              config.flake.homeModules.git
            ];

            home = {
              username = "kitsunoff";
              homeDirectory = lib.mkForce "/Users/kitsunoff";
              stateVersion = "24.11";
              packages = [ ];
            };


            # AI assistants configuration
            programs.aiCodeAssistants = {
              enable = true;

              vibeKanban.enable = true;
              context7.enable = true;
              nixos.enable = true;

              opencode = {
                enable = true;
                agentsPath = ../../dotfiles/agents;
                plugins = [ "opencode-alibaba-qwen3-auth" ];
                defaultModel = "alibaba/coder-model";
                skillsPath = ../../dotfiles/skills;
                extraConfig = { };
              };

              claudeCode = {
                enable = true;
                agentsPath = ../../dotfiles/agents-claude;
                claudeMdPath = ../../dotfiles/CLAUDE.md;
                skillsPath = ../../dotfiles/skills;
              };

              qwenCode = {
                enable = true;
                agentsPath = ../../dotfiles/agents-qwen;
              };
            };

            # Git configuration
            programs.git.settings.user = {
              name = "kitsunoff";
              email = "kitsunoff@example.com";
            };

            programs.gh.settings.editor = "nvim";

            programs.home-manager.enable = true;
          };
        };
      }
    ];
  };
}

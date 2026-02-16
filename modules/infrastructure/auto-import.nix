# Auto-import flake-parts module
# Provides DSL for declarative host configurations via attrsets
{ lib, config, inputs, ... }:
let
  # Collected modules as lists
  collectedDarwinModules = lib.attrValues config.flake.darwinModules;
  collectedHomeModules = lib.attrValues config.flake.homeModules;
  collectedNixosModules = lib.attrValues (config.flake.nixosModules or { });

  # Common overlays for all systems
  mkOverlays = system: [
    config.flake.overlays.rocksdb-fix
    inputs.mcp-servers-nix.overlays.default
    config.flake.overlays.custom-packages
    (_final: _prev: {
      opencode = inputs.opencode.packages.${system}.default;
    })
  ];

  # Build darwin configuration from host attrset
  buildDarwinHost = name: cfg:
    let
      hostname = if cfg.hostname != null then cfg.hostname else name;
      system = cfg.system;
      user = cfg.user;
      email = if cfg.email != null then cfg.email else "${user}@${hostname}.local";
      editor = cfg.editor;
      extraModules = cfg.extraModules;
      homeConfig = cfg.homeConfig;
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules =
        collectedDarwinModules
        ++ [
          {
            nixpkgs = {
              hostPlatform = system;
              config.allowUnfree = true;
              overlays = mkOverlays system;
            };
          }
          inputs.home-manager.darwinModules.home-manager
          {
            networking = {
              hostName = hostname;
              computerName = lib.replaceStrings [ "-" ] [ " " ] hostname;
            };

            system = {
              primaryUser = user;
              configurationRevision = null;
              stateVersion = 6;
            };

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";

              users.${user} = {
                imports = collectedHomeModules;

                home = {
                  username = user;
                  homeDirectory = lib.mkForce "/Users/${user}";
                  stateVersion = "24.11";
                };

                programs.git.settings.user = {
                  name = user;
                  inherit email;
                };

                programs.gh.settings.editor = editor;

                programs.home-manager.enable = true;
              } // homeConfig;
            };
          }
        ]
        ++ extraModules;
    };

  # Build standalone home-manager configuration from host attrset
  buildHomeHost = name: cfg:
    let
      parts = lib.splitString "@" name;
      user = cfg.user;
      host = if cfg.host != null then cfg.host else (if builtins.length parts > 1 then builtins.elemAt parts 1 else null);
      system = cfg.system;
      email = if cfg.email != null then cfg.email else "${user}@${if host != null then host else "localhost"}.local";
      editor = cfg.editor;
      extraModules = cfg.extraModules;
      homeConfig = cfg.homeConfig;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = mkOverlays system;
      };

      extraSpecialArgs = { inherit inputs; };

      modules =
        collectedHomeModules
        ++ [
          {
            home = {
              username = user;
              homeDirectory = lib.mkForce (
                if system == "aarch64-darwin" || system == "x86_64-darwin"
                then "/Users/${user}"
                else "/home/${user}"
              );
              stateVersion = "24.11";
            };

            programs.git.settings.user = {
              name = user;
              inherit email;
            };

            programs.gh.settings.editor = editor;

            nixpkgs.config.allowUnfree = true;
            programs.home-manager.enable = true;
          }
          homeConfig
        ]
        ++ extraModules;
    };

  # Darwin host option type
  darwinHostOptions = {
    options = {
      user = lib.mkOption {
        type = lib.types.str;
        description = "Primary user name";
      };
      hostname = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hostname (defaults to attrset key)";
      };
      system = lib.mkOption {
        type = lib.types.str;
        default = "aarch64-darwin";
        description = "System architecture";
      };
      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "User email for git";
      };
      editor = lib.mkOption {
        type = lib.types.str;
        default = "nvim";
        description = "Default editor";
      };
      extraModules = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = "Extra modules to include";
      };
      homeConfig = lib.mkOption {
        type = lib.types.raw;
        default = { };
        description = "Home-manager configuration";
      };
    };
  };

  # Home host option type
  homeHostOptions = {
    options = {
      user = lib.mkOption {
        type = lib.types.str;
        description = "Primary user name";
      };
      host = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Host name (defaults to part after @ in key)";
      };
      system = lib.mkOption {
        type = lib.types.str;
        default = "x86_64-linux";
        description = "System architecture";
      };
      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "User email for git";
      };
      editor = lib.mkOption {
        type = lib.types.str;
        default = "code";
        description = "Default editor";
      };
      extraModules = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = "Extra modules to include";
      };
      homeConfig = lib.mkOption {
        type = lib.types.raw;
        default = { };
        description = "Home-manager configuration";
      };
    };
  };

in
{
  options.flake = {
    darwinHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule darwinHostOptions);
      default = { };
      description = "Darwin host configurations as attrsets";
    };

    homeHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule homeHostOptions);
      default = { };
      description = "Standalone home-manager configurations as attrsets";
    };
  };

  config.flake = {
    darwinConfigurations = lib.mapAttrs buildDarwinHost config.flake.darwinHosts;
    homeConfigurations = lib.mapAttrs buildHomeHost config.flake.homeHosts;
  };
}

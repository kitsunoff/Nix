{
  description = "macOS and NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # MCP servers for AI assistants (Claude Code, OpenCode, Qwen Code)
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Formatting and linting
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # OpenCode - terminal-based AI assistant (official upstream)
    opencode.url = "github:sst/opencode/dev";
    opencode.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      mcp-servers-nix,
      treefmt-nix,
      git-hooks,
      opencode,
      ...
    }:
    let
      # Supported systems
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Nixpkgs for each system
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            mcp-servers-nix.overlays.default
            (final: _prev: import ./pkgs { pkgs = final; })
            # OpenCode from official sst/opencode flake
            (_final: _prev: {
              opencode = opencode.packages.${system}.default;
            })
          ];
        };

      # Treefmt configuration
      treefmtEval = system: treefmt-nix.lib.evalModule (pkgsFor system) ./treefmt.nix;

      # Pre-commit hooks configuration
      preCommitCheck =
        system:
        git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Nix formatting (use nixfmt directly, treefmt has issues with pre-commit)
            nixfmt-rfc-style.enable = true;

            # Nix linting
            statix.enable = true;

            # Find dead code
            deadnix.enable = true;
          };
        };
    in
    {
      # Darwin (macOS) configurations
      darwinConfigurations = {
        "MacBook-Pro-Maxim" = nix-darwin.lib.darwinSystem {
          modules = [
            ./darwin/MacBook-Pro-Maxim

            # Add overlays (MCP servers + custom packages + opencode)
            ({ pkgs, ... }: {
              nixpkgs.overlays = [
                mcp-servers-nix.overlays.default
                (final: _prev: import "${self}/pkgs" { pkgs = final; })
                # OpenCode from official sst/opencode flake
                (_final: _prev: {
                  opencode = opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
                })
              ];
            })

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.kitsunoff = import ./home/kitsunoff.nix;
                extraSpecialArgs = {
                  inherit inputs mcp-servers-nix;
                };
              };
            }
          ];
        };
      };

      # Formatter for `nix fmt`
      formatter = forAllSystems (system: (treefmtEval system).config.build.wrapper);

      # Pre-commit checks
      checks = forAllSystems (system: {
        pre-commit-check = preCommitCheck system;
        formatting = (treefmtEval system).config.build.check self;
      });

      # Development shell with tools
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            name = "my-nixos-dev";

            packages = with pkgs; [
              # Nix tools
              nil # Nix LSP
              nixd # Alternative Nix LSP
              statix # Nix linter
              deadnix # Find dead code
              nix-tree # Explore nix store

              # Formatting
              (treefmtEval system).config.build.wrapper

              # Git
              git

              # Useful utilities
              jq
              yq-go
            ];

            shellHook = ''
              ${(preCommitCheck system).shellHook}
              echo ""
              echo "Development shell loaded!"
              echo "  nix fmt        - format code"
              echo "  nix flake check - run all checks"
              echo "  Pre-commit hooks are installed"
              echo ""
            '';
          };
        }
      );

      # Standalone Home Manager configurations (for non-NixOS systems like Steam Deck)
      homeConfigurations = {
        "deck@steamdeck" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          modules = [ ./home/deck.nix ];
          extraSpecialArgs = {/
    };
}

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
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, mcp-servers-nix }: {
    # Darwin (macOS) configurations
    darwinConfigurations = {
      "MacBook-Pro-Maxim" = nix-darwin.lib.darwinSystem {
        modules = [ 
          ./darwin/MacBook-Pro-Maxim
          
          # Home Manager integration for Darwin
          # Add overlays (MCP servers + custom packages)
          ({ ... }: {
            nixpkgs.overlays = [
              mcp-servers-nix.overlays.default
              # Custom packages overlay
              (final: prev: import "${self}/pkgs" { pkgs = final; })
            ];
          })

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.kitsunoff = import ./home/kitsunoff.nix;

            # Pass inputs to home-manager modules
            home-manager.extraSpecialArgs = {
              inherit inputs;
              mcp-servers-nix = mcp-servers-nix;
            };
          }
        ];
      };
    };

    # NixOS configurations
    # nixosConfigurations = {
    #   "hostname" = nixpkgs.lib.nixosSystem {
    #     modules = [ 
    #       ./nixos/hostname
    #       
    #       # Home Manager integration for NixOS
    #       home-manager.nixosModules.home-manager
    #       {
    #         home-manager.useGlobalPkgs = true;
    #         home-manager.useUserPackages = true;
    #         home-manager.users.username = import ./home/username.nix;
    #       }
    #     ];
    #   };
    # };
  };
}

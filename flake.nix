{
  description = "macOS and NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }: {
    # Darwin (macOS) configurations
    darwinConfigurations = {
      "MacBook-Pro-Maxim" = nix-darwin.lib.darwinSystem {
        modules = [ 
          ./darwin/MacBook-Pro-Maxim
          
          # Home Manager integration for Darwin
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.kitsunoff = import ./home/kitsunoff.nix;
            
            # Pass inputs to home-manager modules
            home-manager.extraSpecialArgs = { inherit inputs; };
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

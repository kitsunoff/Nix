# Define flake.darwinModules for merging
# flake.nixosModules is provided by flake-parts
# flake.homeModules is provided by home-manager.flakeModules.home-manager
{ lib, ... }:
{
  options.flake = {
    # Darwin modules (for nix-darwin)
    # nix-darwin.flakeModules.default only provides flake.darwinConfigurations
    # so we need to define darwinModules ourselves for reusable modules
    darwinModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
      description = "Darwin system modules";
    };
  };
}

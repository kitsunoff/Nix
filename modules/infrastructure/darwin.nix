# Darwin flake-parts integration
# Uses official nix-darwin.flakeModules.default
{ inputs, ... }:
{
  imports = [
    inputs.nix-darwin.flakeModules.default
  ];

  # The flakeModule provides:
  # - flake.darwinConfigurations option (for proper merging across modules)
  #
  # Usage: Define darwinConfigurations directly in system modules using
  # inputs.nix-darwin.lib.darwinSystem
}

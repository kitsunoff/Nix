# Home Manager flake-parts integration
# Uses official home-manager.flakeModules.home-manager
# Docs: https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-flake-parts-module
{ inputs, ... }:
{
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  # The flakeModule provides:
  # - flake.homeConfigurations option (for proper merging across modules)
  # - flake.homeModules option (for reusable modules)
  #
  # Usage: Define homeConfigurations directly in system modules using
  # inputs.home-manager.lib.homeManagerConfiguration
}

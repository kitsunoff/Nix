# Nix configuration for all platforms
{ ... }:
{
  # Export as official darwin module
  flake.darwinModules.nix-settings =
    { ... }:
    {
      nix.settings = {
        experimental-features = "nix-command flakes";
      };
      nix.optimise.automatic = true;
      nix.gc.automatic = true;
    };

  # Export as official nixos module
  flake.nixosModules.nix-settings =
    { ... }:
    {
      nix.settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
      };
      nix.gc.automatic = true;
    };
}

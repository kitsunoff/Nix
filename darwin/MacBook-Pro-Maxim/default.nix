{ pkgs, ... }:
{
  imports = [
    # System-level Darwin modules
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/linux-builder.nix
    ../../modules/darwin/defaults.nix

    # System-wide packages
    ../../modules/common/workstation-packages.nix
    ../../modules/common/ai-tools.nix

    # Note: OpenCode configuration moved to home-manager (home/kitsunoff.nix)
  ];

  # Networking
  networking = {
    hostName = "MacBook-Pro-Maxim";
    computerName = "MacBook Pro Maxim";
  };

  # System packages (installed via Nix)
  environment.systemPackages = [
    pkgs.nix-tree
  ];

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";

  # System configuration
  system = {
    primaryUser = "kitsunoff";
    configurationRevision = null;
    stateVersion = 6;
  };

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}

{ pkgs, ... }: {
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

  # Primary user (required for Homebrew and other user-specific options)
  system.primaryUser = "kitsunoff";

  # Networking
  networking.hostName = "MacBook-Pro-Maxim";
  networking.computerName = "MacBook Pro Maxim";

  # System packages (installed via Nix)
  environment.systemPackages = [
    pkgs.nix-tree
  ];

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";

  # System configuration
  system.configurationRevision = null;
  system.stateVersion = 6;

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
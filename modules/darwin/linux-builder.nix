# Linux builder configuration for building Linux packages on macOS
# Docs: https://nixos.org/manual/nixpkgs/stable/#sec-darwin-builder
{ config, pkgs, lib, ... }@inputs: {
  nix.linux-builder = {
    enable = true;

    # VM configuration
    config = {
      virtualisation = {
        # Adjust based on available resources
        cores = 4;
        memorySize = lib.mkForce (4 * 1024); # 4GB
      };
    };
  };

  # Required for building Linux packages
  nix.settings = {
    extra-platforms = "x86_64-linux aarch64-linux";
  };
}

# Linux builder configuration for building Linux packages on macOS
# Docs: https://nixos.org/manual/nixpkgs/stable/#sec-darwin-builder
{ ... }:
{
  # Export as official darwin module
  flake.darwinModules.linux-builder =
    { lib, ... }:
    {
      nix.linux-builder = {
        enable = true;
        config = {
          virtualisation = {
            cores = 4;
            memorySize = lib.mkForce (4 * 1024); # 4GB
          };
        };
      };

      nix.settings.extra-platforms = "x86_64-linux aarch64-linux";
    };
}

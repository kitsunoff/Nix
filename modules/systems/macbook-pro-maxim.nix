# MacBook Pro Maxim - Darwin configuration
{ inputs, ... }:
{
  flake.darwinHosts."MacBook-Pro-Maxim" = {
    user = "kitsunoff";
    email = "kitsunoff@example.com";
    editor = "nvim";

    extraModules = [
      { environment.systemPackages = with inputs.nixpkgs.legacyPackages.aarch64-darwin; [ nix-tree nodejs ]; }

      # Google DNS for physical interfaces: Cloudflare returns Akamai edges with
      # TLS resets for Steam. VPN services keep their own resolvers.
      {
        networking = {
          knownNetworkServices = [
            "Wi-Fi"
            "USB 10/100/1000 LAN"
          ];
          dns = [
            "8.8.8.8"
            "8.8.4.4"
          ];
        };
      }

      # Colima-based Linux builder with Rosetta 2 for x86_64-linux builds
      {
        nix.colima-builder = {
          enable = true;
          sshKey = "/Users/kitsunoff/.ssh/nix-builder-colima";
        };
      }
    ];

    homeConfig = {
      programs.aiCodeAssistants.opencode = {
        plugins = [ "opencode-alibaba-qwen3-auth" ];
        defaultModel = "alibaba/coder-model";
      };
    };
  };
}

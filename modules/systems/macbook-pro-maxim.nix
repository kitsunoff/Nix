# MacBook Pro Maxim - Darwin configuration
{ inputs, ... }:
{
  flake.darwinHosts."MacBook-Pro-Maxim" = {
    user = "kitsunoff";
    email = "kitsunoff@example.com";
    editor = "nvim";

    extraModules = [
      { environment.systemPackages = with inputs.nixpkgs.legacyPackages.aarch64-darwin; [ nix-tree ]; }

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

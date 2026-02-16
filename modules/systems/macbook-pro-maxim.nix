# MacBook Pro Maxim - Darwin configuration
{ inputs, ... }:
{
  flake.darwinHosts."MacBook-Pro-Maxim" = {
    user = "kitsunoff";
    email = "kitsunoff@example.com";
    editor = "nvim";

    extraModules = [
      { environment.systemPackages = with inputs.nixpkgs.legacyPackages.aarch64-darwin; [ nix-tree ]; }
    ];

    homeConfig = {
      programs.aiCodeAssistants.opencode = {
        plugins = [ "opencode-alibaba-qwen3-auth" ];
        defaultModel = "alibaba/coder-model";
      };
    };
  };
}

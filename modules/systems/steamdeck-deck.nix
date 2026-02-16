# Steam Deck - Standalone home-manager configuration
{ ... }:
{
  flake.homeHosts."deck@steamdeck" = {
    user = "deck";
    system = "x86_64-linux";
    editor = "code";

    homeConfig = { pkgs, ... }: {
      home.packages = with pkgs; [
        vscode
        beads
        lazybeads
      ];

      programs.aiCodeAssistants.qwenCode.enable = false;
    };
  };
}

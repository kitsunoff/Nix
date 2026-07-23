# Common workstation packages for all platforms
{ pkgs, ... }:
{
  # Export as official darwin module
  flake.darwinModules.workstation =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        fzf
        go
        jq
        opencode
        qwen-code
        nim
      ];
    };

  # Export as official nixos module
  flake.nixosModules.workstation =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        fzf
        go
        jq
        opencode
        qwen-code
        nim
      ];
    };
}

# Custom packages overlay
{ pkgs }:

let
  ccusage = pkgs.callPackage ./ccusage.nix { };
in
{
  inherit ccusage;
  vibe-kanban = pkgs.callPackage ./vibe-kanban.nix { };
  lazybeads = pkgs.callPackage ./lazybeads.nix { };
  claude-statusline = pkgs.callPackage ./claude-statusline.nix { inherit ccusage; };
}

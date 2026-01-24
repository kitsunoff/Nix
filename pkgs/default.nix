# Custom packages overlay
{ pkgs }:

{
  vibe-kanban = pkgs.callPackage ./vibe-kanban.nix { };
  lazybeads = pkgs.callPackage ./lazybeads.nix { };
}

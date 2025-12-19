# Custom packages overlay
{ pkgs }:

{
  vibe-kanban = pkgs.callPackage ./vibe-kanban.nix { };
}

# macOS system defaults
{ ... }:
{
  # Export as official darwin module
  flake.darwinModules.defaults =
    { ... }:
    {
      # Example macOS defaults (currently empty/commented)
      # Uncomment to enable
      # system.defaults.dock = {
      #   autohide = true;
      #   orientation = "bottom";
      #   show-recents = false;
      # };

      # system.defaults.finder = {
      #   AppleShowAllExtensions = true;
      #   ShowPathbar = true;
      # };

      # system.defaults.NSGlobalDomain = {
      #   AppleShowAllExtensions = true;
      #   InitialKeyRepeat = 14;
      #   KeyRepeat = 1;
      # };
    };
}

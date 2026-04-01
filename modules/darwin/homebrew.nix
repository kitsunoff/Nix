# Homebrew configuration for macOS
{ ... }:
{
  # Export as official darwin module
  flake.darwinModules.homebrew =
    { ... }:
    {
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false;
          upgrade = false;
          cleanup = "zap";
        };
        taps = [ ];
        brews = [ "talosctl" "teleport" ];
        casks = [ ];
        masApps = { };
      };
    };
}

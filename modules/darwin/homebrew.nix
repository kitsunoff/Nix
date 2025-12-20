# Homebrew configuration for macOS
_: {
  # Enable Homebrew
  homebrew = {
    enable = true;

    # Auto-update Homebrew and packages
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };

    # Homebrew taps
    taps = [ ];

    # Homebrew formulas (CLI tools)
    brews = [ ];

    # Homebrew casks (GUI applications)
    casks = [
    ];

    # Mac App Store apps
    masApps = {
      # Example: "Xcode" = 497799835;
    };
  };
}

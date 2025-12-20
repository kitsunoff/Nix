# Common Nix settings for all systems
_: {
  nix.settings = {
    experimental-features = "nix-command flakes";

    # Auto-optimize store
    auto-optimise-store = true;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
  };
}

# Treefmt configuration
# https://github.com/numtide/treefmt-nix
_: {
  # Project root marker
  projectRootFile = "flake.nix";

  # Formatters
  programs = {
    # Nix formatter
    nixfmt.enable = true;
    # Alternative: alejandra (more opinionated)
    # alejandra.enable = true;

    # Shell scripts
    shfmt = {
      enable = true;
      indent_size = 2;
    };

    # YAML
    yamlfmt.enable = true;

    # JSON
    prettier = {
      enable = true;
      includes = [ "*.json" ];
    };

    # Markdown
    mdformat.enable = true;

    # TOML
    taplo.enable = true;
  };

  # Exclude paths
  settings.global.excludes = [
    # Nix store and build artifacts
    "result"
    "result-*"

    # Git
    ".git/*"

    # Generated files
    "flake.lock"
    "*.lock"

    # Hardware configuration (auto-generated)
    "hardware-configuration.nix"
  ];
}

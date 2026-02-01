# Overlays module - centralized overlay management
# Based on flake-parts best practices: https://flake.parts/overlays
{ inputs, config, ... }:
{
  # Define overlays at top-level (not per-system)
  # These can be consumed by other flakes and reused internally
  flake.overlays = {
    # Rocksdb fix overlay - MUST be applied first
    rocksdb-fix = final: prev: {
      python313Packages = prev.python313Packages.overrideScope (
        _pyFinal: pyPrev: {
          rocksdict = pyPrev.rocksdict.overridePythonAttrs (_old: {
            doCheck = false;
          });
          py-key-value-aio = pyPrev.py-key-value-aio.overridePythonAttrs (_old: {
            doCheck = false;
          });
        }
      );
      python312Packages = prev.python312Packages.overrideScope (
        _pyFinal: pyPrev: {
          rocksdict = pyPrev.rocksdict.overridePythonAttrs (_old: {
            doCheck = false;
          });
          py-key-value-aio = pyPrev.py-key-value-aio.overridePythonAttrs (_old: {
            doCheck = false;
          });
        }
      );
    };

    # Custom packages overlay
    custom-packages = final: _prev: import "${inputs.self}/pkgs" { pkgs = final; };

    # Default overlay composition (for external consumption)
    default = final: prev:
      # Compose overlays in order
      config.flake.overlays.rocksdb-fix final prev
      // config.flake.overlays.custom-packages final prev;
  };

  # Apply overlays to perSystem.pkgs
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # Order matters! Rocksdb fix must be first
          config.flake.overlays.rocksdb-fix
          inputs.mcp-servers-nix.overlays.default
          config.flake.overlays.custom-packages

          # OpenCode (system-specific, can't be in top-level overlay)
          (final: _prev: {
            opencode = inputs.opencode.packages.${system}.default;
          })
        ];
      };
    };
}

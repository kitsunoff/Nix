# my-nixos

NixOS/Darwin system configurations using flake-parts with import-tree for automatic module discovery.

## Quick Reference

```bash
# Build and switch
darwin-rebuild switch --flake .

# Build only (test)
darwin-rebuild build --flake .

# Lint nix files
statix check .
```

## Architecture

### Core Stack

- **flake-parts** - modular flake composition
- **import-tree** - automatic module discovery from `modules/` directory
- **nix-darwin** - macOS system configuration
- **home-manager** - user environment management

### Directory Structure

```text
modules/
├── infrastructure/     # Flake-parts modules (overlays, dev-tools, auto-import)
├── darwin/             # nix-darwin modules (system-level)
├── features/           # home-manager modules (user-level)
├── defaults/           # Personal default values (mkDefault)
└── systems/            # Host definitions (darwinHosts, homeHosts)
```

### Module Types

| Directory | Exports to | Purpose |
| --- | --- | --- |
| `infrastructure/` | flake-parts | Flake infrastructure, overlays, helpers |
| `darwin/` | `flake.darwinModules` | macOS system config (brew, defaults) |
| `features/` | `flake.homeModules` | User programs (ai-assistants, git) |
| `defaults/` | `flake.homeModules` | Personal defaults for features |
| `systems/` | `flake.darwinHosts` / `flake.homeHosts` | Host definitions |

## Host DSL

Hosts are defined as pure attrsets via `flake.darwinHosts` and `flake.homeHosts`:

```nix
# Darwin host (macOS)
flake.darwinHosts."My-MacBook" = {
  user = "username";           # Required
  # hostname = "My-MacBook";   # Optional, defaults to attrset key
  # system = "aarch64-darwin"; # Optional, default
  # email = "user@host.local"; # Optional, auto-generated
  # editor = "nvim";           # Optional, default
  extraModules = [ ];          # Extra nix-darwin modules
  homeConfig = { };            # home-manager config overrides
};

# Standalone home-manager host
flake.homeHosts."user@server" = {
  user = "user";               # Required
  # host = "server";           # Optional, parsed from key after @
  # system = "x86_64-linux";   # Optional, default
  # editor = "code";           # Optional, default
  homeConfig = { pkgs, ... }: {
    home.packages = [ pkgs.htop ];
  };
};
```

All `flake.darwinModules` and `flake.homeModules` are auto-imported into hosts.

## Adding New Host

1. Create `modules/systems/<hostname>.nix`
2. Define host via `flake.darwinHosts` or `flake.homeHosts`
3. Build: `darwin-rebuild build --flake .`

Minimal darwin host:

```nix
{ ... }:
{
  flake.darwinHosts."New-Mac" = {
    user = "myuser";
  };
}
```

## Adding New Module

### Darwin module (system-level)

```nix
# modules/darwin/my-feature.nix
{ ... }:
{
  flake.darwinModules.my-feature = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.htop ];
  };
}
```

### Home module (user-level)

```nix
# modules/features/my-feature.nix
{ ... }:
{
  flake.homeModules.my-feature = { pkgs, ... }: {
    home.packages = [ pkgs.htop ];
  };
}
```

Modules are auto-discovered by import-tree and auto-imported into all hosts.

## Defaults Pattern

Personal defaults live in `modules/defaults/`:

```nix
# modules/defaults/ai-assistants.nix
{ lib, ... }:
{
  flake.homeModules.ai-assistants-defaults = { ... }: {
    programs.aiCodeAssistants = {
      enable = lib.mkDefault true;
      # ... defaults with mkDefault
    };
  };
}
```

Use `lib.mkDefault` so hosts can override.

## Key Patterns

### Separation of Concerns

- **Module** (`features/`) - options + implementation logic
- **Defaults** (`defaults/`) - personal default values
- **Host** (`systems/`) - host-specific overrides

### Auto-import Flow

1. `import-tree ./modules` discovers all `.nix` files
2. `flake.darwinModules` / `flake.homeModules` collected
3. `auto-import.nix` builds hosts with all modules included

### Override Priority

```text
module options < defaults (mkDefault) < host config
```

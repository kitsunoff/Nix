# Agents

## nix-module

Create or modify Nix modules following project patterns.

### Module Types

**Darwin module** (system-level, macOS):

```nix
# modules/darwin/<name>.nix
{ ... }:
{
  flake.darwinModules.<name> = { config, lib, pkgs, ... }: {
    # nix-darwin options
  };
}
```

**Home module** (user-level):

```nix
# modules/features/<name>.nix
{ ... }:
{
  flake.homeModules.<name> = { config, lib, pkgs, ... }: {
    # home-manager options
  };
}
```

**Defaults module** (personal defaults):

```nix
# modules/defaults/<name>.nix
{ lib, ... }:
{
  flake.homeModules.<name>-defaults = { ... }: {
    # Use lib.mkDefault for all values
  };
}
```

### Conventions

- One module per file
- File name matches module name
- Use `lib.mkOption` for custom options
- Use `lib.mkDefault` in defaults modules
- Use `lib.mkIf` for conditional config
- Modules auto-discovered by import-tree

---

## nix-host

Create or modify host configurations.

### Darwin Host

```nix
# modules/systems/<hostname>.nix
{ inputs, ... }:
{
  flake.darwinHosts."<hostname>" = {
    user = "<username>";           # Required
    # hostname = "<hostname>";     # Optional, defaults to key
    # system = "aarch64-darwin";   # Optional
    # email = "user@host.local";   # Optional
    # editor = "nvim";             # Optional

    extraModules = [
      # Additional nix-darwin modules
    ];

    homeConfig = {
      # home-manager overrides
    };
  };
}
```

### Home-Manager Host (standalone)

```nix
# modules/systems/<user>-<host>.nix
{ ... }:
{
  flake.homeHosts."<user>@<host>" = {
    user = "<user>";               # Required
    # system = "x86_64-linux";     # Optional
    # editor = "code";             # Optional

    homeConfig = { pkgs, ... }: {
      home.packages = with pkgs; [ ];
    };
  };
}
```

### Key Points

- All `darwinModules` and `homeModules` auto-imported
- Override defaults in `homeConfig`
- Use `extraModules` for system-level additions
- Hostname parsed from attrset key

---

## nix-overlay

Create or modify overlays.

### Location

`modules/infrastructure/overlays.nix`

### Pattern

```nix
flake.overlays.<name> = final: prev: {
  <package> = prev.<package>.overrideAttrs (old: {
    # modifications
  });
};
```

### Adding New Package

```nix
flake.overlays.custom-packages = final: prev: {
  my-package = final.callPackage ../packages/my-package.nix { };
};
```

---

## nix-debug

Debug Nix evaluation issues.

### Commands

```bash
# Check syntax
statix check .

# Build with trace
darwin-rebuild build --flake . --show-trace 2>&1 | head -100

# Evaluate specific attribute
nix eval .#darwinConfigurations.MacBook-Pro-Maxim.config.system.build.toplevel

# REPL exploration
nix repl
:lf .
darwinConfigurations.<host>.config.<path>
```

### Common Issues

**"attribute X not found"** - Check module exports match file structure

**"infinite recursion"** - Check for circular imports in config

**"option X does not exist"** - Module not imported or typo in option path

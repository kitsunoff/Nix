# Nix Configuration

Multi-platform system configuration for macOS (nix-darwin) and Linux (home-manager) using the [dendritic pattern](https://github.com/mightyiam/dendritic) with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree).

## Systems

| Host | Platform | Type |
|------|----------|------|
| `MacBook-Pro-Maxim` | aarch64-darwin | nix-darwin + home-manager |
| `deck@steamdeck` | x86_64-linux | standalone home-manager |

## Architecture

Every `.nix` file under `modules/` is a top-level [flake-parts](https://github.com/hercules-ci/flake-parts) module, auto-imported via [import-tree](https://github.com/vic/import-tree). Reusable lower-level modules (darwin, home-manager) are stored as `deferredModule` options and composed in system definitions.

```
flake.nix                          # Inputs + import-tree entry point
modules/
├── infrastructure/                # Plumbing: module types, overlays, systems
│   ├── modules.nix                # darwinModules / homeModules option defs
│   ├── overlays.nix               # Shared nixpkgs overlays
│   ├── systems.nix                # Supported platforms
│   ├── darwin.nix                 # Darwin-specific infra
│   ├── home-manager.nix           # HM-specific infra
│   └── dev-tools.nix              # treefmt, git-hooks, devShells
├── features/                      # Reusable feature modules
│   ├── nix-settings.nix           # Nix daemon & substituters
│   ├── workstation.nix            # System packages & shell config
│   ├── ai-assistants.nix          # OpenCode, Claude Code, Qwen Code
│   └── git.nix                    # Git & GitHub CLI
├── darwin/                        # macOS-specific modules
│   ├── defaults.nix               # macOS system defaults
│   ├── homebrew.nix               # Homebrew casks & formulae
│   └── linux-builder.nix          # Linux VM builder for cross-compilation
└── systems/                       # Host declarations
    ├── macbook-pro-maxim.nix      # MacBook Pro config
    └── steamdeck-deck.nix         # Steam Deck config
dotfiles/                          # Agent prompts & skills for AI assistants
pkgs/                              # Custom packages
treefmt.nix                        # Code formatting config
```

## Usage

### Apply configuration

```bash
# macOS (full system + home-manager)
darwin-rebuild switch --flake .#MacBook-Pro-Maxim

# Linux / Steam Deck (home-manager only)
home-manager switch --flake .#deck@steamdeck
```

### Update dependencies

```bash
nix flake update
```

### Format & lint

```bash
nix fmt           # treefmt (alejandra)
nix flake check   # git-hooks, build checks
```

## Adding a new host

1. Create `modules/systems/<hostname>.nix` as a flake-parts module
2. Define `flake.darwinConfigurations` or `flake.homeConfigurations` using modules from `config.flake.darwinModules` / `config.flake.homeModules`
3. Run `darwin-rebuild switch` or `home-manager switch`

The file is auto-imported -- no manual imports needed.

## Key dependencies

- [nixpkgs](https://github.com/NixOS/nixpkgs) (unstable)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [flake-parts](https://github.com/hercules-ci/flake-parts)
- [import-tree](https://github.com/vic/import-tree)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix)
- [opencode](https://github.com/sst/opencode)

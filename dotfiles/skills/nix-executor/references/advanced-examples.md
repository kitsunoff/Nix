# Advanced Nix Execution Examples

This document provides advanced examples for executing and debugging Nix code.

## Complex Expression Evaluation

### Working with nixpkgs

```bash
# Get package version
nix eval --expr 'with import <nixpkgs> {}; hello.version'

# Check if package exists
nix eval --expr 'with import <nixpkgs> {}; builtins.hasAttr "vscode" pkgs'

# List all python packages
nix eval --json --expr 'builtins.attrNames (import <nixpkgs> {}).python3Packages' | jq
```

### Flake Evaluation

```bash
# List flake outputs
nix eval .#outputs --apply builtins.attrNames

# Check flake input versions
nix eval .#inputs.nixpkgs.rev

# Evaluate specific configuration
nix eval .#darwinConfigurations.myHost.config.system.stateVersion
```

## Debugging Techniques

### Using Show Trace

```bash
# Get full evaluation trace
nix eval --show-trace --expr 'throw "debug message"'

# Trace function calls
nix eval --show-trace --expr 'builtins.trace "value" (1 + 1)'
```

### Inspecting Evaluation

```bash
# See what a derivation contains
nix eval --json nixpkgs#hello.drvPath | jq

# Check derivation outputs
nix derivation show nixpkgs#hello | jq '.[] | .outputs'

# List all derivation dependencies
nix derivation show nixpkgs#hello | jq '.[] | .inputDrvs'
```

## Testing Configuration

### Darwin Configuration

```bash
# Validate darwin configuration builds
nix build .#darwinConfigurations.$(hostname -s).system --dry-run

# Check specific service configuration
nix eval .#darwinConfigurations.$(hostname -s).config.services.nix-daemon.enable

# List all enabled services
nix eval --json .#darwinConfigurations.$(hostname -s).config.services \
  --apply 'services: builtins.attrNames (builtins.filter (s: s.enable or false) services)' | jq
```

### NixOS Configuration

```bash
# Check system packages
nix eval --json .#nixosConfigurations.myHost.config.environment.systemPackages \
  --apply 'pkgs: map (p: p.name or "unknown") pkgs' | jq

# Verify network configuration
nix eval --json .#nixosConfigurations.myHost.config.networking | jq
```

## Working with Custom Expressions

### Creating Test Derivations

```bash
# Create and evaluate a simple derivation
nix eval --expr '
  let
    pkgs = import <nixpkgs> {};
  in
    pkgs.runCommand "test" {} "echo hello > $out"
'

# Test a shell script
nix eval --expr '
  let
    pkgs = import <nixpkgs> {};
  in
    pkgs.writeShellScript "test.sh" "echo hello world"
'
```

### Function Testing

```bash
# Test a custom function
nix eval --expr '
  let
    double = x: x * 2;
    numbers = [1 2 3 4 5];
  in
    map double numbers
'

# Test attribute merging
nix eval --json --expr '
  let
    a = { x = 1; y = 2; };
    b = { y = 3; z = 4; };
  in
    a // b
' | jq
```

## Performance Testing

### Lazy Evaluation

```bash
# This doesn't evaluate the throw
nix eval --expr 'let x = throw "error"; in 1'

# This does evaluate the throw
nix eval --expr 'let x = throw "error"; in x'
```

### Memory Usage

```bash
# Monitor evaluation memory
/usr/bin/time -l nix eval --expr 'builtins.genList (x: x) 10000' 2>&1 | grep maximum
```

## Integration Testing

### Home Manager

```bash
# Test home-manager configuration
nix eval .#homeConfigurations.user.activationPackage

# Check user packages
nix eval --json .#homeConfigurations.user.config.home.packages \
  --apply 'pkgs: map (p: p.name or "unknown") pkgs' | jq
```

### Module System

```bash
# Evaluate module options
nix eval --expr '
  let
    lib = (import <nixpkgs> {}).lib;
    eval = lib.evalModules {
      modules = [
        { options.foo = lib.mkOption { type = lib.types.int; }; }
        { config.foo = 42; }
      ];
    };
  in
    eval.config.foo
'
```

## CI/CD Integration

### Automated Checks

```bash
# Check if flake is valid
nix flake check --all-systems

# Build all packages without installing
nix build .#packages.$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]').all --dry-run

# Evaluate and format output for parsing
nix eval --json .#checks | jq -r 'keys[]'
```

## Error Recovery

### Handling Evaluation Errors

```bash
# Try evaluation with fallback
nix eval --expr 'builtins.tryEval (throw "error")' 
# Returns: { success = false; value = false; }

# Conditional evaluation
nix eval --expr '
  if builtins.pathExists ./config.nix
  then import ./config.nix
  else {}
'
```

### Debugging Import Errors

```bash
# Check if file is valid Nix
nix-instantiate --parse file.nix

# Evaluate file with trace
nix-instantiate --eval --strict --show-trace file.nix
```

## Tips and Tricks

1. **Use `--impure` when needed**: For accessing environment variables or current time
   ```bash
   nix eval --impure --expr 'builtins.getEnv "HOME"'
   ```

2. **Pretty print with `nix repl`**: For interactive exploration
   ```bash
   nix repl
   :l <nixpkgs>
   :p lib.version
   ```

3. **Cache evaluation results**: Use `--eval-store` for faster re-evaluation
   ```bash
   nix eval --eval-store auto --expr 'expensive-computation'
   ```

4. **Profile evaluation**: Find slow parts of configuration
   ```bash
   nix eval --profile ./profile --expr 'import ./config.nix'
   ```

# Development tools: formatter, checks, devShells
{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs "${inputs.self}/treefmt.nix";

      preCommitCheck = inputs.git-hooks.lib.${system}.run {
        src = inputs.self;
        hooks = {
          nixfmt-rfc-style.enable = true;
          statix.enable = true;
          deadnix.enable = true;
        };
      };
    in
    {
      formatter = treefmtEval.config.build.wrapper;

      checks = {
        pre-commit-check = preCommitCheck;
        formatting = treefmtEval.config.build.check inputs.self;
      };

      devShells.default = pkgs.mkShell {
        name = "my-nixos-dev";
        packages = with pkgs; [
          nil
          nixd
          statix
          deadnix
          nix-tree
          treefmtEval.config.build.wrapper
          git
          jq
          yq-go
        ];
        shellHook = ''
          ${preCommitCheck.shellHook}
          echo ""
          echo "Development shell loaded!"
          echo "  nix fmt        - format code"
          echo "  nix flake check - run all checks"
          echo "  Pre-commit hooks are installed"
          echo ""
        '';
      };
    };
}

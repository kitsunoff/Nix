# Development tools: devShells, apps, formatter, checks
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

      # Wrap switch.sh with dependencies
      nixos-switch = pkgs.stdenv.mkDerivation {
        name = "nixos-switch";
        src = inputs.self;
        dontBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          mkdir -p $out/bin
          cp scripts/switch.sh $out/bin/nixos-switch
          chmod +x $out/bin/nixos-switch
          wrapProgram $out/bin/nixos-switch \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.fzf pkgs.jq pkgs.nix ]}
        '';
      };
    in
    {
      formatter = treefmtEval.config.build.wrapper;

      checks = {
        formatting = treefmtEval.config.build.check inputs.self;
        pre-commit = preCommitCheck;
      };

      packages = {
        inherit nixos-switch;
        default = nixos-switch;
      };

      apps = {
        switch = {
          type = "app";
          program = "${nixos-switch}/bin/nixos-switch";
        };
        default = {
          type = "app";
          program = "${nixos-switch}/bin/nixos-switch";
        };
      };

      devShells.default = pkgs.mkShell {
        name = "my-nixos-dev";
        packages = with pkgs; [
          statix
          deadnix
          git
          jq
          fzf
          nixos-switch
        ];
      };
    };
}

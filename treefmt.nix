# Treefmt configuration
_: {
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
    };
    yamlfmt.enable = true;
    prettier = {
      enable = true;
      includes = [ "*.json" ];
    };
    taplo.enable = true;
  };

  settings.global.excludes = [
    "result"
    "result-*"
    ".git/*"
    "flake.lock"
    "*.lock"
  ];
}

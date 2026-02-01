# Git and GitHub CLI configuration
{ ... }:
{
  # Export as official home-manager module
  flake.homeModules.git =
    { ... }:
    {
      programs.git = {
        enable = true;
        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        settings = {
          git_protocol = "https";
        };
      };
    };
}

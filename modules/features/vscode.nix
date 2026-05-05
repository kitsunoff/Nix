{ ... }:
{
  flake.homeModules.vscode =
    { pkgs, ... }:
    {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;
        mutableExtensionsDir = true;

        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;

          userSettings = {
            "python.analysis.typeCheckingMode" = "standard";
            "git.confirmSync" = false;
            "git.replaceTagsWhenPull" = true;
            "claudeCode.preferredLocation" = "panel";
            "[dockercompose]" = {
              "editor.insertSpaces" = true;
              "editor.tabSize" = 2;
              "editor.autoIndent" = "advanced";
              "editor.defaultFormatter" = "redhat.vscode-yaml";
            };
            "[github-actions-workflow]" = {
              "editor.defaultFormatter" = "redhat.vscode-yaml";
            };
          };

          keybindings = [
            {
              key = "shift+enter";
              command = "workbench.action.terminal.sendSequence";
              args.text = builtins.fromJSON ''"\u001b\r"'';
              when = "terminalFocus";
            }
          ];

          extensions = with pkgs.vscode-marketplace; [
            anthropic.claude-code
            bbenoist.nix
            golang.go
            mermaidchart.vscode-mermaid-chart
            ms-azuretools.vscode-containers
            # ms-dotnettools.csdevkit — broken in nix-vscode-extensions (patchPhase pattern mismatch)
            ms-dotnettools.csharp
            ms-dotnettools.vscode-dotnet-runtime
            ms-python.debugpy
            ms-python.python
            ms-python.vscode-pylance
            ms-python.vscode-python-envs
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode.makefile-tools
            ms-vscode.remote-explorer
            nimsaem.nimvscode
            redhat.ansible
            redhat.vscode-yaml
            sst-dev.opencode
            vue.volar
          ];
        };
      };
    };
}

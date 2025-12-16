# Common packages for all workstations
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Code editors and development tools
    opencode
    qwen-code
  ];
}

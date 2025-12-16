# Shell configuration (bash/zsh)
{ pkgs, ... }: {
  # Example: enable zsh
  # programs.zsh.enable = true;

  # Shell packages
  environment.systemPackages = with pkgs; [
    # Add shell utilities here
  ];
}

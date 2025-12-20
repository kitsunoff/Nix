# AI Tools configuration - prompts and agents
# Работает на macOS (Darwin) и NixOS
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Путь к промптам и агентам в репозитории
  dotfilesPath = ../../dotfiles;
  promptsPath = "${dotfilesPath}/prompts";
  agentsPath = "${dotfilesPath}/agents";

  # Определяем имя пользователя в зависимости от платформы
  username =
    if pkgs.stdenv.isDarwin then
      config.system.primaryUser or (builtins.getEnv "USER")
    else
      builtins.getEnv "USER";

  homeDir = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

  # Скрипт для создания симлинков
  setupScript = ''
    # Создаём директории для каждого инструмента
    mkdir -p "${homeDir}/.config/claude"
    mkdir -p "${homeDir}/.config/opencode"
    mkdir -p "${homeDir}/.config/qwen"

    # Линкуем промпты и агенты для всех инструментов
    for tool in claude opencode qwen; do
      # Удаляем старые симлинки если есть
      rm -f "${homeDir}/.config/$tool/prompts"
      rm -f "${homeDir}/.config/$tool/agents"

      # Создаём симлинки на общие промпты и агенты
      ln -sf "${promptsPath}" "${homeDir}/.config/$tool/prompts"
      ln -sf "${agentsPath}" "${homeDir}/.config/$tool/agents"
    done

    echo "✓ AI tools prompts and agents synced from ${dotfilesPath}"
  '';

in
{
  # Works on both Darwin and NixOS
  system.activationScripts.extraActivation.text = lib.mkAfter setupScript;
}

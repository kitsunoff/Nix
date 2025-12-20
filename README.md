# My NixOS/nix-darwin Configuration

Централизованная конфигурация для macOS (nix-darwin) и NixOS систем.

## Структура проекта

```
my-nixos/
├── flake.nix              # Главный flake файл
├── flake.lock             # Lock файл зависимостей
├── NIX_STYLE_GUIDE.md     # Правила оформления кода
│
├── darwin/                # macOS системные конфигурации
│   └── MacBook-Pro-Maxim/ # Конфигурация для конкретного хоста
│       └── default.nix
│
├── home/                  # Home Manager конфигурации пользователей
│   └── kitsunoff.nix     # Пользовательская конфигурация
│
├── modules/               # Переиспользуемые модули
│   ├── common/           # Общие системные модули
│   ├── darwin/           # macOS-специфичные модули
│   ├── nixos/            # NixOS-специфичные модули
│   └── home-manager/     # Home Manager модули (пользовательские)
│
└── dotfiles/             # Dotfiles и агенты
    └── agents/           # OpenCode агенты
```

### Разделение системной и пользовательской конфигурации

**Системная конфигурация** (`darwin/` и `modules/darwin/`, `modules/common/`):

- Системные пакеты и сервисы
- Настройки macOS/NixOS
- Homebrew (macOS)
- Сетевые настройки
- Системные демоны

**Пользовательская конфигурация** (`home/` и `modules/home-manager/`):

- Пользовательские приложения
- Dotfiles (zsh, git, vim и т.д.)
- OpenCode конфигурация
- Пользовательские настройки окружения

## Использование

### Применение конфигурации (macOS)

```bash
# Проверка конфигурации
darwin-rebuild check --flake .#MacBook-Pro-Maxim

# Применение изменений (система + home-manager)
darwin-rebuild switch --flake .#MacBook-Pro-Maxim

# Сборка без активации
darwin-rebuild build --flake .#MacBook-Pro-Maxim
```

### Применение только пользовательской конфигурации

```bash
# Применение Home Manager конфигурации без перестройки системы
home-manager switch --flake .#kitsunoff@MacBook-Pro-Maxim

# Примечание: обычно не требуется, так как darwin-rebuild 
# автоматически применяет home-manager конфигурацию
```

### Применение конфигурации (NixOS)

```bash
# Проверка конфигурации
nixos-rebuild dry-build --flake .#hostname

# Применение изменений
sudo nixos-rebuild switch --flake .#hostname

# Тестирование без загрузчика
sudo nixos-rebuild test --flake .#hostname
```

### Обновление зависимостей

```bash
# Обновить все inputs
nix flake update

# Обновить конкретный input
nix flake lock --update-input nixpkgs

# Показать информацию о flake
nix flake show
```

### Форматирование кода

```bash
# Установка инструментов
nix-shell -p nixpkgs-fmt alejandra statix deadnix

# Форматирование
alejandra .

# Проверка линтером
statix check

# Поиск неиспользуемого кода
deadnix -e
```

## Добавление нового хоста

### macOS (Darwin)

1. Создайте директорию для хоста:

```bash
mkdir -p darwin/hostname
```

2. Создайте `darwin/hostname/default.nix`:

```nix
{ pkgs, ... }: {
  imports = [
    ../../modules/common/nix-settings.nix
  ];

  networking.hostName = "hostname";
  nixpkgs.hostPlatform = "aarch64-darwin";  # или x86_64-darwin
  system.stateVersion = 6;
}
```

3. Добавьте конфигурацию в `flake.nix`:

```nix
darwinConfigurations = {
  "hostname" = nix-darwin.lib.darwinSystem {
    modules = [ ./darwin/hostname ];
  };
};
```

### NixOS

1. Создайте директорию для хоста:

```bash
mkdir -p nixos/hostname
```

2. Создайте `nixos/hostname/default.nix` и скопируйте `hardware-configuration.nix`

1. Добавьте конфигурацию в `flake.nix`:

```nix
nixosConfigurations = {
  "hostname" = nixpkgs.lib.nixosSystem {
    modules = [ ./nixos/hostname ];
  };
};
```

## Создание модулей

### Системный модуль (modules/common/ или modules/darwin/)

```nix
# modules/common/git.nix
{ pkgs, ... }: {
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };

  environment.systemPackages = [ pkgs.git ];
}
```

Использование в конфигурации хоста:

```nix
imports = [
  ../../modules/common/git.nix
];
```

### Home Manager модуль (modules/home-manager/)

```nix
# modules/home-manager/neovim.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.neovim;
in {
  options.programs.neovim = {
    enable = mkEnableOption "Neovim configuration";
    # дополнительные опции
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      # конфигурация
    };
  };
}
```

Использование в пользовательской конфигурации (`home/username.nix`):

```nix
imports = [
  ../modules/home-manager/neovim.nix
];

programs.neovim.enable = true;
```

### Сервис (services/)

```nix
# services/nginx.nix
{ ... }: {
  services.nginx = {
    enable = true;
    # конфигурация
  };
}
```

## Настройка AI Code Assistants

AI coding assistants (OpenCode, Claude Code, Qwen Code) настраиваются через Home Manager с использованием универсального модуля.

### Единая конфигурация в `home/kitsunoff.nix`:

```nix
# Универсальный модуль для всех AI assistants
programs.aiCodeAssistants = {
  enable = true;
  
  # Общая директория с агентами (используется всеми инструментами)
  agentsPath = ../dotfiles/agents;
  
  # OpenCode
  opencode = {
    enable = true;
    plugins = [ "opencode-alibaba-qwen3-auth" ];
    defaultModel = "alibaba/coder-model";
  };
  
  # Claude Code
  claudeCode = {
    enable = true;
    settings = {
      # Claude-специфичные настройки
    };
  };
  
  # Qwen Code
  qwenCode = {
    enable = true;
    settings = {
      # Qwen-специфичные настройки
    };
  };
};
```

**Преимущества**:

- **DRY** - агенты определяются один раз, используются везде
- **Единая точка управления** - все AI assistants в одной конфигурации
- **Гибкость** - каждый инструмент настраивается индивидуально

Подробности см. в [AI_ASSISTANTS.md](modules/home-manager/AI_ASSISTANTS.md).

### Преимущества Home Manager подхода:

1. **Декларативность** - конфигурация описана в Nix, без bash-скриптов
1. **Чистота** - файлы управляются через симлинки в XDG директории
1. **Откат** - можно откатиться к предыдущей конфигурации
1. **Портативность** - конфигурация легко переносится между системами
1. **Разделение** - пользовательские настройки отделены от системных
1. **Расширяемость** - наш модуль расширяет встроенный, а не заменяет его

### Где хранятся файлы:

- Конфигурация: `~/.config/opencode/opencode.json` (симлинк в Nix store)
- Агенты: `~/.config/opencode/agents/` (симлинк на `dotfiles/agents`)

### Наши расширения встроенного модуля:

- `plugins` - простой список плагинов вместо `settings.plugin`
- `defaultModel` - короткая опция вместо `settings.model`
- `agentsPath` - путь к директории агентов (автоматически сканирует `.md` файлы)
- `extraConfig` - дополнительные настройки, мерджатся в `settings`

**Пример**: `agentsPath = ./dotfiles/agents` автоматически импортирует все `.md` файлы из директории как агентов, преобразуя их в требуемый атрибут-сет.

## Полезные команды

```bash
# Поиск пакетов
nix search nixpkgs <package-name>

# Информация о пакете
nix-env -qa --description <package-name>

# Очистка старых поколений
nix-collect-garbage -d

# Список поколений
nix-env --list-generations

# Откат к предыдущему поколению (macOS)
darwin-rebuild switch --rollback

# Откат к предыдущему поколению (NixOS)
sudo nixos-rebuild switch --rollback
```

## Правила оформления кода

Подробные правила оформления Nix кода смотрите в [NIX_STYLE_GUIDE.md](./NIX_STYLE_GUIDE.md).

## Дополнительные ресурсы

- [nix-darwin документация](https://github.com/LnL7/nix-darwin)
- [NixOS мануал](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Home Manager](https://github.com/nix-community/home-manager)

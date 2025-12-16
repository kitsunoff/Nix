# Правила формирования Nix конфигураций

## 1. Форматирование и отступы

### Отступы
- **Использовать 2 пробела** для отступов (стандарт Nix сообщества)
- Никогда не использовать табуляцию

### Списки

```nix
# ✅ Хорошо: короткие списки в одну строку
environment.systemPackages = [ pkgs.firefox pkgs.vim ];

# ✅ Хорошо: длинные списки - каждый элемент на новой строке
environment.systemPackages = [
  pkgs.firefox
  pkgs.vim
  pkgs.git
];

# ❌ Плохо: непоследовательное форматирование
environment.systemPackages =
  [ pkgs.firefox
  ];
```

### Атрибутные множества (attribute sets)

```nix
# ✅ Хорошо: короткие множества в одну строку
user = { name = "user"; home = "/home/user"; };

# ✅ Хорошо: множества с несколькими атрибутами
user = {
  name = "user";
  home = "/home/user";
  shell = pkgs.zsh;
};

# ✅ Хорошо: вложенные множества
programs.git = {
  enable = true;
  config = {
    user.name = "Name";
    user.email = "email@example.com";
  };
};
```

### Длинные строки

```nix
# ✅ Хорошо: переносить на 80-100 символах
services.nginx.virtualHosts."example.com" = {
  enableACME = true;
  forceSSL = true;
  locations."/" = {
    proxyPass = "http://localhost:3000";
  };
};
```

### Пробелы

```nix
# ✅ Хорошо
let x = 1; in x + 2

# ❌ Плохо
let x=1;in x+2
```

---

## 2. Структура и организация

### Порядок секций в flake.nix

```nix
{
  # 1. Description
  description = "My system configuration";

  # 2. Inputs (упорядочены по важности)
  inputs = {
    nixpkgs.url = "...";
    home-manager.url = "...";
    # другие inputs...
  };

  # 3. Outputs
  outputs = inputs@{ self, nixpkgs, ... }: {
    # 3.1 nixosConfigurations / darwinConfigurations
    # 3.2 homeConfigurations
    # 3.3 packages
    # 3.4 devShells
  };
}
```

### Разделение на модули

Когда конфигурация > 200 строк, разбивать на модули:
- `./modules/system.nix` - системные настройки
- `./modules/packages.nix` - пакеты
- `./modules/programs.nix` - программы
- `./modules/services.nix` - сервисы
- `./modules/users.nix` - пользователи

```nix
# В flake.nix:
modules = [
  ./modules/system.nix
  ./modules/packages.nix
];
```

### Группировка опций

```nix
# ✅ Хорошо: логическая группировка
{
  # System
  system.stateVersion = "24.05";

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nix.gc.automatic = true;

  # Packages
  environment.systemPackages = [ ... ];

  # Programs
  programs.zsh.enable = true;

  # Services
  services.sshd.enable = true;
}
```

---

## 3. Именование и комментарии

### Именование

```nix
# ✅ Хорошо: camelCase для переменных и функций
let
  myPackages = [ ... ];
  buildInputs = [ ... ];
in

# ✅ Хорошо: kebab-case для файлов модулей
# system-packages.nix
# shell-config.nix

# ✅ Хорошо: описательные имена
let
  developmentPackages = [ pkgs.gcc pkgs.gdb ];
  pythonWithPackages = pkgs.python3.withPackages (ps: [ ps.numpy ]);
in
```

### Комментарии

```nix
# ✅ Хорошо: комментировать неочевидные решения
# Using unstable channel for latest version of package X
# because stable version has bug #12345

# ✅ Хорошо: TODO комментарии
# TODO: migrate to home-manager when ready

# ✅ Хорошо: секционные комментарии
## Development Tools ##
environment.systemPackages = [ ... ];

## System Services ##
services = { ... };

# ❌ Плохо: очевидные комментарии
# Install Firefox
pkgs.firefox
```

---

## 4. Лучшие практики

### Использование let-bindings

```nix
# ✅ Хорошо: выносить повторяющиеся значения
let
  username = "myuser";
  homeDir = "/Users/${username}";
in {
  users.users.${username} = {
    home = homeDir;
  };
}
```

### Pinning и follows

```nix
# ✅ Хорошо: использовать follows для согласованности
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";  # ← важно!
};
```

### Overlay vs packageOverrides

```nix
# ✅ Хорошо: использовать overlays для модификации пакетов
nixpkgs.overlays = [
  (final: prev: {
    myCustomPackage = prev.myPackage.override { enableFeature = true; };
  })
];
```

### Безопасность

```nix
# ✅ Хорошо: не хранить секреты в конфигурации
# Использовать agenix, sops-nix или переменные окружения

# ❌ Плохо
services.myservice.apiKey = "secret123";

# ✅ Хорошо
services.myservice.apiKeyFile = "/run/secrets/api-key";
```

### Версионирование

```nix
# ✅ Хорошо: явно указывать stateVersion и не менять без необходимости
system.stateVersion = 6;  # Не обновлять автоматически!

# ✅ Хорошо: использовать lock файл
# Коммитить flake.lock в репозиторий
```

### Условная конфигурация

```nix
# ✅ Хорошо: использовать lib.mkIf для условий
{
  programs.git = lib.mkIf config.myOptions.developmentMode {
    enable = true;
    # ...
  };
}
```

### Тестирование

```bash
# ✅ Хорошо: проверять конфигурацию перед применением
darwin-rebuild check --flake .#hostname
nixos-rebuild dry-build --flake .#hostname
```

---

## 5. Инструменты для форматирования

Рекомендуемые инструменты:
- **nixpkgs-fmt** или **alejandra** - автоформатирование
- **statix** - линтер для Nix
- **deadnix** - поиск неиспользуемого кода

```bash
# Установка
nix-shell -p nixpkgs-fmt alejandra statix deadnix

# Использование
nixpkgs-fmt flake.nix
alejandra .
statix check
deadnix -e
```

---

## 6. Структура директорий проекта

### Рекомендуемая структура для multi-host конфигурации

```
my-nixos/
├── flake.nix              # Главный flake файл
├── flake.lock             # Lock файл (коммитить!)
│
├── darwin/                # Darwin (macOS) конфигурации
│   ├── MacBook-Pro-Maxim/ # Директория для конкретного хоста
│   │   ├── default.nix    # Главная конфигурация хоста
│   │   └── hardware.nix   # (опционально) Специфичные настройки железа
│   └── MacBook-Air/       # Другой хост
│       └── default.nix
│
├── nixos/                 # NixOS (Linux) конфигурации
│   ├── server-1/          # Директория для конкретного хоста
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── desktop/
│       ├── default.nix
│       └── hardware-configuration.nix
│
├── modules/               # Переиспользуемые модули
│   ├── common/           # Общие для всех систем
│   │   ├── nix-settings.nix
│   │   └── shell.nix
│   ├── darwin/           # Специфичные для macOS
│   │   ├── homebrew.nix
│   │   └── defaults.nix
│   └── nixos/            # Специфичные для NixOS
│       ├── boot.nix
│       └── networking.nix
│
├── services/             # Конфигурации сервисов
│   ├── nginx.nix
│   ├── postgresql.nix
│   └── docker.nix
│
├── packages/             # Кастомные пакеты
│   └── my-package/
│       └── default.nix
│
├── overlays/             # Nix overlays
│   └── default.nix
│
└── users/                # Пользовательские конфигурации
    ├── maxim.nix
    └── shared.nix
```

---

## 7. Правила организации

### 7.1 Директории конфигураций хостов

**Правило:** Каждый хост должен иметь свою директорию в `darwin/` или `nixos/`

```nix
# darwin/MacBook-Pro-Maxim/default.nix
{ pkgs, ... }: {
  imports = [
    ../../modules/common/nix-settings.nix
    ../../modules/darwin/homebrew.nix
    ../../users/maxim.nix
  ];

  networking.hostName = "MacBook-Pro-Maxim";
  networking.computerName = "MacBook Pro Maxim";

  environment.systemPackages = with pkgs; [
    firefox
    vim
  ];
}
```

```nix
# flake.nix - импорт конфигураций
{
  outputs = { self, nixpkgs, nix-darwin, ... }: {
    # Darwin конфигурации
    darwinConfigurations = {
      "MacBook-Pro-Maxim" = nix-darwin.lib.darwinSystem {
        modules = [ ./darwin/MacBook-Pro-Maxim ];
      };

      "MacBook-Air" = nix-darwin.lib.darwinSystem {
        modules = [ ./darwin/MacBook-Air ];
      };
    };

    # NixOS конфигурации
    nixosConfigurations = {
      "server-1" = nixpkgs.lib.nixosSystem {
        modules = [ ./nixos/server-1 ];
      };

      "desktop" = nixpkgs.lib.nixosSystem {
        modules = [ ./nixos/desktop ];
      };
    };
  };
}
```

---

### 7.2 Модули (modules/)

**Правило:** Переиспользуемая функциональность выносится в `modules/`

**Когда создавать модуль:**
- Функциональность используется на 2+ хостах
- Логически независимый компонент (например, настройка Git)
- Более 50 строк связанной конфигурации

```nix
# modules/common/git.nix
{ config, pkgs, lib, ... }:
{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    gh  # GitHub CLI
  ];
}
```

**Структура modules/:**
```
modules/
├── common/           # Общие модули для всех ОС
│   ├── shell.nix    # Настройки shell (zsh/bash)
│   ├── git.nix      # Git конфигурация
│   └── vim.nix      # Vim/Neovim
│
├── darwin/          # Только для macOS
│   ├── homebrew.nix
│   ├── defaults.nix # macOS defaults
│   └── aerospace.nix
│
└── nixos/           # Только для NixOS
    ├── boot.nix
    ├── networking.nix
    └── xserver.nix
```

---

### 7.3 Сервисы (services/)

**Правило:** Конфигурации сервисов выносятся в `services/`

**Когда создавать файл сервиса:**
- Сложная конфигурация сервиса (более 30 строк)
- Сервис используется на нескольких хостах
- Требуется отдельная документация/комментарии

```nix
# services/nginx.nix
{ config, pkgs, lib, ... }:
{
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "example.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:3000";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

```nix
# Использование в конфигурации хоста
# nixos/server-1/default.nix
{ ... }: {
  imports = [
    ../../services/nginx.nix
    ../../services/postgresql.nix
  ];
}
```

---

### 7.4 Пользователи (users/)

**Правило:** Конфигурации пользователей в `users/`

```nix
# users/maxim.nix
{ pkgs, ... }: {
  users.users.maxim = {
    home = "/Users/maxim";
    shell = pkgs.zsh;
    description = "Maxim";
  };

  # Пакеты специфичные для пользователя
  environment.systemPackages = with pkgs; [
    # Development
    vscode
    jetbrains.idea-ultimate
  ];
}
```

```nix
# users/shared.nix - общие настройки для всех пользователей
{ ... }: {
  users.mutableUsers = false;  # Управление через Nix
}
```

---

### 7.5 Именование файлов и директорий

```nix
# ✅ Хорошо: понятные имена
modules/common/shell-config.nix
services/backup-service.nix
darwin/MacBook-Pro-Maxim/

# ❌ Плохо: аббревиатуры и нечеткие имена
modules/sh.nix
services/bkp.nix
darwin/mbp/
```

---

### 7.6 Импорты (imports)

**Правило:** Порядок импортов в конфигурации хоста

```nix
# ✅ Хорошо: логический порядок
{ ... }: {
  imports = [
    # 1. Hardware (только для NixOS)
    ./hardware-configuration.nix

    # 2. Общие модули
    ../../modules/common/nix-settings.nix
    ../../modules/common/shell.nix

    # 3. OS-специфичные модули
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/defaults.nix

    # 4. Сервисы
    ../../services/nginx.nix

    # 5. Пользователи
    ../../users/maxim.nix
  ];

  # Локальная конфигурация хоста
  networking.hostName = "MacBook-Pro-Maxim";
}
```

---

### 7.7 Комментарии в структуре

```nix
# modules/darwin/aerospace.nix

# Aerospace window manager configuration
# Docs: https://github.com/nikitabobko/AeroSpace
{ pkgs, ... }: {
  # ...
}
```

---

## 8. Миграция существующей конфигурации

Если у вас уже есть `flake.nix` с конфигурацией внутри:

### Шаги миграции

1. **Создать структуру директорий:**
```bash
mkdir -p darwin/MacBook-Pro-Maxim
mkdir -p modules/common modules/darwin modules/nixos
mkdir -p services users
```

2. **Вынести конфигурацию хоста:**
```bash
# Создать darwin/MacBook-Pro-Maxim/default.nix
# Перенести содержимое из configuration в flake.nix
```

3. **Обновить flake.nix:**
```nix
darwinConfigurations."MacBook-Pro-Maxim" = nix-darwin.lib.darwinSystem {
  modules = [ ./darwin/MacBook-Pro-Maxim ];
};
```

4. **Постепенно выносить в модули:**
   - Начать с больших блоков (packages, programs)
   - Перенести повторяющиеся части
   - Специфичные для хоста настройки оставить в `darwin/hostname/default.nix`

---

## Быстрая справка

### Чек-лист перед коммитом

- [ ] Код отформатирован (`nixpkgs-fmt` или `alejandra`)
- [ ] Нет неиспользуемого кода (`deadnix`)
- [ ] Проверка линтером (`statix check`)
- [ ] Конфигурация собирается (`darwin-rebuild check` / `nixos-rebuild dry-build`)
- [ ] `flake.lock` обновлен и закоммичен
- [ ] Нет секретов в коде
- [ ] Комментарии добавлены для неочевидных решений

### Команды для работы

```bash
# Форматирование
alejandra .

# Проверка конфигурации
darwin-rebuild check --flake .#MacBook-Pro-Maxim

# Применение конфигурации
darwin-rebuild switch --flake .#MacBook-Pro-Maxim

# Обновление зависимостей
nix flake update

# Просмотр изменений
nix flake show
```

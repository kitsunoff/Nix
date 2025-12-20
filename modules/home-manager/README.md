# Home Manager Custom Modules

Кастомные модули, расширяющие встроенные модули Home Manager.

## OpenCode Module Extension

**Файл**: `opencode.nix`

### Описание

Этот модуль **расширяет** встроенный модуль Home Manager `programs.opencode`, добавляя удобные опции-сокращения. Он не заменяет встроенный модуль, а работает поверх него.

### Зачем это нужно?

Встроенный модуль Home Manager использует более низкоуровневый API:

```nix
# Встроенный API
programs.opencode = {
  enable = true;
  settings = {
    plugin = [ "plugin1" "plugin2" ];
    model = "provider/model";
    # другие настройки
  };
  agents = ./path/to/agents;
};
```

Наше расширение добавляет более удобные опции:

```nix
# Наш расширенный API (более удобный)
programs.opencode = {
  enable = true;
  plugins = [ "plugin1" "plugin2" ];        # вместо settings.plugin
  defaultModel = "provider/model";          # вместо settings.model
  agentsPath = ./path/to/agents;            # альтернатива agents
  extraConfig = {                           # мерджится в settings
    theme = "dark";
  };
};
```

### Как это работает?

1. **Опции добавляются** к существующему `programs.opencode`
1. **В config блоке** наши опции преобразуются в стандартные:
   - `plugins` → `settings.plugin`
   - `defaultModel` → `settings.model`
   - `agentsPath` → автоматически сканирует директорию и создаёт `agents` attrset
   - `extraConfig` → мерджится в `settings`
1. **Результат**: удобный API + совместимость с встроенным модулем

### Особенность agentsPath

Встроенный модуль Home Manager ожидает `agents` как **attribute set**:

```nix
# Встроенный API
programs.opencode.agents = {
  code-reviewer = ./agents/code-reviewer.md;
  docs-writer = ./agents/docs-writer.md;
};
```

Наш модуль позволяет просто указать директорию:

```nix
# Наш расширенный API
programs.opencode.agentsPath = ./dotfiles/agents;

# Автоматически преобразуется в:
# {
#   business-analyst = ./dotfiles/agents/business-analyst.md;
#   product-vision = ./dotfiles/agents/product-vision.md;
#   task-decomposition = ./dotfiles/agents/task-decomposition.md;
#   technical-architect = ./dotfiles/agents/technical-architect.md;
# }
```

Модуль автоматически сканирует все `.md` файлы в директории!

### Технические детали

```nix
# Наш модуль НЕ объявляет programs.opencode заново
# Он только добавляет новые опции к существующему

options.programs.opencode = {
  # Новые опции
  plugins = mkOption { ... };
  defaultModel = mkOption { ... };
  # и т.д.
};

config = mkIf cfg.enable {
  # Преобразуем в стандартный API
  programs.opencode.settings = mkMerge [
    (mkIf (cfg.plugins != []) { plugin = cfg.plugins; })
    (mkIf (cfg.defaultModel != null) { model = cfg.defaultModel; })
    cfg.extraConfig
  ];
};
```

### Преимущества подхода

✅ **Совместимость** - можно использовать и наши опции, и встроенные\
✅ **Не ломает апстрим** - встроенный модуль продолжает работать\
✅ **Удобство** - более простой и понятный API\
✅ **Гибкость** - можно смешивать оба подхода

### Альтернативные подходы (НЕ используем)

❌ **disabledModules** - полностью заменить встроенный модуль

- Минус: теряем обновления из Home Manager
- Минус: дублируем код

❌ **Отдельное имя** (programs.opencode-custom)

- Минус: непонятно какой использовать
- Минус: дублируются настройки

✅ **Module overlay** (наш подход)

- Плюс: расширяем, не заменяем
- Плюс: получаем обновления из Home Manager
- Плюс: добавляем свои фичи

## AI Code Assistants Module

**Файл**: `ai-code-assistants.nix`

### Описание

Унифицированный модуль для управления AI-ассистентами кода (OpenCode, Claude Code, Qwen Code). Каждый ассистент может использовать свою собственную директорию с агентами.

### Основные возможности

#### 1. Управление плагинами и skills

Для OpenCode поддерживается автоматическая установка плагинов и множественных источников skills из Git-репозиториев.

**Superpowers Plugin + Skills** (ДЕКЛАРАТИВНО через Nix!):

```nix
programs.aiCodeAssistants = {
  enable = true;
  
  opencode = {
    enable = true;
    
    # Superpowers plugin + skills - ПОЛНОСТЬЮ ДЕКЛАРАТИВНО!
    superpowers = {
      enable = true;  # Включить superpowers плагин
      
      # Явно указываем какие skills устанавливать
      skills = [
        # Официальные superpowers skills
        {
          name = "superpowers";
          package = pkgs.fetchFromGitHub {
            owner = "obra";
            repo = "superpowers";
            rev = "main";
            sha256 = "sha256-...";
          };
          skillsDir = "skills";
        }
      ];
      
      # Опционально: указать конкретную версию плагина
      # package = pkgs.fetchFromGitHub {
      #   owner = "obra";
      #   repo = "superpowers";
      #   rev = "abc123...";  # Конкретный commit для воспроизводимости
      #   sha256 = "sha256-...";  # Hash для проверки целостности
      # };
    };
  };
};
```

**Что происходит при включении superpowers** (ДЕКЛАРАТИВНО!):

1. Nix скачивает superpowers в `/nix/store/...` (с фиксированным SHA256 hash)
1. Home Manager создаёт symlinks:
   - `~/.config/opencode/plugin/superpowers.js -> /nix/store/.../superpowers/.opencode/plugin/superpowers.js`
   - `~/.config/opencode/skills/superpowers/ -> /nix/store/.../superpowers/skills/` (если добавлено в `skills`)
1. **Явный контроль** - вы выбираете какие skills устанавливать
1. **Полностью воспроизводимо** - одинаковый hash = одинаковые файлы на всех машинах
1. **Нет императивных команд** - всё через Nix деривации

#### 2. Множественные источники Skills (ДЕКЛАРАТИВНО!)

Вы можете установить несколько источников skills одновременно:

```nix
programs.aiCodeAssistants.opencode.superpowers = {
  enable = true;
  
  # Список всех skills источников
  skills = [
    # Официальные superpowers skills
    {
      name = "superpowers";
      package = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "main";
        sha256 = "sha256-...";
      };
      skillsDir = "skills";
    }
    
    # Ваши кастомные skills
    {
      name = "my-custom-skills";
      package = pkgs.fetchFromGitHub {
        owner = "your-username";
        repo = "my-skills";
        rev = "main";
        sha256 = "sha256-...";
      };
      skillsDir = "skills";  # Путь к skills внутри репозитория
    }
    
    # Корпоративные/командные skills
    {
      name = "company-standards";
      package = pkgs.fetchFromGitHub {
        owner = "company-org";
        repo = "ai-skills";
        rev = "v1.2.0";
        sha256 = "sha256-...";
      };
      skillsDir = "opencode/skills";
    }
    
    # Локальные skills для разработки
    {
      name = "local-dev";
      package = /Users/username/dev/my-skills;
      skillsDir = ".";
    }
  ];
};
```

**Структура после установки:**

```
~/.config/opencode/skills/
├── superpowers/ -> /nix/store/xxx-superpowers/skills/
├── my-custom-skills/ -> /nix/store/yyy-my-skills/skills/
├── company-standards/ -> /nix/store/zzz-company/opencode/skills/
└── local-dev/ -> /Users/username/dev/my-skills/
```

**Приоритет skills (от высшего к низшему):**

1. **Project skills** (`.opencode/skills/`) - ВЫСШИЙ приоритет
1. **Personal skills** (`~/.config/opencode/skills/`)
1. **Installed skills** (в порядке списка `skills`)
   - Первый в списке имеет приоритет над следующими

**Использование в OpenCode:**

```
# OpenCode автоматически находит skills из всех источников
use_skill "superpowers:test-driven-development"
use_skill "my-custom-skills:my-skill"
use_skill "company-standards:code-review"
use_skill "local-dev:experimental-skill"
```

#### 3. Управление агентами для разных AI-ассистентов

```nix
programs.aiCodeAssistants = {
  enable = true;
  
  opencode = {
    enable = true;
    agentsPath = ../dotfiles/agents;
    plugins = [ "opencode-alibaba-qwen3-auth" ];
    defaultModel = "alibaba/coder-model";
  };
  
  claudeCode = {
    enable = true;
    agentsPath = ../dotfiles/agents-claude;
    # Создаст symlink: ~/.claude/agents -> ../dotfiles/agents-claude
  };
  
  qwenCode = {
    enable = true;
    agentsPath = ../dotfiles/agents-qwen;
    # Создаст symlink: ~/.qwen/agents -> ../dotfiles/agents-qwen
  };
};
```

### Как работает установка superpowers (декларативно!)

Модуль использует `home.file` для создания symlink из Nix store:

```nix
# Декларативный подход - НЕТ императивных команд!
home.file.".config/opencode/plugin/superpowers.js" = {
  source = "${cfg.opencode.superpowers.package}/.opencode/plugin/superpowers.js";
};

# где cfg.opencode.superpowers.package это:
pkgs.fetchFromGitHub {
  owner = "obra";
  repo = "superpowers";
  rev = "main";
  sha256 = "sha256-160bw8z5dhbjvz2359j9jqbiif9lwzvliqbs5amrvjk6yw6msdfp";
}
```

**Почему это лучше императивного `git clone`**:

❌ **Императивный подход** (`git clone`, `git pull`):

- Не воспроизводимо (разные версии на разных машинах)
- Зависит от состояния файловой системы
- Может сломаться при конфликтах git
- Нужно вручную управлять обновлениями

✅ **Декларативный подход** (Nix deмривации):

- **Полностью воспроизводимо** - фиксированный SHA256 hash
- **Чистая функция** - одинаковый вход = одинаковый выход
- **Атомарные обновления** - нет частично обновлённых состояний
- **Откат изменений** - через `home-manager generations`
- **Кеширование** - Nix переиспользует `/nix/store`

### Обновление superpowers до новой версии

Чтобы обновить superpowers до новой версии:

```bash
# 1. Получить новый hash для последнего main
nix-prefetch-url --unpack https://github.com/obra/superpowers/archive/refs/heads/main.tar.gz

# 2. Обновить sha256 в конфигурации
# modules/home-manager/ai-code-assistants.nix:
#   sha256 = "sha256-НОВЫЙ_ХЭШ";

# 3. Применить конфигурацию
home-manager switch
```

**Или закрепить конкретную версию** (рекомендуется для стабильности):

```nix
opencode.superpowers = {
  enable = true;
  package = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "abc123def456...";  # Конкретный commit hash
    sha256 = "sha256-...";     # Hash для этого коммита
  };
};
```

### Использование fork или local development

```nix
# Ваш форк
opencode.superpowers = {
  enable = true;
  package = pkgs.fetchFromGitHub {
    owner = "your-username";
    repo = "superpowers";
    rev = "my-feature-branch";
    sha256 = "sha256-...";
  };
};

# Локальная разработка (для тестирования изменений)
opencode.superpowers = {
  enable = true;
  package = /path/to/local/superpowers;  # Абсолютный путь
};
```

### Преимущества такого подхода

✅ **Декларативность** - вся конфигурация в одном месте\
✅ **Автоматическое обновление** - `git pull` при каждом `home-manager switch`\
✅ **Воспроизводимость** - одинаковая конфигурация на всех машинах\
✅ **Простота** - не нужно помнить команды установки\
✅ **Расширяемость** - легко добавить другие плагины по аналогии

### Добавление других плагинов

Чтобы добавить поддержку других плагинов, можно расширить модуль:

```nix
# В ai-code-assistants.nix
opencode = {
  # ... существующие опции
  
  myPlugin = {
    enable = mkEnableOption "My custom plugin";
    repository = mkOption { ... };
    rev = mkOption { ... };
  };
};

# В config блоке
home.activation.opencodeMyPlugin = mkIf (cfg.opencode.myPlugin.enable) ...
```

## Создание своих расширений

Чтобы создать расширение для другого модуля:

1. Импортируйте модуль в `home/username.nix`
1. Добавьте новые опции в `options.<program>.myOption`
1. В `config` преобразуйте их в стандартные опции
1. Используйте `mkMerge`, `mkIf` для условной настройки

Пример:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.myapp;
in {
  options.programs.myapp = {
    myConvenientOption = mkOption { ... };
  };

  config = mkIf cfg.enable {
    programs.myapp.settings = {
      # Преобразуем нашу опцию в стандартную
      standard-option = cfg.myConvenientOption;
    };
  };
}
```

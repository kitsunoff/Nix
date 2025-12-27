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

#### 1. Native OpenCode Skills (ДЕКЛАРАТИВНО через Nix!)

OpenCode 1.0+ поддерживает нативные skills через директорию `~/.opencode/skill/`. Модуль автоматически создаёт symlinks из вашей dotfiles директории.

**Конфигурация:**

```nix
programs.aiCodeAssistants = {
  enable = true;
  
  opencode = {
    enable = true;
    
    # Путь к директории со skills
    # Каждая поддиректория должна содержать SKILL.md с YAML frontmatter
    skillsPath = ../dotfiles/skills;
  };
};
```

**Формат SKILL.md (нативный OpenCode):**

```markdown
---
name: my-skill
description: Brief description of when to use this skill
license: MIT
---

# My Skill

Instructions and guidelines...
```

**Требования к имени skill:**
- 1-64 символа
- Только lowercase буквы, цифры и одиночные дефисы
- Не может начинаться или заканчиваться на `-`
- Не может содержать `--`
- Имя должно совпадать с именем директории

**Структура директории skills:**

```
dotfiles/skills/
├── business-analyst/
│   └── SKILL.md
├── code-reviewer/
│   └── SKILL.md
├── product-vision/
│   └── SKILL.md
├── technical-architect/
│   └── SKILL.md
└── task-decomposition/
    └── SKILL.md
```

**После активации Home Manager:**

```
~/.opencode/skill/
├── business-analyst/ -> /nix/store/.../skills/business-analyst/
├── code-reviewer/ -> /nix/store/.../skills/code-reviewer/
└── ...
```

**Использование в OpenCode:**

```
# OpenCode автоматически обнаруживает skills
# Они доступны через нативный skill tool
skill({ name: "code-reviewer" })
skill({ name: "business-analyst" })
```

**Преимущества нативных skills над плагинами:**

✅ **Официальная поддержка** - встроенная функциональность OpenCode
✅ **YAML frontmatter** - чистый и понятный формат
✅ **Автоматическое обнаружение** - skills появляются в tool description
✅ **Контроль permissions** - можно настраивать доступ через opencode.json

#### 2. Управление агентами для разных AI-ассистентов

```nix
programs.aiCodeAssistants = {
  enable = true;
  
  opencode = {
    enable = true;
    agentsPath = ../dotfiles/agents;        # OpenCode agents
    skillsPath = ../dotfiles/skills;         # Native OpenCode skills
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

### Как работает установка skills (декларативно!)

Модуль использует `home.file` для создания symlinks:

```nix
# Декларативный подход - НЕТ императивных команд!
# Для каждой skill директории создаётся symlink:
home.file.".opencode/skill/${skillName}" = {
  source = cfg.opencode.skillsPath + "/${skillName}";
  recursive = true;
};
```

**Почему это лучше ручной установки**:

✅ **Декларативный подход** (Nix):

- **Полностью воспроизводимо** - одинаковые файлы на всех машинах
- **Атомарные обновления** - нет частично обновлённых состояний
- **Откат изменений** - через `home-manager generations`
- **Кеширование** - Nix переиспользует `/nix/store`

### Добавление новых skills

Чтобы добавить новый skill:

1. Создайте директорию в `dotfiles/skills/my-skill/`
2. Создайте файл `SKILL.md` с YAML frontmatter:

```markdown
---
name: my-skill
description: Brief description of when to use this skill
license: MIT
---

# My Skill

Your skill instructions here...
```

3. Примените конфигурацию: `darwin-rebuild switch --flake .`

### Преимущества нативных skills

✅ **Официальная поддержка** - встроенная функциональность OpenCode 1.0+
✅ **Простой формат** - YAML frontmatter + Markdown
✅ **Декларативность** - вся конфигурация в Nix
✅ **Воспроизводимость** - одинаковая конфигурация на всех машинах
✅ **Расширяемость** - легко добавить новые skills

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

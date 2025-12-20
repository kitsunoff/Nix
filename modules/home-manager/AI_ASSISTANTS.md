# Unified AI Code Assistants Module

Универсальный модуль для управления несколькими AI-ассистентами программирования через единую конфигурацию.

## Поддерживаемые инструменты

- **OpenCode** - Open-source AI coding assistant
- **Claude Code** - Anthropic's AI coding assistant
- **Qwen Code** - Alibaba's AI coding assistant

## Основная идея

Вместо дублирования конфигурации для каждого инструмента, этот модуль позволяет:

1. **Единое место для агентов** - одна директория с агентами используется всеми инструментами
1. **Независимая настройка** - каждый инструмент можно включить/выключить отдельно
1. **Специфические настройки** - для каждого инструмента свои дополнительные опции

## Использование

### Базовая конфигурация

```nix
programs.aiCodeAssistants = {
  enable = true;
  
  # Общая директория с агентами
  agentsPath = ./dotfiles/agents;
  
  # Включить все инструменты
  opencode.enable = true;
  claudeCode.enable = true;
  qwenCode.enable = true;
};
```

### Полная конфигурация

```nix
programs.aiCodeAssistants = {
  enable = true;
  
  # Агенты в Markdown формате (совместимы со всеми инструментами)
  agentsPath = ../dotfiles/agents;
  
  # OpenCode конфигурация
  opencode = {
    enable = true;
    plugins = [
      "opencode-alibaba-qwen3-auth"
    ];
    defaultModel = "alibaba/coder-model";
    extraConfig = {
      theme = "dark";
      autoSave = true;
    };
  };
  
  # Claude Code конфигурация
  claudeCode = {
    enable = true;
    settings = {
      model = "claude-sonnet-4";
      enableMcp = true;
    };
  };
  
  # Qwen Code конфигурация
  qwenCode = {
    enable = true;
    settings = {
      model = "qwen/coder";
      theme = "dark";
    };
  };
};
```

## Формат агентов

Все инструменты используют единый формат агентов - Markdown файлы с YAML frontmatter:

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and best practices
tools: Read, Grep, Glob  # Опционально, зависит от инструмента
model: sonnet            # Опционально, зависит от инструмента
---

You are a senior code reviewer specializing in security and performance.

When reviewing code:
1. Check for security vulnerabilities
2. Assess performance implications
3. Verify error handling
4. Ensure code maintainability

Provide actionable feedback with specific examples.
```

### Примеры агентов

#### Специалист по тестированию

```markdown
---
name: testing-expert
description: Writes comprehensive unit and integration tests
---

You are a testing specialist focused on creating high-quality, maintainable tests.

For each testing task:
1. Analyze code structure and dependencies
2. Identify key functionality and edge cases
3. Create comprehensive test suites
4. Include proper setup/teardown
5. Add meaningful assertions
```

#### Автор документации

```markdown
---
name: documentation-writer
description: Creates detailed documentation, READMEs, and API docs
---

You are a technical documentation specialist.

Focus on:
- Clear API documentation with examples
- Step-by-step user guides
- Architecture overviews
- Troubleshooting sections

Always verify code examples and keep docs in sync with implementation.
```

## Директорная структура

```
# OpenCode использует XDG стандарт
~/.config/opencode/
├── opencode.json          # Генерируется из конфигурации
└── agents/               # Симлинк → ~/my-nixos/dotfiles/agents

# Claude Code использует dotfile в home
~/.claude/
├── settings.json         # Управляется через UI Claude Code
├── history.jsonl         # Runtime данные
├── debug/                # Runtime данные
├── projects/             # Runtime данные
└── agents/               # Симлинк → ~/my-nixos/dotfiles/agents ⬅ СОЗДАЁТСЯ НАМИ

# Qwen Code использует dotfile в home
~/.qwen/
├── settings.json         # Управляется через UI Qwen Code
├── oauth_creds.json      # Runtime данные
├── installation_id       # Runtime данные
└── agents/               # Симлинк → ~/my-nixos/dotfiles/agents ⬅ СОЗДАЁТСЯ НАМИ
```

**Важно**:

- Мы **НЕ управляем** директориями `.claude/` и `.qwen/` полностью
- Мы **ТОЛЬКО создаём** симлинк `agents/` внутри них
- Это позволяет Claude Code и Qwen Code управлять своими настройками через UI
- При этом агенты остаются под контролем Nix

**Примечание**: Claude Code и Qwen Code также ищут `.claude/` и `.qwen/` директории в корне проекта для project-specific конфигурации.

## Как это работает

### OpenCode

OpenCode полностью управляется через Nix:

- Конфигурация: `~/.config/opencode/opencode.json` (генерируется из Nix)
- Агенты: `~/.config/opencode/agents/` (симлинк на dotfiles)

### Claude Code и Qwen Code

Для Claude Code и Qwen Code используется **гибридный подход**:

1. **Runtime данные и настройки** - управляются приложениями:

   ```
   ~/.claude/settings.json     # UI настройки
   ~/.claude/history.jsonl     # История
   ~/.qwen/settings.json       # UI настройки
   ~/.qwen/oauth_creds.json    # Авторизация
   ```

1. **Агенты** - управляются через Nix:

   ```bash
   # Home Manager создаст симлинки:
   ~/.claude/agents → ~/my-nixos/dotfiles/agents
   ~/.qwen/agents   → ~/my-nixos/dotfiles/agents
   ```

1. **Результат**:

   - Приложения сами управляют своими настройками через UI
   - Агенты версионируются и управляются декларативно через Nix
   - Нет конфликтов между Nix и runtime данными

### Почему не управляем settings.json?

❌ **Проблема если бы управляли**:

```nix
# Nix создаёт settings.json
home.file.".claude/settings.json" = { text = "..."; };

# Claude Code перезаписывает при изменении настроек через UI
# Конфликт! При следующем home-manager switch изменения потеряются
```

✅ **Правильный подход**:

```nix
# Nix управляет только агентами
home.file.".claude/agents" = { source = ./agents; };

# Claude Code свободно управляет settings.json через UI
# Никаких конфликтов!
```

## Преимущества подхода

### ✅ DRY (Don't Repeat Yourself)

Агенты определяются один раз, используются везде:

```nix
# Было бы без универсального модуля:
programs.opencode.agents = { ... };
programs.claudeCode.agents = { ... };  # Дублирование!
programs.qwenCode.agents = { ... };    # Дублирование!

# С универсальным модулем:
programs.aiCodeAssistants.agentsPath = ./agents;  # Один раз!
```

### ✅ Единая точка управления

Все AI-ассистенты настраиваются в одном месте:

```nix
programs.aiCodeAssistants = {
  agentsPath = ./agents;      # Общее
  opencode.enable = true;     # Специфичное
  claudeCode.enable = false;  # Специфичное
};
```

### ✅ Гибкость

Каждый инструмент можно настроить индивидуально, сохраняя общие агенты:

```nix
programs.aiCodeAssistants = {
  agentsPath = ./agents;  # Общие агенты
  
  opencode = {
    plugins = [ "qwen-auth" ];        # Только для OpenCode
    defaultModel = "alibaba/model";   # Только для OpenCode
  };
  
  claudeCode = {
    settings.model = "claude-sonnet"; # Только для Claude Code
  };
};
```

### ✅ Легкость добавления новых инструментов

Чтобы добавить поддержку нового AI coding assistant, нужно только:

1. Добавить секцию в опции модуля
1. Добавить конфигурацию в `config` блок
1. Всё! Агенты автоматически подхватятся

## Совместимость с индивидуальными модулями

Универсальный модуль работает ВМЕСТЕ с индивидуальными модулями расширения:

```nix
imports = [
  ../modules/home-manager/opencode.nix          # Расширение встроенного
  ../modules/home-manager/ai-code-assistants.nix # Универсальный модуль
];

# Можно использовать ОБА подхода одновременно:

# 1. Через универсальный модуль (рекомендуется)
programs.aiCodeAssistants = {
  opencode.enable = true;
  opencode.plugins = [ ... ];
};

# 2. Напрямую через расширенный модуль (если нужно)
programs.opencode = {
  plugins = [ ... ];          # Наше расширение
  extraConfig = { ... };      # Наше расширение
};
```

## Миграция с отдельных конфигураций

### Было (отдельно для каждого инструмента):

```nix
# OpenCode
programs.opencode = {
  enable = true;
  plugins = [ "qwen-auth" ];
  agentsPath = ./agents;
};

# Claude Code (гипотетически)
programs.claudeCode = {
  enable = true;
  agents = ./agents;  # Дублирование!
};
```

### Стало (единая конфигурация):

```nix
programs.aiCodeAssistants = {
  enable = true;
  agentsPath = ./agents;  # Один раз!
  
  opencode = {
    enable = true;
    plugins = [ "qwen-auth" ];
  };
  
  claudeCode.enable = true;
};
```

## Лучшие практики

### 1. Используйте понятные имена агентов

```markdown
---
name: react-performance-optimizer  # ✅ Описательное
name: helper                       # ❌ Слишком общее
---
```

### 2. Пишите подробные описания

```markdown
---
description: Optimizes React components using profiling and best practices  # ✅
description: Helps with React                                              # ❌
---
```

### 3. Держите агентов в version control

```bash
dotfiles/
└── agents/
    ├── code-reviewer.md
    ├── testing-expert.md
    └── documentation-writer.md
```

### 4. Тестируйте агентов на простых задачах

Перед использованием нового агента в production, протестируйте его на простых примерах.

### 5. Версионируйте изменения агентов

При изменении поведения агента, сделайте git commit с пояснением:

```bash
git commit -m "feat(agents): improve code-reviewer to check for performance issues"
```

## Расширение модуля

Чтобы добавить поддержку нового AI coding assistant:

```nix
# В modules/home-manager/ai-code-assistants.nix

options.programs.aiCodeAssistants = {
  # ... существующие опции ...
  
  newAssistant = {
    enable = mkEnableOption "New AI Assistant";
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Settings for New AI Assistant";
    };
  };
};

config = mkIf cfg.enable {
  # ... существующая конфигурация ...
  
  # Добавить новую конфигурацию
  xdg.configFile."newassistant/agents" = mkIf (cfg.newAssistant.enable && cfg.agentsPath != null) {
    source = cfg.agentsPath;
    recursive = true;
  };
  
  xdg.configFile."newassistant/config.json" = mkIf cfg.newAssistant.enable {
    text = builtins.toJSON cfg.newAssistant.settings;
  };
};
```

## Troubleshooting

### Агенты не появляются

1. Проверьте, что файлы агентов имеют расширение `.md`
1. Убедитесь, что `agentsPath` указывает на существующую директорию
1. Проверьте логи: `journalctl --user -u home-manager-*`

### Конфликты конфигураций

Если вы используете и универсальный модуль, и прямую конфигурацию, убедитесь что они не конфликтуют:

```nix
# ❌ Конфликт
programs.aiCodeAssistants.opencode.plugins = [ "a" ];
programs.opencode.plugins = [ "b" ];  # Что использовать?

# ✅ Выберите один подход
programs.aiCodeAssistants.opencode.plugins = [ "a", "b" ];
```

## См. также

- [OpenCode модуль](./opencode.nix) - расширение встроенного модуля HM
- [Документация OpenCode](https://opencode.ai/docs)
- [Документация Claude Code](https://code.claude.com/docs)
- [Документация Qwen Code](https://qwenlm.github.io/qwen-code-docs/)

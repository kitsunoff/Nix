# Quick Start Guide

Быстрый старт для применения конфигурации AI Code Assistants.

## Перед применением

### 1. Проверьте текущее состояние

```bash
# Проверьте существующие агенты
ls -la ~/.config/opencode/agents/  # OpenCode
ls -la ~/.claude/agents/           # Claude Code (пока нет)
ls -la ~/.qwen/agents/             # Qwen Code (пока нет)

# Проверьте агенты в dotfiles
ls -la ~/my-nixos/dotfiles/agents/
```

### 2. Исправьте права на flake.lock

```bash
cd ~/my-nixos
sudo chown kitsunoff:staff flake.lock
```

## Применение конфигурации

### Шаг 1: Обновить зависимости

```bash
cd ~/my-nixos
nix flake update
```

### Шаг 2: Проверить конфигурацию

```bash
darwin-rebuild check --flake .#MacBook-Pro-Maxim
```

### Шаг 3: Собрать без активации (опционально)

```bash
# Посмотреть что изменится
darwin-rebuild build --flake .#MacBook-Pro-Maxim

# Сравнить с текущей системой
nvd diff /run/current-system ./result
```

### Шаг 4: Применить изменения

```bash
darwin-rebuild switch --flake .#MacBook-Pro-Maxim
```

## После применения

### Проверка результата

```bash
# Проверьте что симлинки созданы
ls -la ~/.config/opencode/agents/  # → dotfiles/agents
ls -la ~/.claude/agents/           # → dotfiles/agents (новый!)
ls -la ~/.qwen/agents/             # → dotfiles/agents (новый!)

# Проверьте содержимое
ls ~/.claude/agents/
# Должны увидеть:
# business-analyst.md
# product-vision.md
# task-decomposition.md
# technical-architect.md
```

### Проверка в приложениях

#### OpenCode
```bash
# Запустите OpenCode
opencode

# В чате попросите:
> /agents

# Должны увидеть ваших агентов
```

#### Claude Code
```bash
# Откройте Claude Code
# Используйте команду /agents или упомяните агента:
> Use the business-analyst agent to analyze this feature
```

#### Qwen Code
```bash
# Откройте Qwen Code
# Используйте команду /agents или упомяните агента:
> Use the technical-architect agent to design this system
```

## Добавление новых агентов

### 1. Создайте Markdown файл

```bash
cd ~/my-nixos/dotfiles/agents
cat > my-new-agent.md << 'EOF'
---
name: my-new-agent
description: Brief description of when to use this agent
---

System prompt for the agent goes here.
Define the agent's expertise and behavior.
EOF
```

### 2. Примените изменения

```bash
cd ~/my-nixos
darwin-rebuild switch --flake .#MacBook-Pro-Maxim
```

### 3. Проверьте

```bash
# Агент автоматически появится во всех инструментах
ls ~/.config/opencode/agents/my-new-agent.md
ls ~/.claude/agents/my-new-agent.md
ls ~/.qwen/agents/my-new-agent.md
```

## Редактирование агентов

### Способ 1: Редактировать в dotfiles

```bash
# Отредактируйте файл
vim ~/my-nixos/dotfiles/agents/business-analyst.md

# Примените изменения (если нужна немедленная перезагрузка)
darwin-rebuild switch --flake .#MacBook-Pro-Maxim

# ИЛИ просто перезапустите AI assistant
# (симлинки указывают на dotfiles, изменения видны сразу)
```

### Способ 2: Коммит в git

```bash
cd ~/my-nixos
git add dotfiles/agents/
git commit -m "feat(agents): improve business-analyst prompt"
```

## Отключение AI assistants

Если хотите отключить какой-то инструмент:

```nix
# В home/kitsunoff.nix
programs.aiCodeAssistants = {
  enable = true;
  agentsPath = ../dotfiles/agents;
  
  opencode.enable = true;
  claudeCode.enable = false;  # Отключено
  qwenCode.enable = true;
};
```

Симлинк `~/.claude/agents/` не будет создан, но `.claude/` директория с настройками останется нетронутой.

## Troubleshooting

### Симлинки не создались

```bash
# Проверьте что home-manager активировался
home-manager generations

# Посмотрите логи
journalctl --user -u home-manager-kitsunoff -n 50
```

### Агенты не видны в приложении

1. Перезапустите приложение
2. Проверьте формат `.md` файлов (YAML frontmatter корректный?)
3. Проверьте права доступа:
   ```bash
   ls -la ~/my-nixos/dotfiles/agents/
   # Должны быть readable
   ```

### Изменения в dotfiles не применяются

Если вы редактируете агентов в `dotfiles/agents/`, изменения видны сразу через симлинки. Пересборка не требуется!

Но если вы:
- Добавили новый `.md` файл
- Изменили конфигурацию в `home/kitsunoff.nix`

Тогда нужен rebuild:
```bash
darwin-rebuild switch --flake .#MacBook-Pro-Maxim
```

## Откат изменений

Если что-то пошло не так:

```bash
# Откатиться к предыдущей конфигурации
darwin-rebuild switch --rollback

# Или к конкретному поколению
darwin-rebuild switch --flake .#MacBook-Pro-Maxim --switch-generation 42
```

## Следующие шаги

1. Прочитайте [AI_ASSISTANTS.md](modules/home-manager/AI_ASSISTANTS.md) для деталей
2. Настройте git (обновите email в `home/kitsunoff.nix`)
3. Добавьте свои агенты в `dotfiles/agents/`
4. Экспериментируйте с настройками OpenCode в `home/kitsunoff.nix`

## Полезные команды

```bash
# Посмотреть все опции home-manager
man home-configuration.nix

# Список доступных пакетов
nix search nixpkgs <package>

# Очистка старых поколений
nix-collect-garbage -d

# Проверить размер Nix store
du -sh /nix/store

# Обновить только home-manager (быстрее)
home-manager switch --flake .
```

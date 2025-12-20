# Universal Agent Format

Универсальный формат для AI coding assistant агентов, совместимый с OpenCode, Claude Code и Qwen Code.

## Формат

```yaml
---
# ОБЯЗАТЕЛЬНЫЕ ПОЛЯ (используются всеми инструментами)
name: agent-name              # Имя агента (lowercase, kebab-case)
description: Brief description of when to use this agent

# ОПЦИОНАЛЬНЫЕ ПОЛЯ (специфичны для разных инструментов)

# Модель (Claude Code, OpenCode)
model: sonnet                 # sonnet | opus | haiku | inherit
temperature: 0.3              # 0.0 - 1.0

# Инструменты (все инструменты)
tools:                        # OpenCode format (complex)
  read: true
  write: true
  bash: false
  
# ИЛИ упрощённый формат (автоматически конвертируется)
toolsList: Read, Write, Bash  # Claude/Qwen format (simple list)

# Права доступа (OpenCode-специфичное)
permission:
  edit: allow                 # allow | deny | ask
  bash: deny

# Режим работы (OpenCode)
mode: subagent                # subagent | inline

# Дополнительные настройки (Claude Code)
permissionMode: default       # default | acceptEdits | bypassPermissions | plan
skills: skill1, skill2        # Auto-load skills
---

# System Prompt (общий для всех инструментов)

Основной текст системного промпта идёт здесь.
Этот текст используется всеми инструментами без изменений.

## Guidelines

- Instruction 1
- Instruction 2

## Process

1. Step 1
2. Step 2
```

## Правила конвертации

### В Claude Code формат

```yaml
# Из универсального формата
name: code-reviewer
description: Reviews code for quality
model: sonnet
toolsList: Read, Grep, Glob

# Конвертируется в
---
name: code-reviewer
description: Reviews code for quality  
model: sonnet
tools: Read, Grep, Glob
---
[System prompt остаётся без изменений]
```

### В Qwen Code формат

```yaml
# Из универсального формата
name: code-reviewer
description: Reviews code for quality
model: sonnet
toolsList: Read, Grep, Glob

# Конвертируется в
---
name: code-reviewer
description: Reviews code for quality
tools: Read, Grep, Glob
---
[System prompt остаётся без изменений]
```

### В OpenCode формат

```yaml
# Из универсального формата
name: code-reviewer
description: Reviews code for quality
model: sonnet
temperature: 0.3
tools:
  read: true
  write: false
  bash: false

# OpenCode использует встроенный модуль HM, который преобразует в settings
# Наш расширяющий модуль добавляет агентов через agentsPath
```

## Минималистичный формат (рекомендуется)

Для большинства агентов достаточно:

```yaml
---
name: my-agent
description: What this agent does and when to use it
---

You are an expert in...

Your responsibilities:
- Task 1
- Task 2
```

Этот формат работает везде "из коробки".

## Расширенный формат

Если нужен точный контроль:

```yaml
---
name: my-agent
description: What this agent does

# Claude/Qwen simple format
toolsList: Read, Write, Bash
model: sonnet

# OpenCode detailed format (если нужен)
tools:
  read: true
  write: true
  bash: true
permission:
  edit: allow
  bash: deny
temperature: 0.5
---

System prompt...
```

## Примеры

### Минимальный агент

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and maintainability
---

You are a senior code reviewer. Focus on:
- Code quality and readability
- Security vulnerabilities
- Performance issues
- Best practices
```

### Агент с ограниченными правами

```markdown
---
name: read-only-analyzer
description: Analyzes code without making changes
toolsList: Read, Grep, Glob
---

You are a code analyzer. You can only read files and search.
Never suggest changes, only provide analysis.
```

### Агент с кастомной моделью

```markdown
---
name: quick-helper
description: Fast responses for simple questions
model: haiku
temperature: 0.7
---

You are a quick assistant for simple questions.
Keep answers brief and to the point.
```

## Преимущества универсального формата

1. **Write Once, Run Everywhere** - один файл работает во всех инструментах
1. **Обратная совместимость** - старые агенты продолжают работать
1. **Гибкость** - можно добавлять специфичные для инструмента поля
1. **Простота** - минимальный формат очень простой
1. **Мощность** - расширенный формат даёт полный контроль

## Миграция существующих агентов

### Из OpenCode формата

```yaml
# Было (OpenCode)
---
description: Business analyst
mode: subagent
tools:
  write: true
  edit: false
---

# Стало (Универсальный)
---
name: business-analyst  # ДОБАВИТЬ!
description: Business analyst
toolsList: Write        # Упростить или оставить tools:
---
```

### Из Claude Code формата

```yaml
# Было (Claude)
---
name: reviewer
description: Code reviewer
tools: Read, Grep
---

# Стало (Универсальный) - уже совместим!
---
name: reviewer
description: Code reviewer
toolsList: Read, Grep  # Опционально переименовать в toolsList
---
```

## Автоматическая конвертация

Nix модуль автоматически конвертирует форматы:

```nix
# dotfiles/agents/my-agent.md (универсальный формат)
# ↓
# ~/.config/opencode/agents/my-agent.md (OpenCode формат)
# ~/.claude/agents/my-agent.md (Claude формат)
# ~/.qwen/agents/my-agent.md (Qwen формат)
```

Конвертация происходит на лету при активации home-manager.

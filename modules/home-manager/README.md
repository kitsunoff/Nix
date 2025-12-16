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
2. **В config блоке** наши опции преобразуются в стандартные:
   - `plugins` → `settings.plugin`
   - `defaultModel` → `settings.model`
   - `agentsPath` → автоматически сканирует директорию и создаёт `agents` attrset
   - `extraConfig` → мерджится в `settings`
3. **Результат**: удобный API + совместимость с встроенным модулем

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

✅ **Совместимость** - можно использовать и наши опции, и встроенные  
✅ **Не ломает апстрим** - встроенный модуль продолжает работать  
✅ **Удобство** - более простой и понятный API  
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

## Создание своих расширений

Чтобы создать расширение для другого модуля:

1. Импортируйте модуль в `home/username.nix`
2. Добавьте новые опции в `options.<program>.myOption`
3. В `config` преобразуйте их в стандартные опции
4. Используйте `mkMerge`, `mkIf` для условной настройки

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

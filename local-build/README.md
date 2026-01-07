# Локальная сборка

## Что нужно

Установить и включить Docker Desktop. Для macOs:

```shell
brew install --cask docker
```

Установить зависимости yq и just:

```shell
brew install just yq
```

## Как пользоваться

Все команды нужно вызывать из корневой папки проекта.

### Интерактивный режим

```shell
just build
```

Сценарий скрипта:

- читает конфигурацию из build.yaml
- показывает доступные варианты сборки
- просит выбрать конфигурацию для сборки
- запускает docker для сборки прошивки
- выводит путь к файлу прошивки .uf2

### Режим командной строки

```shell
# Сборка по номеру их списка конфигураций
just build -n 1

# Сборка но названию shield (можно по частичному совпадению)
just build -s "totem_dongle"

# Сборка по board и shield (точное совпадение)
just build -b nice_nano -s "charybdis_dongle prospector_adapter"

# Отобрахить список всех конфигураций
just build -l
just list

# Отобразить справку
just build -h

# Очистить зависимости
just build --clean
just clean
```

### Кэшерирование зависимостей

Скрипт сохраняет постоянное рабочее пространство west:

- `local-build/workspace/`

Этот каталог игнорируется и содержит проверенные зависимости (`zephyr/`, `zmk/`, `modules/` и т. д.), поэтому последующие сборки не загружают все повторно.

Полезные флаги:

- `--clean` (псевдоним: `--clean-deps`): удаляет оба:
  - `local-build/workspace/` (зависимости; принудительно свежие `west update`)
  - `local-build/artifact/` (артифакты прошивки)

### Как это работает

Этот скрипт сохраняет git репозиторий чистотым, используя отдельное рабочее пространство west,:

- `local-build/workspace/`

Исключение: сборанные прошивки, они сохраняются в `firmware/` и индексируются Git, чтобы в Git репозитории всегда были актуальные прошивки.

Внутри контейнера Docker скрипт монтирует:

- `/repo`: репозиторий (источники только для чтения для `config/`, `boards/`, `dts/`, `modules/` и `zephyr/module.yml`)
- `/workspace`: рабочее пространство west (содержит `.west/`, `zephyr/`, `zmk/`, `modules/` и т. д.)
- `/out`: build outputs (будет писать в `local-builds/artifact/`)

Каждая сборка копирует:

- `/repo/config` → `/workspace/config` (так что `west init -l` инициализируется в рабочем пространстве)
- `/repo/boards`, `/repo/dts`, `/repo/zephyr/module.yml` → `/workspace/zmk-config/` (как правильный модуль Zephyr)
- `/repo/modules/*` → `/workspace/modules/`

Затем он выполняет:

- `west init -l /workspace/config` (только при необходимости)
- `west update` (только если зависимости отсутствуют, например, первая сборка или после --clean)
- `west build ... -DZMK_CONFIG=/workspace/config -DZMK_EXTRA_MODULES=/workspace/zmk-config`

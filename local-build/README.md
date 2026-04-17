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
- выводит путь к итоговому файлу в `firmware/` (например, `lapka_dongle-xiao_ble_zmk.uf2`)

### Режим командной строки

```shell
# Сборка по номеру их списка конфигураций
just build -n 1

# Сборка по названию shield (можно по частичному совпадению)
just build -s "lapka_dongle"

# Сборка по board и shield (точное совпадение)
just build -b "nice_nano//zmk" -s "charybdis_peripheral_left"

# Отобрахить список всех конфигураций
just build -l
just list

# Отобразить справку
just build -h

# Очистить зависимости
just build --clean
just clean
```

### Кэширование зависимостей

Скрипт сохраняет постоянное рабочее пространство west:

- `local-build/workspace/`

Этот каталог игнорируется git и содержит зависимости west (`zephyr/`, `zmk/`, `modules/` и т. д.), поэтому последующие сборки не загружают их повторно.

Полезные флаги:

- `--clean` (псевдоним: `--clean-deps`): удаляет оба:
  - `local-build/workspace/` (зависимости; при следующей сборке будет выполнен свежий `west update`)
  - `local-build/artifact/` (временные артефакты сборки)
- `--update`: принудительно выполняет `west update` перед сборкой

### Как это работает

Этот скрипт сохраняет git-репозиторий чистым, используя отдельное рабочее пространство west:

- `local-build/workspace/`

Итоговые прошивки сохраняются в `firmware/` и доступны как `*.uf2` файлы.

Внутри контейнера Docker скрипт монтирует:

- `/repo`: репозиторий (источники только для чтения)
- `/workspace`: рабочее пространство west
- `/out`: временные build outputs (на хосте это `local-build/artifact/`)

Каждая сборка копирует в `/workspace` только нужные исходники из репозитория:

- `/repo/config` → `/workspace/config`
- `/repo/boards`, `/repo/dts`, `/repo/app`, `/repo/zephyr/module.yml` → `/workspace/zmk-config/`
- для Charybdis дополнительно копируются `config/includes/layers.h` и `config/charybdis_pointer.dtsi`

Затем он выполняет:

- `west init -l config` (только при необходимости)
- `west update` (только если `zmk/` ещё нет или был указан `--update`)
- `west build ... -DZMK_CONFIG=/workspace/config -DZMK_EXTRA_MODULES=/workspace/zmk-config`

# ZMK Config

Конфигурация и прошивка для моих клавиатур:

1. **[Charybdis Nano](#charybdis-nano)** – основная
2. [Lapka](#lapka)

## Оглавление

- [Основные возможности](#основные-возможности)
- [Режимы работы](#режимы-работы)
- [Модули](#модули)
- [Прошивка](#прошивка)
- [FAQ](#faq)
- [Клавиатуры](#клавиатуры)
- [Tester Pro Micro](#tester-pro-micro)
- [Скрипты](#скрипты)
- [Раскладка](#раскладка)
- [Дополнительные настройки ОС](#дополнительные-настройки-ос)
- [Ссылки](#ссылки)

## Основные возможности

- **Локальная сборка** через Docker, актуальные прошивки в папке `firmware/`
- **Home-Row Mods** на базе идеи [urob](https://github.com/urob/zmk-config#timeless-homerow-mods)
- **Универсальная раскладка** [universal-layout](https://github.com/braindefender/universal-layout) и [wellum](https://github.com/braindefender/wellum) (без OSSM)
- **Гибкая схема работы**: с донглом или без (одна половинка — главная)
- **Адаптирована для macOS**
- **Скрипты** для сборки, прошивки, отрисовки keymap

## Режимы работы

**Без донгла (standalone):**

Одна половинка — главная (по Bluetooth к ПК). Вторая подключается по Bluetooth к ней.
Для Charybdis главная — правая половина (там трекбол).

**С донглом (dongle mode):**

Донгл — главный (USB/Bluetooth к ПК). Обе половинки — периферия (Bluetooth к донглу).

**Варианты донглов:**

- nice!nano v2 / Seeeduino XIAO BLE — просто плата с USB
- Prospector Dongle — экран: слой, батарея, статус, модификаторы; на базе XIAO BLE
- Dongle Display — мини-OLED (128x32 / 128x64); на базе nice!nano

## Модули

### Helpers

- [zmk-helpers](https://github.com/urob/zmk-helpers) - полезные макросы.

### Drivers

- [zmk-pmw3610-driver](https://github.com/badjeff/zmk-pmw3610-driver) - модуль драйвера для сенсора PMW3610. Нужен для трекбола в клавиатуре Charybdis.

### Behaviors & Input processors

- [zmk-smart-toggle](https://github.com/caksoylar/zmk-smart-toggle) - модуль для "smart toggle". В проекте используется для `swapper` и `tabber`.
- [zmk-input-processor-keybind](https://github.com/zettaface/zmk-input-processor-keybind) - модуль, который преобразует движения трекбола в нажатия стрелок. Полезно так двигать каретку в полях ввода. Нужен для трекбола в клавиатуре Charybdis.
- ~~[zmk-pointing-acceleration](https://github.com/oleksandrmaslov/zmk-pointing-acceleration) - добавляет ускорение трекбола.~~
- [zmk-scroll-snap](https://github.com/kot149/zmk-scroll-snap) - добавляет привязку прокрутки трекбола к осям X или Y.

### Dongle

- [prospector-zmk-module](https://github.com/carrefinho/prospector-zmk-module) - модуль для донгла Prospector.
- [zmk-dongle-display](https://github.com/englmaxi/zmk-dongle-display) - модуль для донгла с OLED-экраном.

## Прошивка

### Сборка

Подробнее о локальной сборке в [local-build](local-build/README.md).

### Загрузка прошивки

Чтобы перевести половинку или донгл в режим прошивки, нужно нажать кнопку Reset дважды или, если ее нет, замкнуть пины RST и GND дважды.

Стабильная процедура первичной привязки половинок к донглу. Используйте ее, когда половинки еще не привязаны или есть проблемы с подключением:

1. Подключить донгл и прошить в него файл `settings_reset.uf2`
2. Отключить донгл от провода и отложить в сторону
3. Подключить левую половинку и прошить в неё сначала `settings_reset.uf2`, затем `peripheral_left.uf2`
4. Подключить правую половинку и прошить в неё сначала `settings_reset.uf2`, затем `peripheral_right.uf2`
5. Подключить донгл и прошить в него `dongle.uf2`
6. Включить донгл, затем левую половину, затем правую половину (именно в таком порядке)

Когда нет донгла, левая половина является основной (если правая, то меняем местами):

1. Подключить правую половинку и прошить в неё сначала `settings_reset.uf2`, затем `peripheral_right.uf2`
2. Подключить левую половинку и прошить в неё сначала `settings_reset.uf2`, затем `central_left.uf2`

Если половины уже привязаны к донглу и была изменена только dongle.uf2, то достаточно прошить только ее.

## FAQ

### На экране донгла индикаторы аккумуляторов половин перепутаны

Нужно заново привязать клавиатуры к донглу: перепрошить половины и донгл прошивкой сброса, как описано выше.
Порядок включения: донгл, затем левая (!) половина, затем правая половина.

### В IntelliJ IDEA и VS Code некорректно работают сочетания `Cmd+[`/`Cmd+]` на ru-раскладке

Частично решается через Karabiner-Elements: добавьте правило Complex Modifications из раздела ниже
(`Universal Layout fixes for GUI layer`).

### UF2-накопитель не появляется после двойного reset

Проверьте кабель: для прошивки нужен USB-кабель с передачей данных, а не только питание.
Если накопитель не появился, повторите двойной reset с меньшим интервалом и попробуйте другой USB-порт.

### После прошивки половинки не связываются по BLE

Сбросьте связи на всех устройствах через `settings_reset.uf2` и повторите привязку по инструкции из раздела
"Загрузка прошивки". В режиме с донглом соблюдайте порядок включения: донгл, затем левая, затем правая половина.

## Клавиатуры

### [Charybdis Nano](https://github.com/bastardkb/charybdis/)

Заказывал kit у продавца на AliExpress, плата hot-swap, поэтому в прошивке есть отличия от оригинальной:

- Для каждого свитча отдельная платка, все они соединяются проводками. Пока что не нашел какой форк [SU120](https://github.com/e3w2q/su120-keyboard) они использовали
- Изменены пины колонок и строк
- Изменено направление диодов: я припаял диоды так как было показано на плате, в итоге оказалось для совместимости с оригинальной прошивкой надо было наоборот
- Изменен matrix transform

**Особенности:**

- Используется модуль [zmk-input-processor-keybind](https://github.com/zettaface/zmk-input-processor-keybind), который позволяет трекболом двигать каретку в полях ввода
- Используется модуль [zmk-pointing-acceleration](https://github.com/oleksandrmaslov/zmk-pointing-acceleration) для ускорения трекбола
- Используется модуль [zmk-scroll-snap](https://github.com/kot149/zmk-scroll-snap) для привязки движения каретки к осям X и Y.
- В режиме без донгла основной половиной будет правая (central_right)

![Charybdis keymap](./draw/charybdis.svg?raw=true "Charybdis keymap")
_(keymap image created with [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer))_

**Прошивка:**

- `just flash -s "charybdis_dongle_prospector"` - прошивка донгла Prospector (XIAO + prospector_adapter)
- `just flash -s "charybdis_central_right"` - прошивка правой половины как основной
- `just flash -s "charybdis_peripheral_left"` - прошивка левой половины для работы с донглом
- `just flash -s "charybdis_peripheral_right"` - прошивка правой половины (как для работы с донглом, так и когда левая основная)

Особенность в том, что во время сборки скрипт копирует папку `config/includes` и файл `charybdis_pointer.dtsi` в папку `<zmk config local workspace>/boards/shields/charybdis`, так как не все общие конфигурации удалось вынести.

### [Lapka](https://github.com/braindefender/lapka)

![Lapka keymap](./draw/lapka.svg?raw=true "Lapka keymap")
_(keymap image created with [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer))_

**Прошивка:**

- `just flash -s "lapka_dongle" -b "xiao_ble//zmk"` - прошивка донгла на XIAO
- `just flash -s "lapka_dongle" -b "nice_nano//zmk"` - прошивка донгла на nice!nano
- `just flash -s "lapka_dongle_prospector"` - прошивка донгла Prospector
- `just flash -s "lapka_central_left"` - прошивка левой половины как основной
- `just flash -s "lapka_peripheral_left"` - прошивка левой половины для работы с донглом
- `just flash -s "lapka_peripheral_right"` - прошивка правой половины (как для работы с донглом, так и когда левая основная)

## Tester Pro Micro

Прошивка для проверки пинов на плате ProMicro nRF52840 (aka nice!nano и других клонов). Копия из [репозитория](https://github.com/choovick/zmk-config-charybdis) @choovick.
В прошивке отключен Bluetooth, работает только по USB.

**Прошивка:**

`just flash -s "tester_pro_micro"`

**Порядок действий:**

1. Прошить tester_pro_micro-nice_nano_zmk.uf2
2. Подключить контроллер по USB к компьютеру
3. Открыть любой текстовый редактор
4. Замкнуть GPIO пин с GND, тот который проверяем
5. В текстовом редакторе должно напечататься "pin X", где X - номер пина
6. Проверить все пины

## Скрипты

Все в папке `scripts`. Для упрощения используется [Just](https://github.com/casey/just).

### `build.sh`

Локальная сборка прошивок, подробнее в [local-build](local-build/README.md).
Справка: `just build --help`
Список таргетов: `just build --list`

### `flash.sh`

Прошивка клавиатур.
Справка: `just flash --help`
Список прошивок: `just flash --list`

### `draw.sh`

Отрисовка keymap.
Справка: `just draw --help`
Список keymap: `just draw --list`

## Раскладка

В папке `layout` — форк [universal-layout](https://github.com/braindefender/universal-layout).

Отличия:

- разделение на два языка: ru и en
- поправлен слой GUI (Cmd), чтобы как надо работали сочетания клавиш
- добавлены иконки флажков, чтобы в системе было видно какая сейчас раскладка
- раскладка только для macOS

### Установка Universal Layout

На macOS:

1. Файл `layouts/macOS/Universal.bundle` скопировать в `~/Library/Keyboard Layouts`.
2. Перезагрузиться или перезайти в систему.
3. Выбрать желаемую раскладку в Настройки системы > Клавиатура > Источники ввода.
4. Удалить стандартные раскладки русского и английского языка. [Здесь](https://4te.me/post/flags-tray-macos/) описано как их удалить.
5. Снова перезагрузиться или перезайти в систему.

## Дополнительные настройки ОС

### Karabiner-Elements

Для поддержки переключения языка через сочетание клавиш (Cmd+F11/F12) нужно установить программу [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements).
В настройках Complex Modifications добавьте свое правило и вставьте этот код:

```json
{
    "description": "Set language on Cmd+F11/F12",
    "manipulators": [
        {
            "from": {
                "key_code": "f11",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [{ "select_input_source": { "language": "ru" } }],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "f12",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [{ "select_input_source": { "language": "en" } }],
            "type": "basic"
        }
    ]
}
```

Для того чтобы сочетания `Cmd+[`, `Cmd+]` и другие работали одинаково на раскладках ru и en в IntelliJ IDEA и VS Code, нужно добавить правило Complex Modifications.
В нем происходят преобразования:

- `.` -> `[`
- `/` -> `]`
- `[` -> `,`
- `]` -> `.`
- `\` -> `/`

```json
{
    "description": "Universal Layout fixes for GUI layer",
    "manipulators": [
        {
            "from": {
                "key_code": "period",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "open_bracket",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "slash",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "close_bracket",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "open_bracket",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "comma",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "close_bracket",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "period",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "backslash",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "slash",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        }
    ]
}
```

## Ссылки

### Charybdis

- [charybdis-3-5-dongle-prospector-studio](https://github.com/devpew/charybdis-3-5-dongle-prospector-studio) от @devpew – Charybdis + ZMK Studio
- [charybdis-wireless-mini-zmk-firmware](https://github.com/280Zo/charybdis-wireless-mini-zmk-firmware) от @280Zo – Charybdis, home-row mods, скрипты для локальной сборки
- [zmk-config-charybdis-mini-wireless](https://github.com/aystream/zmk-config-charybdis-mini-wireless) от @aystream – Charybdis
- [charybdis_zmk](https://github.com/nophramel/charybdis_zmk) от @nophramel – Charybdis
- [zmk-config-charybdis](https://github.com/choovick/zmk-config-charybdis) от @choovick – Charybdis, локальная сборка, tester pro micro
- [charybdis-zmk](https://github.com/vloth/charybdis-zmk) от @vloth – Charybdis

### Lapka

- [lapka-zmk-config](https://github.com/braindefender/lapka-zmk-config) – официальный репозиторий прошивки для Lapka

### Другие

- [zmk-config](https://github.com/urob/zmk-config) от @urob – home-row mods
- [zmk-config](https://github.com/minusfive/zmk-config) от @minusfive – кастомные стили для keymap-drawer
- [zmk-config](https://github.com/mctechnology17/zmk-config) от @mctechnology17 – локальная сборка и makefile
- [keymap-drawer](https://github.com/caksoylar/keymap-drawer) – отрисовка keymap
- [universal-layout](https://github.com/braindefender/universal-layout) – универсальная раскладка от @braindefender
- [wellum](https://github.com/braindefender/wellum) – универсальная раскладка для split-клавиатур от @braindefender

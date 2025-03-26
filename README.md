# Corne ZMK Config

Конфигурация и прошивка для клавиатур Corne, Nijuni, Dao и других Corne-подобных клавиатур.

## Особенности

- Переключение языка на RU/EN происходит через комбо: D+F → RU, J+K → EN
- Запятая, точка, вопрос выведены в отдельный слой чтобы не зависеть от раскладки, сделано через клавиши F13/14/15

## Keymap

![Keymap Representation](./keymap-drawer/corne.svg?raw=true "Keymap Representation")

Сгенерировано с помощью [`keymap-drawer`](https://github.com/caksoylar/keymap-drawer).

## Прошивка

После изменения конфигурации прошивка будет собрана в Actions. Там же можно ее скачать.

1. Подключить по usb сначала донгл (если есть), потом левую и правую половины
2. Зажать два раза кнопку Reset (или замкнуть контакты RST и GND).
3. В проводнике появться подключенная флешка. Перекинуть на нее нужную прошивку.

### С донглом

Для донгла:
- с контроллером nice! - "corne_central_dongle-nice-nano-v2-zmk.uf2"
- с контроллером xiao - "corne_central_dongle-seeeduino_xiao_ble-zmk.uf2"

Для левой половины - "corne_peripheral_left-nice_nano_v2-zmk.uf2".
Для правой половины - "corne_peripheral_right-nice_nano_v2-zmk.uf2".

### Без донгла

Для левой половины - "corne_central_left-nice_nano_v2-zmk.uf2".
Для правой половины - "corne_peripheral_right-nice_nano_v2-zmk.uf2".

## Дополнительные настройки ОС

### macOS

Для поддержки переключения языка через комбо и ввод ", . ?" нужно установить программу Karabiner-Elements.
Для поддержки переключения языка в настройках, в Complex Modifications добавить свое правило и вставить этот код:

```json
{
    "description": "Set language on GUI+F11/F12",
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

Для поддержки ", . ?" точно также создать свое правило и вставить этот код:

```json
{
    "description": "Replace F13/14/15 to to ,.?",
    "manipulators": [
        {
            "conditions": [
                {
                    "input_sources": [{ "language": "en" }],
                    "type": "input_source_if"
                }
            ],
            "from": {
                "key_code": "f13",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "comma" }],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "input_sources": [{ "language": "ru" }],
                    "type": "input_source_if"
                }
            ],
            "from": {
                "key_code": "f13",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                {
                    "key_code": "6",
                    "modifiers": ["left_shift"]
                }
            ],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "input_sources": [{ "language": "en" }],
                    "type": "input_source_if"
                }
            ],
            "from": {
                "key_code": "f14",
                "modifiers": { "optional": ["any"] }
            },
            "to": [{ "key_code": "period" }],
            "type": "basic"
        },
        {
            "conditions": [
                {
                    "input_sources": [{ "language": "ru" }],
                    "type": "input_source_if"
                }
            ],
            "from": {
                "key_code": "f14",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                {
                    "key_code": "7",
                    "modifiers": ["left_shift"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "f15",
                "modifiers": { "optional": ["any"] }
            },
            "to": [
                {
                    "key_code": "slash",
                    "modifiers": ["shift"]
                }
            ],
            "type": "basic"
        }
    ]
}
```

## Ссылки

1. Примеры конфигураций:
   1. [corne-keyboard-layout](https://github.com/devpew/corne-keyboard-layout) от @devpew
   2. [one-zmk-config](https://github.com/ergonautkb/one-zmk-config) от @ergonautkb
   3. [zmk-config](https://github.com/minusfive/zmk-config) от @minusfive
   4. [zmk-config](https://github.com/mctechnology17/zmk-config) от @mctechnology17
2. [keymap-editor](https://nickcoutsos.github.io/keymap-editor) - сайт, на котором можно редактировать лайауты в gui
3. [keymap-drawer](https://github.com/caksoylar/keymap-drawer) - отрисовка keymap
4. [universal-layout](https://github.com/braindefender/universal-layout) - универсальная раскладка от @braindefender
   1. [wellum](https://github.com/braindefender/wellum) - универсальная раскладка для split-клавиатур от @braindefender

# Corne ZMK Config

Конфигурация и прошивка для клавиатур Corne, Nijuni, Dao и других Corne-подобных клавиатур.

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

## Особенности

- Переключение языка на RU/EN происходит через комбо: D+F → RU, J+K → EN
- Запятая, точка, вопрос выведены в отдельный слой чтобы не зависеть от раскладки, сделано через клавиши KP_N1, KP_N2, KP_N3

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
    "description": "Replace KP 1/2/3 to ,.?",
    "manipulators": [
        {
            "from": { "key_code": "keypad_1" },
            "to": [
                {
                    "key_code": "period",
                    "modifiers": []
                }
            ],
            "type": "basic"
        },
        {
            "from": { "key_code": "keypad_2" },
            "to": [
                {
                    "key_code": "comma",
                    "modifiers": []
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "keypad_3",
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

1. [corne-keyboard-layout](https://github.com/devpew/corne-keyboard-layout) от @devpew
2. [one-zmk-config](https://github.com/ergonautkb/one-zmk-config) от @ergonautkb
3. [keymap-editor](https://nickcoutsos.github.io/keymap-editor/) - сайт, на котором можно редактировать лайауты в gui
4. [keymap-drawer](https://github.com/caksoylar/keymap-drawer/) - отрисовка keymap

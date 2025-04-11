# Corne ZMK Config

Конфигурация и прошивка для клавиатур Corne, Nijuni, Dao и других Corne-подобных клавиатур.

## Особенности

- Работает с форком универсальной раскладкой ([universal-layout](https://github.com/braindefender/universal-layout))
- За основу взята раскладка [wellum](https://github.com/braindefender/wellum)
- Адаптирована для macOS

## Keymap

![Keymap Representation](./draw/corne.svg?raw=true "Keymap Representation")

Сгенерировано с помощью [`keymap-drawer`](https://github.com/caksoylar/keymap-drawer).

## Прошивка

Актуальные прошивки лежат в папке firmware.

- `nice_corne_central_dongle.uf2` - донгл на nice!
- `xiao_corne_central_dongle.uf2` - донгл на xiao
- `nice_corne_central_left.uf2` - левая половина для работы без донгла
- `nice_corne_peripheral_left.uf2` - левая половина для работы с донглом
- `nice_corne_peripheral_right.uf2` - правая половина

### Вручную

1. Подключить по usb сначала донгл (если есть), потом левую и правую половины
2. Зажать два раза кнопку Reset (или замкнуть контакты RST и GND).
3. В проводнике появться подключенная флешка. Перекинуть на нее нужную прошивку.

### Через командную строку

В корне проекта вызвать такие команды:

- `make flash_nice_corne_central_dongle` - прошивка донгла на nice!
- `make flash_nice_corne_central_left` - прошивка левой половины для работы с донглом
- `make flash_nice_corne_left` - прошивка левой половины для работы с донглом
- `make flash_nice_corne_right` - прошивка правой половины

Затем подключить донгл/клавиатуры и зажать два раза кнопку Reset (или замкнуть контакты RST и GND).

### Сборка

Установить и включить Docker Desktop.

Вызвать в командрой строке:

```shell
make codebase
make build_corne
```

## Дополнительные настройки ОС

### macOS

В папке layout лежит кастомная раскладка на основе [universal-layout](https://github.com/braindefender/universal-layout). Ее нужно установить.

В ней находятся две раскладки (русская и английская). У каждой есть иконка.

[Здесь](https://4te.me/post/flags-tray-macos/) описано как убрать стандартную английскую раскладку.

Для поддержки переключения языка через комбо (Cmd+F11/F12) нужно установить программу Karabiner-Elements.
В настройках, в Complex Modifications добавить свое правило и вставить этот код:

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

## Ссылки

1. Примеры конфигураций:
   1. [corne-keyboard-layout](https://github.com/devpew/corne-keyboard-layout) от @devpew
   2. [zmk-config](https://github.com/minusfive/zmk-config) от @minusfive
   3. [zmk-config](https://github.com/mctechnology17/zmk-config) от @mctechnology17
   4. [zmk-config](https://github.com/urob/zmk-config) от @urob
2. [keymap-editor](https://nickcoutsos.github.io/keymap-editor) - сайт, на котором можно редактировать лайауты в gui
3. [keymap-drawer](https://github.com/caksoylar/keymap-drawer) - отрисовка keymap
4. [universal-layout](https://github.com/braindefender/universal-layout) - универсальная раскладка от @braindefender
   1. [wellum](https://github.com/braindefender/wellum) - универсальная раскладка для split-клавиатур от @braindefender

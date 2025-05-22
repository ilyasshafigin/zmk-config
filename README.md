# Corne ZMK Config

Конфигурация и прошивка для клавиатур Corne (Nijuni, Dao и других Corne-подобных клавиатур)

## Особенности

- Работает с форком универсальной раскладкой ([universal-layout](https://github.com/braindefender/universal-layout))
- За основу взята раскладка [wellum](https://github.com/braindefender/wellum)
- Адаптирована для macOS

## Corne

### Keymap

![Keymap Representation](./draw/corne.svg?raw=true "Keymap Representation")

### Прошивки

Актуальные прошивки лежат в папке firmware.

Команды для прошивки:

- `just flash seeeduino_xiao_ble corne_dongle` - прошивка донгла на XIAO
- `just flash nice_nano_v2 corne_dongle` - прошивка донгла на nice!
- `just flash nice_nano_v2 corne_central_left` - прошивка левой половины для работы с донглом
- `just flash nice_nano_v2 corne_peripheral_left` - прошивка левой половины для работы с донглом
- `just flash nice_nano_v2 corne_peripheral_right` - прошивка правой половины

## Прошивка

### Вручную

1. Подключить по usb сначала донгл (если есть), потом левую и правую половины
2. Зажать два раза кнопку Reset (или замкнуть контакты RST и GND).
3. В проводнике появться подключенная флешка. Перекинуть на нее нужную прошивку.

### Через командную строку

В корне проекта вызвать такие команды:

- `just flash <board> <keyboard>_dongle` - прошивка донгла
- `just flash <board> <keyboard>_central_left` - прошивка левой половины для работы с донглом
- `just flash <board> <keyboard>_peripheral_left` - прошивка левой половины для работы с донглом
- `just flash <board> <keyboard>_peripheral_right` - прошивка правой половины

Затем подключить донгл/клавиатуры и зажать два раза кнопку Reset (или замкнуть контакты RST и GND).

### Сборка

Установить и включить Docker Desktop.

Вызвать в командрой строке:

```shell
just init
just build corne
```

## Universal layout

В проекте в папке `layout` лежат файлы раскладок. Это форк [universal-layout](https://github.com/braindefender/universal-layout).

Отличия:

- разделение на два языка: ru и en
- поправлен слой GUI (Cmd), чтобы как надо работали сочетания клавишь
- добавлены иконки флажков, чтобы в системе было видно какая сейчас раскладка
- раскладка только для macOS

### Установка

#### macOS

1. Файл `layouts/macOS/Universal.bundle` скопировать в `~/Library/Keyboard Layouts`.
2. Перезагрузиться или перезайти в систему.
3. Выбрать желаемую раскладку в Настройки системы > Клавиатура > Источники ввода.
4. Удалить стандартные раскладки русского и английского языка. [Здесь](https://4te.me/post/flags-tray-macos/) описано как их.
5. Снова перезагрузиться или перезайти в систему.

### Проблемы

1. В IntelliJ IDEA и VC Code (в них есть поиск комбинаций клавиш по нажатым клавишам) не верно работают комбинации клавиш `Cmd+[`/`Cmd+]` (и другие, где клавиши поменяны местами) на русской раскладке. Работает как будто слой Cmd не был изменен, но он изменен. В Ukelele в русской раскладке для слоя Cmd все символы точно такие же расположены как и для английской раскладки.

## Дополнительные настройки ОС

### macOS

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

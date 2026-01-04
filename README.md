# ZMK Config

Конфигурация и прошивка для клавиатур:

1. [Corne](https://github.com/foostan/crkbd) (Nijuni, Dao и других Corne-подобных клавиатур)
2. **[TOTEM](https://github.com/GEIGEIGEIST/TOTEM)** – сейчас основная
3. [Charybdis Nano 3x5](https://github.com/bastardkb/charybdis/)

## Особенности

- Home-Row Mods (на основе работы [urob](https://github.com/urob/zmk-config#timeless-homerow-mods))
- Работает с форком универсальной раскладкой ([universal-layout](https://github.com/braindefender/universal-layout))
- За основу взята раскладка [wellum](https://github.com/braindefender/wellum)
- Адаптирована для macOS
- Прошивки собираются локально (через Docker)

## Прошивка

### Сборка

Установить и включить Docker Desktop.

Вызвать в командрой строке:

```shell
just init
just build corne
```

### Загрузка прошивки

Подключить по usb правую половину, потом левую, в последнюю очередь донгл (если есть). Во время прошивки донгла или одной из половин, все остальные должны быть отключены.

Если необходимо перейти на другой донгл или клавиатуры (и донгл) просто не видят друг друга, нужно перед загрузкой основной прошивки прошить settings_reset. Здесь все также как и с основной.

После прошивки включаем донгл (если есть), затем обе половины. Все должно заработать через несклько секунд.

#### Вручную

1. Зажать два раза кнопку Reset (или замкнуть контакты RST и GND).
2. В проводнике появться подключенная флешка. Перекинуть на нее нужную прошивку.

#### Через командную строку

В корне проекта вызвать такие команды:

- `just flash <board> <keyboard>_dongle` - прошивка донгла
- `just flash <board> <keyboard>_central_left` - прошивка левой половины как основной
- `just flash <board> <keyboard>_peripheral_left` - прошивка левой половины для работы с донглом
- `just flash <board> <keyboard>_peripheral_right` - прошивка правой половины
- `just flash <board> settings_reset` - загрузка прошивки сброса

Затем подключить донгл/клавиатуры и зажать два раза кнопку Reset (или замкнуть контакты RST и GND).

## Corne

### Keymap

![Keymap Representation](./draw/corne.svg?raw=true "Keymap Representation")

### Прошивки

Актуальные прошивки лежат в папке firmware.

Сборка:

`just build corne`

Команды для прошивки:

- `just flash xiao_ble corne_dongle` - прошивка донгла на XIAO
- `just flash nice_nano corne_dongle` - прошивка донгла на nice!
- `just flash nice_nano corne_central_left` - прошивка левой половины как основной
- `just flash nice_nano corne_peripheral_left` - прошивка левой половины для работы с донглом
- `just flash nice_nano corne_peripheral_right` - прошивка правой половины (как для работы с донглом, так и когда левая основная)

## Totem

### Keymap

![Keymap Representation](./draw/totem.svg?raw=true "Keymap Representation")

### Прошивки

Актуальные прошивки лежат в папке firmware.

Сборка:

`just build totem`

Команды для прошивки:

- `just flash xiao_ble totem_dongle` - прошивка донгла на XIAO
- `just flash xiao_ble totem_dongle+dongle_screen` - прошивка донгла Prospector (Dongle Screen YADS)
- `just flash xiao_ble totem_dongle+prospector_adapter` - прошивка донгла Prospector
- `just flash xiao_ble totem_central_left` - прошивка левой половины как основной
- `just flash xiao_ble totem_peripheral_left` - прошивка левой половины для работы с донглом
- `just flash xiao_ble totem_peripheral_right` - прошивка правой половины (как для работы с донглом, так и когда левая основная)

## Charybdis Nano

Заказывал kit у китайцев на AliExpress, она how-swap, потому в прошивке есть отличия от оригинальной:

- для каждого свитча отдельная платка, все они соединяются проводками
- изменены пины колонок и строк
- изменено направление диодов: я припаял диоды так как было показано на плате, в итоге оказалось для совместимости с оригинальной прошивкой надо было наоборот
- изменен maxtrix transform

### Keymap

Для отрисовки нужно вызвать команду `just draw charybdis -d boards/shields/charybdis/charybdis_layout.dtsi`

![Keymap Representation](./draw/charybdis.svg?raw=true "Keymap Representation")

### Прошивки

Актуальные прошивки лежат в папке firmware.

Сборка:

`just build charybdis`

Команды для прошивки:

- `just flash xiao_ble charybdis_dongle` - прошивка донгла на XIAO
- `just flash xiao_ble charybdis_dongle+prospector_adapter` - прошивка донгла Prospector
- `just flash xiao_ble charybdis_central_left` - прошивка левой половины как основной
- `just flash xiao_ble charybdis_peripheral_left` - прошивка левой половины для работы с донглом
- `just flash xiao_ble charybdis_peripheral_right` - прошивка правой половины (как для работы с донглом, так и когда левая основная)

Особенность в том, что во вреся сборки скрипт копирует папку `config/includes` и файл `charybdis_pointer.dtsi` в папку `boards/shields/charybdis`, так как не все общие конфигурации удалось вынести. После сборки скопированные файлы удаляются.

## Universal layout

В проекте в папке `layout` лежат файлы раскладок. Это форк [universal-layout](https://github.com/braindefender/universal-layout).

Отличия:

- разделение на два языка: ru и en
- поправлен слой GUI (Cmd), чтобы как надо работали сочетания клавиш
- добавлены иконки флажков, чтобы в системе было видно какая сейчас раскладка
- раскладка только для macOS

### Установка

#### macOS

1. Файл `layouts/macOS/Universal.bundle` скопировать в `~/Library/Keyboard Layouts`.
2. Перезагрузиться или перезайти в систему.
3. Выбрать желаемую раскладку в Настройки системы > Клавиатура > Источники ввода.
4. Удалить стандартные раскладки русского и английского языка. [Здесь](https://4te.me/post/flags-tray-macos/) описано как их удалить.
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
   2. [charybdis-3-5-dongle-prospector-studio](https://github.com/devpew/charybdis-3-5-dongle-prospector-studio) от @devpew – charybdis + zmk studio
   3. [zmk-config](https://github.com/minusfive/zmk-config) от @minusfive – кастомные стили для keymap-drawer
   4. [zmk-config](https://github.com/mctechnology17/zmk-config) от @mctechnology17 – локальная сборка и makefile
   5. [zmk-config](https://github.com/urob/zmk-config) от @urob – home-row mods
   6. [charybdis-wireless-mini-zmk-firmware](https://github.com/280Zo/charybdis-wireless-mini-zmk-firmware) от @280Zo – charybdis, home-row mods, скрипты для локальной сборки
   7. [charybdis_zmk](https://github.com/nophramel/charybdis_zmk) от @nophramel – charybdis
2. [keymap-editor](https://nickcoutsos.github.io/keymap-editor) – сайт, на котором можно редактировать лайауты в gui
3. [keymap-drawer](https://github.com/caksoylar/keymap-drawer) – отрисовка keymap
4. [universal-layout](https://github.com/braindefender/universal-layout) – универсальная раскладка от @braindefender
   - [wellum](https://github.com/braindefender/wellum) – универсальная раскладка для split-клавиатур от @braindefender

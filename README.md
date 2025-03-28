# Corne ZMK Config

Конфигурация и прошивка для клавиатур Corne, Nijuni, Dao и других Corne-подобных клавиатур.

## Особенности

- Работает с универсальной раскладкой ([universal-layout](https://github.com/braindefender/universal-layout))
- За основу взята раскладка [wellum](https://github.com/braindefender/wellum)

## Keymap

![Keymap Representation](./keymap-drawer/corne.svg?raw=true "Keymap Representation")

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

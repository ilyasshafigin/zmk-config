# Corne ZMK Config

Конфигурация и прошивка для клавиатур Corne, Nijuni, Dao и других Corne-подобных клавиатур.

На основе проектов:
- [corne-keyboard-layout](https://github.com/devpew/corne-keyboard-layout) от @devpew
- [one-zmk-config](https://github.com/ergonautkb/one-zmk-config) от @ergonautkb

## Keymap

![Keymap Representation](./keymap-drawer/corne.svg?raw=true "Keymap Representation")

Сгенерировано с помощью [`keymap-drawer`](https://github.com/caksoylar/keymap-drawer).

## Прошивка

После изменения конфигурации прошивка будет собрана в Actions. Там же можно ее скачать.

### С донглом

Для донгла:
- с контроллером nice! - "corne_central_dongle-nice-nano-v2-zmk.uf2"
- с контроллером xiao - "corne_central_dongle-seeeduino_xiao_ble-zmk.uf2"

Также, если вы используете ключ, загрузите "периферийный" uf2 для левой и правой частей

Для левой половины - "corne_peripheral_left-nice_nano_v2-zmk.uf2".
Для правой половины - "corne_peripheral_right-nice_nano_v2-zmk.uf2".

### Без донгла

Для левой половины - "corne_central_left-nice_nano_v2-zmk.uf2".
Для правой половины - "corne_peripheral_right-nice_nano_v2-zmk.uf2".

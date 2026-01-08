# zmk-trackball-arrows

ZMK модуль, который преобразует движения трекбола в нажатия стрелок. Полезно так двигать каретку в полях ввода.

Пример использования:

```dtsi
&trackball_arrows {
    threshold = <20>;
    deadzone-x = <1>;
    deadzone-y = <1>;
}

&trackball_listener {

    ...

    caret {
        layers = <CARE>;
        input-processors = <&trackball_arrows>;
    };
}
```

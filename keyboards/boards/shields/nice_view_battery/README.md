# nice!view-battery peripheral screen

Based on [infely/nice-view-battery](https://github.com/infely/nice-view-battery),
commit `a9ebccd6309e21525577dc35fea4eb107bda7cd1`.

## Changes from upstream

- Port canvas drawing, image descriptors and rotation to LVGL 9, using aligned L8 buffers.
- Support peripheral halves only; reject central and non-split configurations.
- Replace the battery illustration with a large Montserrat percentage, auto-sized for the current value.
- Remove the unused upstream battery illustration, mask and bundled font.
- Rotate the percentage by -90 degrees on the left Temporal half and +90 degrees on the right.
- Leave 8-pixel gaps below the status header and above the bottom edge.
- Set an opaque background explicitly so areas outside the widgets have the same color.
- Use current nice!view serial VCOM inversion with a 33 ms interval.
- Allocate an 8192-byte LVGL heap and a 4096-byte dedicated display stack.

## Retained behavior

- Original connection and charging icons; the charging icon is placed in the status header.
- Battery, USB and connection updates remain event-driven; no animation or new polling timer.
- Optional color inversion.

## Licensing

- Original MIT license: `LICENSE`.

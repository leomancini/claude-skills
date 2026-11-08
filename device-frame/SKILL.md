---
name: device-frame
description: Put phone screenshots into a device frame (iPhone bezel mockup) as transparent PNGs, using the bundled frame or any frame PNG with a transparent screen cutout. Use this whenever the user wants screenshots "in a device frame", "in a phone frame", "in an iPhone mockup", "framed", "wrapped in a bezel", or asks to make app screenshots look like they're on a device, including batch requests over a folder of screenshots.
---

# Device Frame

Composite screenshots into a device-frame PNG so they look like they're on a real phone. The
heavy lifting lives in `scripts/frame.sh` (zsh + ImageMagick 7). Run it rather than
re-deriving the compositing by hand: the edge handling is subtle and the script already
gets it right.

## Quick start

```bash
# Frame every screenshot in a folder; outputs land next to the inputs as NAME-framed.png
~/.claude/skills/device-frame/scripts/frame.sh ~/Downloads/AP/*.PNG

# Use a frame the user supplied instead of the bundled iPhone
~/.claude/skills/device-frame/scripts/frame.sh --frame ~/Downloads/AP/device-frame.png ~/Downloads/AP/IMG_*.PNG

# Write to a separate folder, overwrite earlier outputs
~/.claude/skills/device-frame/scripts/frame.sh --out ~/Downloads/AP/framed --force ~/Downloads/AP/*.PNG
```

The script skips the frame file itself and anything already ending in the output suffix, so
globbing a whole folder is safe. Run `frame.sh --help` for all options.

## Workflow

1. **Look in the folder first.** If it contains a PNG with a transparent screen area (often
   named something like `device-frame.png` or `mockup.png`), the user wants that frame: pass
   it with `--frame`. Otherwise use the bundled `assets/iphone-black.png` (iPhone with Dynamic
   Island, 946x1864, screen cutout 784x1702).
2. **Run the script** over the screenshots. Check the printed `leak=` value is 0 for each; a
   non-zero leak means screenshot pixels escaped the phone body, usually because the frame's
   outer edge has gaps.
3. **Inspect one result at full resolution**, not just a thumbnail. Crop a screen corner and
   an outer bezel corner with `magick OUT.png -crop 160x160+60+60 +repage -background magenta
   -flatten -scale 300% /tmp/corner.png` and view it. The user judges these by their edges.
4. Report the output paths and sizes. Mention that the background is transparent.

## Why the script does what it does

Knowing these lets you adapt when a frame misbehaves.

- **Cutout detection.** The screen is found by flood-filling the frame's alpha from the
  top-left corner: whatever stays transparent after the fill is the screen. Tiny leftover
  islands (a lone transparent pixel in the bezel's anti-aliasing) are dropped with a
  connected-components area threshold. Without that step a stray pixel gets dilated into a
  visible blob at the frame's corner.
- **Soft edges come from the frame, not the mask.** A hard-thresholded mask makes the
  rounded screen corners jagged. Instead the screenshot extends a few pixels (`--pad`, default
  5) under the bezel and the frame is composited over it, so the frame's own anti-aliased
  inner edge defines the boundary.
- **Resolution.** By default the frame is upscaled so its screen cutout matches the
  screenshot's native width. Upscaling a smooth bezel 1.5x is barely visible; downscaling UI
  text is. Use `--native` when the user wants the frame's exact pixel size.
- **Aspect mismatch.** Screenshots are cover-fitted to the cutout and center-cropped. iPhone
  screenshots and iPhone frames differ by well under 1%, so this is invisible. If a
  screenshot's aspect is far off (a tablet shot into a phone frame), tell the user it was
  cropped rather than silently shipping it.
- **The Dynamic Island / notch** is part of the opaque frame and sits over the screenshot's
  status bar, as on the real device. That is expected, not a bug.

## Frames

`assets/iphone-black.png` is the bundled default. Any frame works if it is a PNG whose screen
area is fully transparent and whose outer background is transparent and connected to the
image corners. If a user supplies a frame on an opaque background, the flood fill will fail
("could not find a transparent screen cutout"); remove the background first.

## Troubleshooting

- `leak > 0`: open the output over magenta and find the stray pixels. Usually the frame has a
  gap in its outer edge; close it with `-morphology Close Disk:2` on the frame's alpha, or
  lower `--pad`.
- Blob or speck at a frame corner: the stray-pixel filter missed it. Raise the
  `area-threshold` in the script or clean the frame's alpha.
- Visible seam just inside the bezel: `--pad` is too small for an upscaled frame; try 8.

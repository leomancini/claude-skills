#!/bin/zsh
# Composite screenshots into a device frame PNG that has a transparent screen cutout.
#
# Usage: frame.sh [options] IMAGE...
#   --frame PATH     Frame PNG with transparent screen area (default: bundled iPhone frame)
#   --out DIR        Output directory (default: alongside each input)
#   --suffix STR     Appended to the basename (default: -framed)
#   --native         Keep the frame at its own pixel size and downscale screenshots to fit.
#                    Default upscales the frame so the screen area matches the screenshot width,
#                    which keeps UI text crisp.
#   --pad PX         How far the screenshot extends under the bezel (default: 5). Lets the
#                    frame's own anti-aliased edge define the boundary instead of a hard mask.
#   --force          Overwrite existing outputs.
#
# Requires ImageMagick 7 (`magick`).

set -euo pipefail
setopt null_glob

SCRIPT_DIR="${0:A:h}"
FRAME="$SCRIPT_DIR/../assets/iphone-black.png"
OUT=""
SUFFIX="-framed"
NATIVE=0
PAD=5
FORCE=0
typeset -a INPUTS

while (( $# )); do
  case "$1" in
    --frame)  FRAME="$2"; shift 2;;
    --out)    OUT="$2"; shift 2;;
    --suffix) SUFFIX="$2"; shift 2;;
    --native) NATIVE=1; shift;;
    --pad)    PAD="$2"; shift 2;;
    --force)  FORCE=1; shift;;
    -h|--help) sed -n '2,16p' "$0"; exit 0;;
    -*) echo "unknown option: $1" >&2; exit 2;;
    *)  INPUTS+=("$1"); shift;;
  esac
done

command -v magick >/dev/null || { echo "ImageMagick 7 (magick) not found. brew install imagemagick" >&2; exit 1; }
[[ -f "$FRAME" ]] || { echo "frame not found: $FRAME" >&2; exit 1; }
(( ${#INPUTS} )) || { echo "no input images given" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- 1. Find the screen cutout in the frame -------------------------------------------
# Alpha → binary opaque mask. Flood-fill from the top-left corner so the region OUTSIDE the
# phone becomes "opaque" too; what remains transparent is the screen (plus any stray pixels).
magick "$FRAME" -alpha extract -threshold 0.5% "$WORK/opaque.png"
magick "$WORK/opaque.png" -fill white -draw "color 0,0 floodfill" "$WORK/filled.png"
# Screen = still-black after flood fill. Drop tiny islands (anti-aliasing specks) by keeping
# only components ≥500px, otherwise a lone transparent pixel on the bezel becomes a blob.
magick "$WORK/filled.png" -negate \
  -define connected-components:area-threshold=500 \
  -define connected-components:mean-color=true \
  -connected-components 8 -threshold 50% "$WORK/screen.png"
# Outside-the-body region, for the leak check later.
magick "$WORK/opaque.png" -negate "$WORK/filled.png" -compose Multiply -composite "$WORK/outside.png"

read SW SH SX SY <<<"$(magick "$WORK/screen.png" -format "%@" info: | sed -E 's/x|\+/ /g')"
(( SW > 0 && SH > 0 )) || { echo "could not find a transparent screen cutout in $FRAME" >&2; exit 1; }
FW=$(magick "$FRAME" -format "%w" info:)
echo "frame: $FRAME (${FW}px wide), screen cutout: ${SW}x${SH} at +${SX}+${SY}"

made=0
for f in "${INPUTS[@]}"; do
  [[ -f "$f" ]] || { echo "skip (not a file): $f" >&2; continue; }
  base="${f:t:r}"
  [[ "$f:A" == "$FRAME:A" ]] && continue
  [[ "$base" == *"$SUFFIX" ]] && continue
  dir="${OUT:-${f:h}}"; mkdir -p "$dir"
  out="$dir/$base$SUFFIX.png"
  if [[ -f "$out" && $FORCE -eq 0 ]]; then echo "exists, skipping: $out"; continue; fi

  IW=$(magick "$f" -format "%w" info:)
  if (( NATIVE )); then SCALE=1; else SCALE=$(magick -format "%[fx:$IW/$SW]" xc: info:); fi
  PCT=$(magick -format "%[fx:$SCALE*100]" xc: info:)

  # Scaled frame, mask and geometry for this input size.
  magick "$FRAME" -filter Lanczos -resize "${PCT}%" "$WORK/frame_s.png"
  magick "$WORK/screen.png" -morphology Dilate "Disk:$PAD" -resize "${PCT}%" "$WORK/mask_s.png"
  magick "$WORK/outside.png" -resize "${PCT}%" -threshold 99% "$WORK/outside_s.png"
  read TW TH TX TY <<<"$(magick "$WORK/screen.png" -resize "${PCT}%" -threshold 50% -format "%@" info: | sed -E 's/x|\+/ /g')"

  # Screenshot: cover-fit to the cutout (center crop if the aspect differs), placed at the cutout
  # offset, clipped with the padded mask, then the frame composited over the top.
  magick \( "$WORK/frame_s.png" -alpha transparent \) \
    \( "$f" -resize "${TW}x${TH}^" -gravity center -extent "${TW}x${TH}" \) \
    -gravity NorthWest -geometry "+${TX}+${TY}" -composite \
    "$WORK/mask_s.png" -alpha off -compose CopyOpacity -composite \
    "$WORK/frame_s.png" -compose Over -composite -strip "$out"

  # Leak check: any opaque output pixel outside the body that the frame itself didn't put there.
  leak=$(magick \( "$out" -alpha extract -threshold 0.5% \) \
    \( "$WORK/frame_s.png" -alpha extract -threshold 0.5% -negate \) -compose Multiply -composite \
    "$WORK/outside_s.png" -compose Multiply -composite -format '%[fx:round(mean*w*h)]' info:)
  OW=$(magick "$out" -format "%wx%h" info:)
  echo "made $out ($OW, leak=$leak)"
  (( leak == 0 )) || echo "  WARNING: $leak screenshot pixels landed outside the phone body" >&2
  made=$((made+1))
done
echo "$made image(s) framed"

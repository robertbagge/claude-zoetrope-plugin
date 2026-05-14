---
name: zoetrope-convert-image
description: Resize a still image or convert between PNG/JPEG/WebP/GIF using the zoetrope CLI. Use when the user wants to change an image's format (png/jpg/webp), resize an image to a specific width (aspect-preserved) or exact W×H (stretched), or batch-convert several images at once.
argument-hint: "[input-path]"
---

# zoetrope-convert-image

Thin wrapper around the `zoetrope` CLI for still-image → still-image conversion and resize. Your job is to turn the user's ask into the right `zoetrope` invocation, run it, and report the resulting file.

The CLI accepts these still-image inputs: `png`, `jpg`, `jpeg`, `webp`. Output formats: `png`, `jpg`, `webp`, or single-frame `gif`. WebP output for image input is still (not animated).

## Prerequisites

Before the first invocation, run `${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/verify-cli.sh`. If it exits non-zero, surface its stderr to the user verbatim and stop.

Do not attempt to install `zoetrope` yourself. Do not synthesise a fake output file.

## Picking flags from the ask

| User says | Flag(s) |
|---|---|
| "Convert to WebP" | `-F webp` |
| "Convert to PNG" | `-F png` |
| "Convert to JPEG" | `-F jpg` |
| "Convert to GIF" (single frame) | `-F gif` |
| "Resize to 432 wide, keep aspect" | `--width 432` |
| "Exact 432×432, stretch ok" | `--width 432 --height 432` |
| "Specific height, keep aspect" | `--height 600` (preserves aspect from input) |
| "Custom output name" | `-o photo.webp` (single input only) |
| "Several images at once" | pass multiple inputs |
| "Collect into a folder" | `--output-dir ./resized/` (batch mode) |
| "Overwrite existing file" | `--force` |

If the user gives no format and no resize, ask what they want — `zoetrope` is overkill for a no-op copy.

## Invocation rules

- Quote any path containing spaces or special characters.
- `-o <path>` is **single-input only**. With multiple inputs, use `--output-dir <dir>` instead.
- `--width` alone preserves aspect ratio. `--width` plus `--height` forces an exact box (stretch).
- `--height` alone also preserves aspect (computed from input).
- Output extension is inferred from `-F` (or from `-o`'s extension if provided).
- Only add `--force` when the user explicitly says "overwrite".

## Reference — image-relevant flags only

| Flag | Purpose |
|---|---|
| `-F gif\|webp\|png\|jpg` | Output format. For images: all four are still-image outputs (gif = single frame). |
| `--width N` | Output width in pixels. Alone, preserves aspect. |
| `--height N` | Output height in pixels. With `--width`, exact box (stretch). |
| `-o <path>` | Output file path (single input only). |
| `--output-dir <dir>` | Output directory (batch mode; created if missing). |
| `-f, --force` | Overwrite without prompting. |

Video-only flags (`--fps`, `--speed`, `--playback`, `--start`, `--end`, `--duration`, `--for`, `-q`, `--max-size`) do not apply to still images. Don't pass them.

## Worked examples

Every invocation goes through the wrapper at `${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh`. It is a thin pass-through (`exec zoetrope "$@"`), so the argument surface is identical to the CLI.

```sh
# PNG → WebP, aspect-preserved at 432 wide
${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh photo.png --width 432 -F webp

# Exact 432×432 (stretch)
${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh photo.png --width 432 --height 432

# JPEG → PNG, resized
${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh shot.jpg --width 800 -F png

# WebP → JPEG, resized
${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh shot.webp --width 320 -F jpg

# Custom output filename
${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh photo.png --width 600 -o thumb.webp

# Batch — collect into ./resized/
${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh *.png --width 600 -F webp --output-dir ./resized/

# Format-only conversion (no resize)
${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/convert-image.sh photo.jpg -F webp
```

## After running

Run `ls -lh <output-path>` to confirm the file exists and report its size to the user. For batch mode, list every file produced. If the CLI exited non-zero, surface the stderr verbatim.

## Hard rules

- **Don't invent flags.** The full surface is whatever `${CLAUDE_PLUGIN_ROOT}/skills/zoetrope-convert-image/scripts/help.sh` prints. If the user asks for something not in the table above, say so.
- **Image inputs don't accept video flags.** If the user asks for trim/speed/playback/platform-preset on a still image, push back — those are concepts for video. If the input is actually a video they want animated, hand off to `zoetrope-create-gif`.
- **GIF output for a still image is single-frame.** If the user wants an animated GIF, the input must be a video — use `zoetrope-create-gif` instead.
- **Never fake output.** If `zoetrope` isn't installed or the conversion fails, say so. Don't pretend to have produced a file.

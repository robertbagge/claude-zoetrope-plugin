---
name: zoetrope-create-gif
description: Convert a screen recording (mov/mp4/webm/mkv/avi) to an animated GIF or WebP using the zoetrope CLI. Use when the user wants to turn a video into a shareable GIF, optimise a recording for Slack/GitHub/Discord/Twitter/email, trim or speed up a clip, change playback (reverse/boomerang), or batch-convert multiple recordings.
argument-hint: "[input-path]"
---

# zoetrope-create-gif

Thin wrapper around the `zoetrope` CLI for video → animated output. Your job is to turn the user's natural-language ask into the right invocation of `${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh` (a pass-through to `zoetrope`), run it, and report the resulting file size.

The CLI accepts these video inputs: `mov`, `mp4`, `webm`, `mkv`, `avi`. Output is GIF by default, or WebP if the user wants a smaller file (`-F webp` is 2–5× smaller than GIF and still animated for video input).

## Prerequisites

Before the first invocation, run `${CLAUDE_PLUGIN_ROOT}/scripts/verify-cli.sh`. If it exits non-zero, surface its stderr to the user verbatim and stop.

Do not synthesise a fake output file.

## Picking flags from the ask

Translate the user's request into flags using this table. Combine flags freely — they compose.

| User says | Flag(s) |
|---|---|
| "Make this a GIF" | (default — no `-F` needed) |
| "WebP, smaller" | `-F webp` |
| "For Slack" / "for chat" | `--for slack` (≤5MB, 480px, 10fps) |
| "For GitHub" / "for a PR" | `--for github` (≤10MB, 960px, 12fps) |
| "For Discord" | `--for discord` (≤8MB, 640px, 12fps) |
| "For Twitter/X" | `--for twitter` (≤5MB, 480px, 10fps) |
| "For email" / "inline" | `--for email` (≤500KB, 320px, 8fps) |
| "Under 5MB" / specific cap | `--max-size 5mb` (or `500kb`, decimal units) |
| "Higher quality" | `-q high` (1440px, 15fps) |
| "Best quality" / "demo reel" | `-q ultra` (2048px, 24fps) |
| "Smaller / lower quality" | `-q low` (480px, 8fps) |
| "Specific width" | `--width 640` (overrides preset) |
| "Specific fps" | `--fps 20` (overrides preset) |
| "Exact W×H, stretch ok" | `--width W --height H` |
| "Just from 5s to 12s" | `--start 5s --end 12s` |
| "First 10 seconds" | `--end 10s` |
| "Start at 1:30, run 10s" | `--start 1:30 --duration 10s` |
| "2× speed" / "slow motion" | `--speed 2` / `--speed 0.5` |
| "Play it backwards" | `--playback reverse` |
| "Ping-pong / boomerang" | `--playback boomerang` |
| "Custom output name" | `-o clip.gif` (single input only) |
| "Several files at once" | pass multiple inputs |
| "Collect them in a folder" | `--output-dir ./gifs/` (batch mode) |
| "Overwrite the existing file" | `--force` |

Default quality is `medium` (960px, 12fps) — fine for GitHub PRs and docs.

## Invocation rules

- Quote any path containing spaces or special characters.
- `-o <path>` is **single-input only**. With multiple inputs, use `--output-dir <dir>` instead.
- `--end` and `--duration` are mutually exclusive. Pick one.
- `--for <platform>` locks format to GIF and enforces a size cap. Explicit `--fps`, `--width`, or `--max-size` still override the preset values when set.
- Only add `--force` when the user explicitly says "overwrite" or has acknowledged an existing file.
- Don't combine still-image flags (none exist that would conflict here, but never invent flags — see the Hard rules below for the canonical full-surface reference).

## Reference

**Quality presets:**

| Preset | Width | FPS | Use |
|---|---|---|---|
| `low` | 480px | 8 | Slack, quick shares |
| `medium` (default) | 960px | 12 | GitHub PRs, docs |
| `high` | 1440px | 15 | Presentations, LinkedIn |
| `ultra` | 2048px | 24 | Demo reels, high-fidelity |

**Platform presets** (`--for <name>`):

| Name | Size cap | Width | FPS |
|---|---|---|---|
| `slack` | 5 MB | 480px | 10 |
| `github` | 10 MB | 960px | 12 |
| `discord` | 8 MB | 640px | 12 |
| `twitter` | 5 MB | 480px | 10 |
| `email` | 500 KB | 320px | 8 |

**Time formats:** `5s`, `1:30`, `1:30:45`.

**Size formats:** `5mb`, `500kb`. Decimal units (1mb = 1,000,000 bytes).

**Output formats** (`-F <fmt>`): `gif` (default), `webp` (animated for video input).

## Worked examples

Every invocation goes through the wrapper at `${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh`. It is a thin pass-through (`exec zoetrope "$@"`), so the argument surface is identical to the CLI.

```sh
# Default: medium quality GIF next to input
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov

# Slack-ready, auto-fit
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov --for slack

# GitHub PR clip, trimmed
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov --for github --start 2s --duration 8s

# Smaller animated WebP
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov -F webp -q high

# Demo reel
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov -q ultra -F webp

# Boomerang under 2MB
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov --playback boomerang --max-size 2mb

# 2× speedup, custom width
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov --speed 2 --width 720

# Reverse, custom output filename
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh demo.mov --playback reverse -o demo-reverse.gif

# Batch — collect into ./gifs/
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh *.mov --output-dir ./gifs/

# Batch + platform preset
${CLAUDE_SKILL_DIR}/scripts/generate-gif.sh *.mov --for slack --output-dir ./slack/
```

## After running

Run `ls -lh <output-path>` to confirm the file exists and report its size to the user. For batch mode, list every file produced. If the CLI exited non-zero, surface the stderr verbatim — don't paraphrase.

## Hard rules

- **Don't invent flags.** The full surface is whatever `${CLAUDE_PLUGIN_ROOT}/scripts/help.sh` prints. If the user asks for something not in the table above, say so explicitly rather than guessing.
- **Don't use video-only flags on still images.** `--fps`, `--speed`, `--playback`, `--start`/`--end`/`--duration`, `--for` only apply to video inputs. For still images (png/jpg/jpeg/webp) hand off to the `zoetrope-convert-image` skill.
- **One-shot tool.** Each invocation produces output or fails. Don't poll, don't background it.
- **Never fake output.** If `zoetrope` isn't installed or the conversion fails, say so. Don't pretend to have produced a file.

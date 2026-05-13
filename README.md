# Zoetrope

> **zoetrope** */ˈzoʊ.ɪ.troʊp/* — A 19th-century optical device consisting of a spinning cylinder with slits and a strip of sequential images inside. When spun, the images blur together into the illusion of motion. Invented in 1834 by William George Horner, the zoetrope was one of the first forms of animation — and arguably, the world's first gif.

---

A Claude Code plugin that wraps the [`zoetrope`](https://github.com/robertbagge/zoetrope) CLI. Two infra-layer skills teach the agent how to turn screen recordings into high-quality GIF/WebP and how to resize/convert still images — without you having to remember the flag surface.

## Installation

```bash
claude plugin marketplace add robertbagge/claude-registry
claude plugin install zoetrope@claude-registry
```

### Prerequisite: install the `zoetrope` CLI

The plugin invokes `zoetrope` directly, so the binary must be on PATH.

```bash
# Recommended (macOS) — pulls ffmpeg as a dependency
brew install robertbagge/tap/zoetrope

# From source (requires ffmpeg installed separately)
cargo install --path crates/zoetrope-cli
```

If the binary is missing when a skill runs, the skill will stop cleanly and print these install instructions rather than guessing or faking output.

## `/zoetrope:zoetrope-create-gif` — video → animated GIF/WebP

Wraps `zoetrope` for video inputs (`mov`, `mp4`, `webm`, `mkv`, `avi`). The skill knows the full flag surface: quality presets (`low`/`medium`/`high`/`ultra`), platform presets (`--for slack|github|discord|twitter|email`), trim (`--start`, `--end`, `--duration`), speed (`--speed 2`, `--speed 0.5`), playback modes (`--playback reverse|boomerang`), batch (`--output-dir`), and size targeting (`--max-size 500kb`).

```
/zoetrope:zoetrope-create-gif demo.mov          # ask for slack-ready, ultra quality, trimmed, etc.
```

Examples of asks the skill handles:

- "Make this a Slack-friendly GIF" → `zoetrope demo.mov --for slack`
- "Trim from 2s to 10s, GitHub PR quality" → `zoetrope demo.mov --for github --start 2s --end 10s`
- "Boomerang loop under 2MB" → `zoetrope demo.mov --playback boomerang --max-size 2mb`
- "Convert all the mov files in this folder" → `zoetrope *.mov --output-dir ./gifs/`

## `/zoetrope:zoetrope-convert-image` — still image resize / format conversion

Wraps `zoetrope` for still-image inputs (`png`, `jpg`, `jpeg`, `webp`) and outputs (`png`, `jpg`, `webp`, single-frame `gif`). Handles aspect-preserving resize (`--width` alone), exact-box stretch (`--width` + `--height`), format-only conversion, and batch.

```
/zoetrope:zoetrope-convert-image photo.png      # ask to resize, convert format, etc.
```

Examples of asks the skill handles:

- "Convert this PNG to a 432px WebP" → `zoetrope photo.png --width 432 -F webp`
- "Resize to exactly 432×432" → `zoetrope photo.png --width 432 --height 432`
- "All these JPEGs as PNGs, 800 wide" → `zoetrope *.jpg --width 800 -F png --output-dir ./out/`

## When the agent uses which

The two skills are split by **input type**, not by output:

- Video input → `zoetrope-create-gif`
- Still image input → `zoetrope-convert-image`

The skill descriptions trigger correctly off the natural-language ask in most cases. If you're invoking explicitly, pick by what the input file is.

## Optional: auto-check the binary with a hook

The plugin assumes `zoetrope` is on PATH and lets the OS surface the failure when it isn't. If you'd prefer a hooked check that prints install instructions before the skill runs, add a `PreToolUse` hook that matches the `Skill` tool with skill names `zoetrope:*` and runs `command -v zoetrope`. Not shipped in v0.1 — the failure mode is already clear and a hook adds latency on every invocation.

## Files

```
claude-zoetrope-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── zoetrope-create-gif/
│   │   └── SKILL.md
│   └── zoetrope-convert-image/
│       └── SKILL.md
├── README.md
├── LICENSE
├── CHANGELOG.md
├── release-please-config.json
└── .release-please-manifest.json
```

## Why "Zoetrope"

Borrowed from the upstream CLI: the original optical animation device, and arguably the world's first GIF. The plugin is the thinnest possible wrapper — its job is to make the CLI legible to an agent, not to add behaviour.

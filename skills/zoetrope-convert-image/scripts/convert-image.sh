#!/usr/bin/env bash
set -euo pipefail

# This script is used to generate a GIF from a series of images using the zoetrope command.
exec zoetrope "$@"

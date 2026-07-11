#!/bin/bash
# claude CLI pointed at z.ai's Anthropic-compatible endpoint (GLM coding plan).
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$(cat ~/.config/ringer/zai-token)"   # 0600 perms
exec claude "$@"

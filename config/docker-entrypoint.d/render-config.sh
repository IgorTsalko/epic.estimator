#!/bin/sh
# Runs automatically before nginx starts (nginx image convention: any
# executable *.sh in /docker-entrypoint.d/ is sourced by docker-entrypoint.sh).
# Renders index.html from the read-only template baked into the image into
# the writable html volume, substituting __NAME__ placeholders with the
# pod's env vars (API_KEY, MODEL, MAX_TOKENS from the eestimator-api-token
# secret). Root filesystem is read-only, so the template lives outside the
# nginx html root and the rendered file is written to a mounted emptyDir.
set -eu

TEMPLATE="/usr/share/nginx/html-template/index.html"
TARGET="/usr/share/nginx/html/index.html"

escape() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

cp "$TEMPLATE" "$TARGET"

sed -i \
    -e "s/__API_KEY__/$(escape "${API_KEY:-}")/g" \
    -e "s/__MODEL__/$(escape "${MODEL:-}")/g" \
    -e "s/__MAX_TOKENS__/$(escape "${MAX_TOKENS:-}")/g" \
    "$TARGET"

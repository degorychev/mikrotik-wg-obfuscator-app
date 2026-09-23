#!/usr/bin/env sh
set -eu

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_REPOSITORY_OWNER:?GITHUB_REPOSITORY_OWNER is required}"

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/_site}"
REPO_NAME=${GITHUB_REPOSITORY#*/}
OWNER_LOWER=$(printf '%s' "$GITHUB_REPOSITORY_OWNER" | tr '[:upper:]' '[:lower:]')
REPO_LOWER=$(printf '%s' "$REPO_NAME" | tr '[:upper:]' '[:lower:]')
PROJECT_PAGE="https://${GITHUB_REPOSITORY_OWNER}.github.io/${REPO_NAME}"
IMAGE="ghcr.io/${OWNER_LOWER}/${REPO_LOWER}:latest"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/routeros"

sed \
    -e "s|__PROJECT_PAGE__|$PROJECT_PAGE|g" \
    -e "s|__IMAGE__|$IMAGE|g" \
    "$ROOT_DIR/catalog/app-store.template.yml" > "$OUTPUT_DIR/app-store.yml"

sed \
    -e "s|__PROJECT_PAGE__|$PROJECT_PAGE|g" \
    -e "s|__CATALOG_URL__|$PROJECT_PAGE/app-store.yml|g" \
    -e "s|__REPOSITORY_URL__|https://github.com/$GITHUB_REPOSITORY|g" \
    "$ROOT_DIR/site/index.template.html" > "$OUTPUT_DIR/index.html"

cp "$ROOT_DIR/site/icon.svg" "$OUTPUT_DIR/icon.svg"
cp "$ROOT_DIR/routeros/"*.rsc "$OUTPUT_DIR/routeros/"
touch "$OUTPUT_DIR/.nojekyll"

printf 'Rendered %s with image %s\n' "$PROJECT_PAGE" "$IMAGE"


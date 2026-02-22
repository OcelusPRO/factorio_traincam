#!/bin/bash
set -e

SRC_DIR="/src_mod"
DIST_DIR="/dist_mod"
TEMP_DIR="/tmp/factorio_build"

MOD_NAME=$(jq -r '.name' "$SRC_DIR/ressources/info.json")
MOD_VERSION=$(jq -r '.version' "$SRC_DIR/ressources/info.json")
BUILD_NAME="${MOD_NAME}_${MOD_VERSION}"

echo "🔨 Building Factorio mod: $BUILD_NAME"

mkdir -p "$TEMP_DIR/$BUILD_NAME"

cp -r "$SRC_DIR/ressources/." "$TEMP_DIR/$BUILD_NAME/"
cp -r "$SRC_DIR/src/." "$TEMP_DIR/$BUILD_NAME/"

cd "$TEMP_DIR"
zip -r "$DIST_DIR/$BUILD_NAME.zip" "$BUILD_NAME"

echo "✅ Succès ! $BUILD_NAME.zip généré."
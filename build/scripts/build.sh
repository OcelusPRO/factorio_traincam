#!/bin/bash

RES_DIR="ressources"
SRC_DIR="src"
BUILD_ROOT="build"
BUILD_TEMP="$BUILD_ROOT/temp"
INFO_FILE="$RES_DIR/info.json"

MOD_NAME=$(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$INFO_FILE" | xargs)
MOD_VERSION=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$INFO_FILE" | xargs)

BUILD_NAME="${MOD_NAME}_${MOD_VERSION}"
TARGET_PATH="$BUILD_TEMP/$BUILD_NAME"

rm -rf "$BUILD_TEMP"
mkdir -p "$TARGET_PATH"
mkdir -p "$BUILD_ROOT/dist"

[ -d "$RES_DIR" ] && cp -r "$RES_DIR/." "$TARGET_PATH/"
[ -d "$SRC_DIR" ] && cp -r "$SRC_DIR/." "$TARGET_PATH/"

echo "Compression du mod : $BUILD_NAME"

ABS_PATH=$(pwd)

PATH_TO_ZIP_DIR="$ABS_PATH/$BUILD_TEMP/$BUILD_NAME"
DEST_ZIP_FILE="$ABS_PATH/$BUILD_ROOT/dist/$BUILD_NAME.zip"

if command -v powershell.exe &>/dev/null; then
    WIN_SRC=$(echo "$PATH_TO_ZIP_DIR" | sed 's/^\/mnt\/\([a-z]\)\//\1:\\/;s/\//\\/g')
    WIN_DEST=$(echo "$DEST_ZIP_FILE" | sed 's/^\/mnt\/\([a-z]\)\//\1:\\/;s/\//\\/g')

    WIN_SRC=$(echo "$WIN_SRC" | sed 's/^\/\([a-z]\)\//\1:\\/')
    WIN_DEST=$(echo "$WIN_DEST" | sed 's/^\/\([a-z]\)\//\1:\\/')

    rm -f "$DEST_ZIP_FILE"

    powershell.exe -Command "Compress-Archive -Path '$WIN_SRC' -DestinationPath '$WIN_DEST' -Force"
else
    (cd "$BUILD_TEMP" && zip -r "../dist/$BUILD_NAME.zip" "$BUILD_NAME")
fi

echo "Succès ! Le mod est prêt dans build/dist/"
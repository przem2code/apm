#!/usr/bin/env bash
# Remove the local apm cache to force fresh package resolution.

CACHE_DIR="${APM_CACHE_DIR:-}"

echo "clean-cache: removing $CACHE_DIR"
rm -rf "$CACHE_DIR/"*
echo "clean-cache: done"

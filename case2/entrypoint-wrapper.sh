#!/bin/bash
set -e

# DBT requirements'ı kur (eğer kurulu değilse)
if ! command -v dbt &> /dev/null; then
    echo "Installing DBT requirements..."
    pip install --no-cache-dir -r /requirements.txt
fi

# Orijinal entrypoint'i çalıştır
exec /entrypoint "$@"


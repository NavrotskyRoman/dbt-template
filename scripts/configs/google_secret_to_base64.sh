#!/usr/bin/env bash
# Читает JSON ключа GCP из файла, выводит одну строку base64 для .env или Secret Manager.
# Использование: ./scripts/configs/google_secret_to_base64.sh
# Затем указать путь к файлу с ключом и нажать Enter.

set -e
if [[ -n "$1" ]]; then
  input="$1"
else
  echo "Укажите путь к файлу с ключом и нажмите Enter:" >&2
  read -r input
fi
json=$(cat "$input")
# Одна строка base64 без переносов (macOS: base64 без -w 0)
if base64 -w 0 < /dev/null 2>/dev/null; then
  encoded=$(printf '%s' "$json" | base64 -w 0)
else
  encoded=$(printf '%s' "$json" | base64 | tr -d '\n')
fi
printf 'DBT_ENV_SECRET_BIGQUERY_KEYFILE_BASE64=%s\n' "$encoded"
echo "" >&2
echo "Скопируйте результат выше и вставьте в .env (Ctrl+C, затем Ctrl+V)." >&2

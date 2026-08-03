#!/usr/bin/env bash
# Ping IndexNow whenever pages on cresca.agency are added, updated or removed.
# Submitted URLs are shared with every participating engine (Bing, Yandex, Seznam, Naver).
#
# Usage:
#   ./indexnow-submit.sh                                  # submits the homepage
#   ./indexnow-submit.sh https://cresca.agency/new-page/  # submits specific URLs
#
# Only submit URLs that actually changed. Do not re-submit unchanged pages.

set -euo pipefail

KEY="da188b770da4341e75141ff00b9cb7cc"
HOST="cresca.agency"
KEY_LOCATION="https://cresca.agency/${KEY}.txt"

if [ "$#" -gt 0 ]; then
  URLS=("$@")
else
  URLS=("https://cresca.agency/")
fi

URL_JSON=$(printf '"%s",' "${URLS[@]}")
URL_JSON="[${URL_JSON%,}]"

PAYLOAD=$(cat <<EOF
{
  "host": "${HOST}",
  "key": "${KEY}",
  "keyLocation": "${KEY_LOCATION}",
  "urlList": ${URL_JSON}
}
EOF
)

echo "Submitting ${#URLS[@]} URL(s) to IndexNow..."
printf '%s\n' "${URLS[@]}" | sed 's/^/  - /'

CODE=$(curl -sS -o /tmp/indexnow-body.txt -w '%{http_code}' \
  -X POST "https://api.indexnow.org/IndexNow" \
  -H "Content-Type: application/json; charset=utf-8" \
  --data "${PAYLOAD}")

echo "HTTP ${CODE}"
case "${CODE}" in
  200) echo "OK — URLs submitted successfully." ;;
  202) echo "Accepted — received, key validation pending." ;;
  400) echo "Bad request — invalid format." ;;
  403) echo "Forbidden — key invalid or key file not reachable at ${KEY_LOCATION}" ;;
  422) echo "Unprocessable — URLs do not belong to ${HOST}, or key schema mismatch." ;;
  429) echo "Rate limited — too many requests." ;;
  *)   echo "Unexpected response."; cat /tmp/indexnow-body.txt ;;
esac

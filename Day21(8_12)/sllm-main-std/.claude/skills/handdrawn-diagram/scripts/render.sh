#!/usr/bin/env bash
# render.sh — 손그림 다이어그램 HTML 을 PNG 로 굽는다.
#
#   render.sh <scene.js> <out.png> <width> <height> [seed]
#
# scene.js 는 initSketch() 로 시작하는 그리기 코드 조각이다. 이 스크립트가
# rough.js · sketch.js · 손글씨 폰트를 인라인한 임시 HTML 로 감싼 뒤,
# headless Chrome 으로 스크린샷을 뜬다.
#
# 폰트를 data URI 로 박아 넣는 이유: --headless 크롬은 로컬 file:// 폰트를
# 조용히 무시하는 경우가 있고, 그러면 한글이 시스템 고딕으로 떨어져
# 손그림 느낌이 통째로 날아간다. base64 로 넣으면 그 사고가 없다.

set -euo pipefail

SCENE="${1:?scene.js 경로가 필요합니다}"
OUT="${2:?출력 png 경로가 필요합니다}"
W="${3:-1000}"
H="${4:-700}"
SEED="${5:-42}"

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS="$SKILL_DIR/assets"

CHROME="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
if [ ! -x "$CHROME" ]; then
  echo "!! Chrome 을 찾지 못했습니다: $CHROME" >&2
  echo "   CHROME_BIN 환경변수로 경로를 지정하세요." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

b64() { base64 -i "$1" | tr -d '\n'; }

PEN_B64="$(b64 "$ASSETS/fonts/NanumPenScript-Regular.ttf")"
GAEGU_B64="$(b64 "$ASSETS/fonts/Gaegu-Regular.ttf")"
GAEGUB_B64="$(b64 "$ASSETS/fonts/Gaegu-Bold.ttf")"

HTML="$TMP/page.html"
{
  echo '<!doctype html><html><head><meta charset="utf-8"><style>'
  echo "@font-face{font-family:'PenScript';src:url(data:font/ttf;base64,${PEN_B64}) format('truetype');}"
  echo "@font-face{font-family:'Gaegu';src:url(data:font/ttf;base64,${GAEGU_B64}) format('truetype');}"
  echo "@font-face{font-family:'GaeguBold';src:url(data:font/ttf;base64,${GAEGUB_B64}) format('truetype');}"
  echo 'html,body{margin:0;padding:0;background:#fff;}canvas{display:block;}'
  echo '</style><script>'
  cat "$ASSETS/rough.js"
  echo '</script><script>'
  cat "$ASSETS/sketch.js"
  echo '</script></head><body>'
  echo "<canvas id=\"c\"></canvas>"
  echo '<script>'
  echo "const __W=${W},__H=${H},__SEED=${SEED};"
  echo 'async function main(){'
  echo "  await document.fonts.load('40px \"PenScript\"','가');"
  echo "  await document.fonts.load('40px \"Gaegu\"','가');"
  echo "  await document.fonts.load('40px \"GaeguBold\"','가');"
  echo '  await document.fonts.ready;'
  cat "$SCENE"
  echo '  document.title="ready";'
  echo '}'
  echo 'main();'
  echo '</script></body></html>'
} > "$HTML"

# --headless=old 를 쓴다. 최신 Chrome(151)의 --headless=new 는 이 환경에서
# 스크린샷 명령이 끝나지 않고 매달린다. old 헤드리스는 즉시 파일을 뱉는다.
# --screenshot 은 상대경로를 CWD 기준으로 잡으므로 절대경로로 바꿔 넘긴다.
case "$OUT" in /*) ABS_OUT="$OUT" ;; *) ABS_OUT="$PWD/$OUT" ;; esac

"$CHROME" \
  --headless=old \
  --disable-gpu \
  --no-first-run \
  --no-default-browser-check \
  --hide-scrollbars \
  --force-device-scale-factor=2 \
  --virtual-time-budget=5000 \
  --window-size="${W},${H}" \
  --screenshot="$ABS_OUT" \
  "file://$HTML" >/dev/null 2>&1 || true

OUT="$ABS_OUT"

if [ ! -s "$OUT" ]; then
  echo "!! 스크린샷 실패: $OUT 이 비어 있습니다" >&2
  exit 1
fi
echo "OK  $OUT  ($(cd "$(dirname "$OUT")" && du -h "$(basename "$OUT")" | cut -f1))"

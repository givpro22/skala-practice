#!/usr/bin/env bash
#
# 원고 하드 게이트 — 사용자가 직접 반려한 항목만 기계로 센다.
#
# report-writer 가 원고를 저장하기 전에, human-voice-qa 가 축 0에서 같은 스크립트를
# 돌린다. 두 파일에 grep 을 복제해 두면 한쪽만 고쳐져서 오탐이 난다. 실제로 코드
# 블록 안의 따옴표를 문체로 세는 버그를 양쪽에서 따로 고쳐야 했다.
#
# 사용법: bash .claude/skills/template2-report-writing/scripts/voice-gate.sh [원고경로]
# 종료:   0 = 전부 통과, 1 = 반려 항목 있음, 2 = 원고를 찾을 수 없음
#
set -uo pipefail

M="${1:-_workspace/03_manuscript.md}"
[ -f "$M" ] || { echo "원고를 찾을 수 없습니다: $M" >&2; exit 2; }

FAIL=0

# 코드 블록을 빈 줄로 지운 본문. 줄 번호는 원본 그대로 유지된다.
# event.get("userId") 의 따옴표는 Java 문법이지 문체가 아니다.
BODY=$(awk '/^```/{f=!f; print ""; next} f{print ""; next} {print}' "$M")

n_of() { [ -z "$1" ] && echo 0 || printf '%s\n' "$1" | wc -l | tr -d ' '; }

check() {  # check <게이트 이름> <걸린 줄들>
  local name="$1" out="$2" n
  n=$(n_of "$out")
  if [ "$n" -eq 0 ]; then
    printf '  통과   %s\n' "$name"
  else
    printf '  반려   %s — %d건\n' "$name" "$n"
    printf '%s\n' "$out" | sed 's/^/           /'
    FAIL=1
  fi
}

echo "하드 게이트: $M"
echo

# 1. 큰따옴표 — 본문 한복판. `>` 인용문 블록 안은 통과다.
check "큰따옴표" \
  "$(printf '%s\n' "$BODY" | grep -n '"' | grep -v '^[0-9]*:> ' || true)"

# 2. 중간점 — 나열은 쉼표로.
check "중간점" \
  "$(printf '%s\n' "$BODY" | grep -n '·' || true)"

# 3. 이모지 — grep -P 는 macOS 기본 grep 에 없어서 조용히 통과해 버린다. perl 로 센다.
#    화살표(→ U+2192, ↔ U+2194)는 원본 템플릿2가 쓰는 부호라 범위에서 뺀다.
check "이모지" \
  "$(printf '%s\n' "$BODY" | perl -CSD -ne 'print "$.:$_" if /[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}\x{FE0F}]/' || true)"

# 4. 물음표 — 위치를 가리지 않는다. 줄 끝이든 문장 한복판이든 전부 걸린다.
#    처음에는 답 없이 끝나는 의문형만 막았는데, 사용자가 물음표 자체가 어색하다고
#    다시 반려했다. 자문자답도 쓰지 않는다.
check "물음표" \
  "$(printf '%s\n' "$BODY" | grep -n '?' || true)"

# 5. 의문형 제목 — 물음표를 안 달아도 어미가 의문형이면 걸린다.
check "의문형 제목" \
  "$(grep -nE '^#+ .*(까|나요|는가|인가)\??[[:space:]]*$' "$M" || true)"

# 6. 그림 뒤 캡션 — 원본 템플릿2에는 그림 캡션이 하나도 없다.
check "그림 뒤 캡션" \
  "$(awk '{L[NR]=$0} END{for(i=2;i<=NR;i++) if(L[i] ~ /^> / && L[i-1] ~ /^!\[/) printf "%d: %s\n", i, L[i]}' "$M")"

# 7. 글이 자기를 설명하는 문장
check "자기 해설" \
  "$(grep -nE '이 (보고서|글)는|솔직하게 적|얘기부터 하겠|정리하자면|이건 짧게' "$M" || true)"

# 8. 이름 자리표시자 — 제출자는 4반 박영서다.
check "이름 자리표시자" \
  "$(grep -n '○반\|○○○\|OOO' "$M" || true)"

# 9. 인용 블록 — 전면 금지.
#    상한 4 → 2 → 0 으로 세 번 내려왔다. 마지막 반려는 남아 있던 한 개였고,
#    그게 교수님 발언을 축자로 옮긴 것이었다. 사용자 반려 원문:
#      > 이걸 깊게 파지는 않겠지만 필요한 이유는 알겠어. 충분해요.
#    남의 말을 그대로 떠 오면 어투가 본문과 달라 그 대목만 붕 뜬다. 하물며
#    보고서를 읽는 사람이 그 말을 한 당사자다. 인용할 사실은 서술로 녹여라.
QB=$(awk '/^> /{if(!p) printf "%d: %s\n", NR, $0; p=1; next}{p=0}' "$M")
check "인용 블록" "$QB"

# 10. 인용 앞 도입 한 줄 문단 — 인용을 세워 두고 앞에서 뜸들이는 리듬.
#     출처는 앞 문단 문장 안에 넣는다.
#
#     빈 줄 유무로 판정하면 빈 줄을 지워서 빠져나갈 수 있다. 첫 실행에서 실제로 그랬다.
#     그래서 인용 바로 앞 **문단 블록**을 통째로 모아 문장 수를 센다. 한 문장이면 도입만
#     하는 줄이고, 여러 문장이면 출처가 문단 안에 녹아 있는 형태다.
check "인용 앞 도입 한 줄 문단" \
  "$(awk '{L[NR]=$0} END{
      for(i=1;i<=NR;i++){
        if(L[i] !~ /^> /) continue
        if(L[i-1] ~ /^> /) continue                      # 인용 블록 내부
        j=i-1
        while(j>=1 && L[j]=="") j--                      # 앞의 빈 줄 건너뛰기
        if(j<1) continue
        if(L[j] ~ /^[>#!|`*-]/) continue                 # 제목·그림·표·불릿이면 도입 아님
        k=j
        while(k>=1 && L[k]!="" && L[k] !~ /^[>#!|`]/) k--
        k++
        txt=""
        for(m=k;m<=j;m++) txt = txt " " L[m]
        if(gsub(/[.!?]/,"&",txt) <= 1) printf "%d: %s\n", j, L[j]
      }}' "$M")"

# 11. 예고만 하는 도입 문장 — 할 말을 하기 전에 하겠다고 알리는 군더더기.
check "예고형 도입 문장" \
  "$(grep -nE '이렇게 적혀 있습니다|다음과 같습니다|아래와 같습니다|한 가지 더 배운|여기서 제가|제가 이 절에서|정말 적고 싶은|말씀드리자면|먼저 말해 두면' "$M" || true)"

# ── 그림 안의 글씨도 같은 게이트를 받는다 ────────────────────────────────
#
# 원고에서 걷어낸 반려 문장이 그림에 그대로 살아 있던 적이 있다. 그림은 같은 문서로
# 제출되므로 읽는 사람에게는 본문과 구별되지 않는다. scene 파일의 text() 문자열만
# 골라서 본다 — 코드 자체의 따옴표는 문법이라 대상이 아니다.
D="$(dirname "$M")/diagrams"
if [ -d "$D" ]; then
  echo
  echo "그림 안 글씨: $D/*.js"

  # 한글이 들어간 문자열 리터럴은 전부 화면에 찍히는 글씨다. text() 만 보면 상자 라벨과
  # 배열로 넘긴 항목을 놓친다 — 첫 판에서 실제로 중간점 3건을 놓쳤다.
  # 따옴표는 벗기고 **내용만** 넘긴다. 그래야 JS 문자열의 구분자가 큰따옴표로 오탐되지 않는다.
  ART=$(perl -CSD -ne '
      while (/\x27([^\x27]*)\x27|"([^"]*)"/g) {
        my $s = defined($1) ? $1 : $2;
        next unless $s =~ /[\x{AC00}-\x{D7A3}]/;
        printf "%s:%d  %s\n", $ARGV, $., $s;
      }' "$D"/*.js 2>/dev/null | sed "s|$D/||")

  check "그림 안 큰따옴표" "$(printf '%s\n' "$ART" | grep '"' || true)"
  check "그림 안 물음표"   "$(printf '%s\n' "$ART" | grep '?' || true)"

  # 중간점은 한글 필터를 거치지 않는다. `ELECTRONICS · CHEMICAL` 처럼 한글 없는 라벨을
  # 놓쳤다. `·` 는 JS 문법에 없는 글자라 파일을 통째로 봐도 오탐이 없다.
  check "그림 안 중간점" \
    "$(grep -Hn '·' "$D"/*.js 2>/dev/null | sed "s|$D/||" || true)"
  check "그림 안 의문형 어미" \
    "$(printf '%s\n' "$ART" | grep -E '(까|나요|는가|인가)\??$' || true)"
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "하드 게이트 통과."
else
  echo "반려 항목이 남아 있습니다. 고치기 전에는 저장하지 않는다."
fi
exit "$FAIL"

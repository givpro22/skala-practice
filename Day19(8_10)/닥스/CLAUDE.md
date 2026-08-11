# 닥스 — SKALA Agile & MSA 개인과제

## 하네스: MSA/Agile 개인과제 보고서

**목표:** 실습 근거(강의 자료·템플릿 코드·팀 저장소)에서 출발해, 손으로 그린 듯한
다이어그램과 사람이 쓴 듯한 서술로 템플릿2 양식 보고서를 제출용 .docx까지 뽑아낸다.

**트리거:** 보고서·과제 문서 관련 요청(작성, 수정, 재실행, 그림 교체, 분량 조정,
docx 재조립)이 오면 `msa-report-orchestrator` 스킬을 사용하라.
"이 개념이 뭐야" 수준의 단순 질문은 직접 응답해도 된다.

**소재 고정값**
- 제출자: **4반 박영서** — 표지 줄에 그대로 넣는다. `○반 ○○○` 자리표시자 금지
- 팀 저장소: https://github.com/siamin20/skala-msa-customs (CustomsBridge — HS코드 AI 품목분류 + 통관 중개)
- 강의 템플릿 원본: `../msa-lecture/` — 한 단계 위다. 저장소에 커밋된 사본이 거기 있고,
  작업 디렉토리 안의 `msa-lecture/` 는 빌드 산출물이 붙은 401MB 사본이라 gitignore 대상이다.
  클론한 환경에는 위쪽만 존재하므로 항상 `../msa-lecture/` 를 읽어라
- 과제 범위의 기준: `2026-08-10_171407.txt` (교수님 코멘트) — 이해의 깊이 상한이 여기 있다
- 양식 기준: `코드이해_개인과제_템플릿2.docx` — 순서와 온도는 참고하되 문장은 베끼지 않는다

**원고 하드 게이트** (사용자가 직접 반려한 항목. 하나라도 남으면 다시 쓴다)

큰따옴표 0(코드 블록 예외), 중간점 0, 이모지 0, 물음표 0(위치 무관), 그림 뒤 캡션 0,
글이 자기를 설명하는 문장 0, 인용 앞 도입 한 줄 문단 0, 예고형 도입 문장 0,
`>` 인용 블록 0개, 사람 발언 인용 0. 지적받은 실제 문장과 고친 문장은
`template2-report-writing/references/voice-guide.md` 0절에 있고, 게이트 정의는
`template2-report-writing/scripts/voice-gate.sh` **한 곳뿐이다** — 집필자와 검수자가
같은 스크립트를 돌린다. 게이트를 늘릴 때 에이전트 `.md` 에 grep 을 새로 적지 마라.

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-08-10 | 초기 구성 (에이전트 4 + 스킬 5) | 전체 | - |
| 2026-08-10 | Chrome `--headless=old` 로 고정 | handdrawn-diagram/scripts/render.sh | Chrome 151의 `--headless=new` 가 스크린샷에서 매달림 |
| 2026-08-10 | 손글씨 기본 크기 상향 (21~22 → 25~26) | handdrawn-diagram/assets/sketch.js | 펜 글씨체 획이 얇아 Word 축소 시 뭉개짐 |
| 2026-08-10 | 계층형 레시피 수정 (캔버스 780, `db.top` 기준 화살표) | handdrawn-diagram/references/layout-recipes.md | Phase 6 실행 테스트 — DB 라벨 잘림 + 화살표가 원통 관통 |
| 2026-08-10 | 독립 인용문(`>`) 문법 표에 추가 | docx-compose/SKILL.md | 동작하는데 미문서화라 집필자가 쓸 수 있는 줄 몰랐음 |
| 2026-08-10 | 트리거 경계 명시 (집필↔오케스트레이터, 손그림↔dataviz) | template2-report-writing, handdrawn-diagram | Phase 6 트리거 검증 — near-miss 충돌 2건 |
| 2026-08-11 | 원고 하드 게이트 6종 신설 + 제출자 이름 고정 | voice-guide 0절, template2-anatomy, template2-report-writing, report-writer, human-voice-qa, orchestrator | 초고 검토 반려 — 큰따옴표, 중간점, 이모지, 답 없는 의문형, 그림 캡션, 자기 해설 문장이 AI 티로 읽힘 |
| 2026-08-11 | 원본 템플릿2 재추출 (87문단) | template2-anatomy, voice-guide | 기존 해부 문서가 그림 캡션 유무와 이모지 개수를 잘못 적고 있었음 (실제로 캡션 0개, 이모지 1개) |
| 2026-08-11 | venv 존재 확인을 `import docx` 검사로 교체 | docx-compose/SKILL.md | `python3 -m venv .venv` 가 기존 디렉토리를 갱신하지 않아, 깨진 venv가 있으면 Phase 4가 통째로 실패 |
| 2026-08-11 | 게이트 grep이 코드 블록을 벗기고 세도록 수정 + 의문형 제목 패턴에 `인가` 추가 | report-writer, human-voice-qa | 재집필 실행에서 오탐 — `event.get("userId")` 의 따옴표는 Java 문법이지 문체가 아니다. 그리고 `누가 낸 401인가` 를 기존 패턴이 놓쳤다 |
| 2026-08-11 | 캡션 절을 이름표 절로 교체 (그림 위, 필요할 때만) | _workspace/02_diagrams.md | 원본 템플릿2에 그림 캡션이 0개 |
| 2026-08-11 | 하드 게이트 3종 추가 (인용 블록 상한 2, 인용 앞 도입 한 줄 0, 예고형 도입 문장 0) | voice-gate.sh, voice-guide 0절, template2-report-writing, report-writer, human-voice-qa, orchestrator | 초고 반려 — 인용 4개에 도입 한 줄이 4개 붙어 혼잣말로 읽힘. 코드 주석 의역을 인용 블록에 넣은 대목은 어투가 본문과 달라 AI 티가 남 |
| 2026-08-11 | 게이트 grep을 `scripts/voice-gate.sh` 로 단일화 | report-writer, human-voice-qa | 같은 grep이 두 파일에 복제돼 있었고 코드 블록 오탐을 고칠 때 양쪽을 따로 손봐야 했다 |
| 2026-08-11 | 이모지 검사를 perl 로 교체 | scripts/voice-gate.sh | macOS 기본 grep 에 `-P` 가 없어 이모지 게이트가 조용히 통과하고 있었다 |
| 2026-08-11 | 인용 앞 도입 판정을 빈 줄 기준에서 앞 문단 문장 수 기준으로 교체 | scripts/voice-gate.sh | 첫 실행에서 집필자가 인용 앞 빈 줄을 지우자 게이트가 통과했다. 빈 줄로 판정하면 우회된다 |
| 2026-08-11 | 의문형 게이트를 물음표 전면 금지로 확대 (자문자답 포함) | voice-gate.sh, voice-guide 0절·물음표 절·1절, template2-report-writing | 답 없는 의문형이 이미 0인 상태에서 사용자가 물음표 자체가 어색하다고 재지적. 원본 템플릿2가 자문자답을 쓴다는 사실은 근거가 못 된다 |
| 2026-08-11 | 게이트가 `diagrams/*.js` 안 글씨도 검사하도록 확대 | scripts/voice-gate.sh | 본문에서 걷어낸 반려 문장이 그림에 그대로 살아 있었다. 그림은 같은 문서로 제출되므로 읽는 사람에게는 본문과 구별되지 않는다 |
| 2026-08-11 | perl 호출에 `-CSD` 추가 | scripts/voice-gate.sh | perl 이 입력을 바이트로 읽어 한글·이모지 유니코드 범위가 전부 매치되지 않았다. `grep -P` 를 perl 로 바꾸면서 같은 함정을 다시 밟았다 |
| 2026-08-11 | 재검수 시 앞 회차 판정문을 근거로 쓰지 말 것 (축 1에 절 신설) | human-voice-qa | 2회차가 1회차의 `01_evidence.md 는 낡았다` 를 재확인 없이 옮겨 적었는데 그 파일은 이미 갱신돼 있었다. 그 전제를 따랐으면 MAJOR 하나를 원고 대신 근거 파일을 고쳐서 처리할 뻔했다 |
| 2026-08-11 | 밀도 기준 신설 (절 하나에 본문 측정 수치 10개 이하, 표 안은 제외) | voice-guide 4절, human-voice-qa 정량 지표 | 사용자가 내용이 너무 심오하다고 반려. §6 본문에만 측정 수치가 26개 있어 실습 노트가 아니라 논문으로 읽혔다. 근거 파일이 두꺼우면 다 넣게 되는 게 원인이라, 표·그림·삭제 셋 중 하나로 빼는 기준을 적었다 |
| 2026-08-11 | voice-guide 4절의 톤 기준에서 교수님 발언 인용 제거 | voice-guide 4절 | 0절이 사람 발언 인용을 금지하는데 4절이 바로 그 문장을 톤 기준으로 인용하고 있었다 |
| 2026-08-11 | 인용 블록 상한 2 → **0** (전면 금지) + 사람 발언 인용 금지 신설 | voice-gate.sh, voice-guide 0절·인용 절·5절, report-writer, human-voice-qa, orchestrator, template2-report-writing, CLAUDE.md | 사용자가 마지막 남은 인용 블록(교수님 발언 축자)을 반려. 검수 기준으로는 통과(축자 + 어투가 정보)였는데 반려됐으니 기준이 틀렸던 것이다. 남의 말은 떠 오면 그 대목만 어투가 뜨고, 이 문서는 그 말을 한 사람이 읽는다. `교수님도 같은 선을 그으셨습니다` 처럼 인용 부호를 뗀 서술도 같이 반려 |

**검증 기록:** `_workspace/05_harness_verification.md` (Phase 6 구조·실행·트리거·드라이런)

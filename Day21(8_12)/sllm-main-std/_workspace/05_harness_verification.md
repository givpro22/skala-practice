# 하네스 검증 기록 — 2026-08-12 초기 구성

## 구조 검증 (Phase 6-1)

| 항목 | 결과 |
|---|---|
| 에이전트 정의 6개 frontmatter (name, description) | 통과 |
| 스킬 6개 frontmatter, `name` 과 디렉토리명 일치 | 통과 |
| SKILL.md 본문 500줄 이내 | 통과 (최대 208줄, sllm-subnote-orchestrator) |
| `.claude/commands/` 미생성 | 통과 |
| 전 에이전트 `model: opus` | 통과 (6/6) |
| 게이트 정의 복제 여부 | 통과 — `subnote-writing/scripts/voice-gate.sh` 한 곳 |
| 원고 경로 참조 일관성 | 통과 — day1 11회, day2 13회, 전부 같은 경로 |

## 게이트 실행 테스트 (Phase 6-3)

`voice-gate.sh` 는 하네스에서 유일하게 하중을 받는 부품이라 실제 원고로 돌렸다.

**위반 원고 (day2)** — 의도적으로 11종을 심었다.

걸린 것: 큰따옴표, 중간점, 이모지, 물음표, 자기 해설, 이름 자리표시자,
인용 블록 2건, 인용 앞 도입 한 줄, 제출자 줄 누락, 필수 5항목 4개 누락,
스냅샷 이미지 없음. 종료 코드 1.

`그림 뒤 캡션` 은 통과로 찍혔다. 이 검사는 이미지 **바로 다음 줄**만 보는데 테스트
원고는 사이에 빈 줄이 있었다. 같은 줄이 `인용 블록` 으로 잡혔으므로 반려 결과는
같다. 인용 블록 상한이 0이라 모든 `>` 줄이 걸리고, 그래서 캡션 검사는 사실상
중복이다. 남겨 두되 이 사실을 알고 있어야 한다 — 지적 라벨이 실제 원인과 다르게
찍힐 수 있다.

**통과 원고 (day2)** — 본문 검사 14개 전부 통과.

**그림 안 글씨** — scene `.js` 에 심은 중간점(`train · validation`)과 의문형
어미(`이게 맞을까`)를 둘 다 잡았다. 원고는 깨끗한데 그림이 더러운 경우를 잡는
경로가 살아 있다.

**day1 모드** — 본문 12개(문체 11 + 제출자 줄)만 돌고 day2 전용 구조 검사 2종은
건너뛴다. 확인함.

**파일명 유추** — 인자를 생략해도 `03_manuscript_day2.md` 에서 day2 로 판정한다.
다만 유추에 실패하면 구조 검사를 통째로 건너뛰므로, 호출부는 전부 인자를 명시한다.

**없는 파일** — 종료 코드 2.

## term_shot.py 실행 테스트

ANSI 색상 코드와 tqdm 진행바(`\r` 로 같은 줄을 세 번 덮어씀)를 섞은 로그로 확인.

- ANSI 제거 통과
- 진행바가 최종 상태 한 줄로 접힘 (12줄 → 10줄)

첫 판에서 접히지 않았다. 원인은 Python 텍스트 모드의 universal newline 이 읽는
시점에 `\r` 을 `\n` 으로 바꿔 버리는 것이었다. `newline=""` 로 고쳤다. 안 고쳤으면
학습 로그 스냅샷이 진행바 수백 줄로 채워졌을 것이다.

## 드라이런 (Phase 6-5)

Phase 경계에서 산출물이 다음 단계의 입력과 맞는지 확인했다.

```
Phase 1  outputs/*.json, models/hr-qwen-lora/, logs/*.log, snapshots/*.png, 00_run.md
   ↓     (2와 겹쳐서 돈다 — 학습 중 A~E, 완료 후 F~H)
Phase 2  01_evidence.md  A~H
   ↓
Phase 3  02_diagrams.md, diagrams/*.{js,png}, 03_manuscript_day1.md, day2.md
   ↓
Phase 4  04_qa.md
   ↓
Phase 5  report/*.docx 2개
```

끊긴 구간 없음. 한 군데 주의할 이음매가 있다 — `build_docx.py` 는 `--images-dir` 를
하나만 받고 `![](x.png)` 에서 파일명만 떼어 붙인다. 스냅샷은 `snapshots/` 에서
생기므로 조립 직전에 `diagrams/` 로 복사해야 한다. doc-builder 작업 원칙 1번과
docx-compose 스킬에 적어 두었다.

## 트리거 경계 (Phase 6-4)

| 요청 | 받는 쪽 |
|---|---|
| "서브노트 만들어줘", "과제 진행해줘" | sllm-subnote-orchestrator |
| "학습 돌려줘", "평가만 다시" | sft-practice-run |
| "이 절만 다시 써줘", "더 사람같이" | subnote-writing |
| "학습 결과 분석해줘", "평가 결과 읽어줘" | sllm-evidence-mining |
| "아키텍처 구성도 그려줘" | handdrawn-diagram |
| "docx로 뽑아줘" | docx-compose |

near-miss 로 갈릴 자리 셋을 각 description 에 명시했다.

- `sft-practice-run` ↔ `sllm-evidence-mining` — 프로세스를 띄우는 쪽과 이미 나온
  결과를 읽는 쪽
- `sllm-subnote-orchestrator` ↔ `subnote-writing` — 전체 파이프라인과 원고 문장만
- `handdrawn-diagram` ↔ `dataviz` — 구조를 그리는 것과 수치를 읽히는 차트

전역 스킬 목록(dataviz, artifact-design, code-review 등)과 이름 충돌 없음.

## 미검증

- `build_docx.py` 실제 조립 — Day19 에서 검증된 스크립트를 바이트 그대로 복사했고
  이번에 고치지 않았다. 첫 실행 때 doc-builder 가 이미지 개수 대조로 확인한다
- 학습·평가 실제 실행 — 아직 안 돌렸다. Phase 1 첫 실행이 곧 이 검증이다

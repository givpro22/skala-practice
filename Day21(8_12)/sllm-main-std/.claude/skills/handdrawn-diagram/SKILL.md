---
name: handdrawn-diagram
description: 손으로 그린 것처럼 투박한 플로우/아키텍처 다이어그램을 PNG로 생성한다. "손그림", "직접 그린 것처럼", "투박하게", "excalidraw 느낌", "필기 노트 스타일", "플로우 그려줘", "아키텍처 구성도", "시퀀스 흐름도" 같은 요청이 나오면 반드시 이 스킬을 쓴다. 보고서·발표자료에 넣을 다이어그램을 만들 때, 기존 다이어그램을 수정·재생성할 때, 다이어그램 크기/색/배치를 바꿔 다시 뽑을 때도 이 스킬을 쓴다. Mermaid나 SVG 도형 코드로 대체하지 말 것 — 그건 기계가 그린 티가 나서 이 요청의 목적을 정면으로 배반한다. 다만 수치를 읽히는 차트(막대·선·산점도)는 이 스킬이 아니라 dataviz 를 쓴다. 이 스킬은 구조와 흐름을 그리는 도구다.
---

# 손그림 다이어그램

## 무엇을 만드는가

rough.js(선이 두 번 겹치고 미세하게 어긋나는 스케치 렌더러) + 한글 손글씨 폰트를
canvas 위에서 합성해 PNG로 굽는다. 결과물은 태블릿으로 직접 그린 필기 노트에 가깝다.

Mermaid·draw.io·PlantUML을 쓰면 안 된다. 격자에 딱 맞은 직선과 시스템 고딕 글꼴은
"사람이 그렸다"는 인상을 즉시 무너뜨린다. 그 인상이 이 스킬의 존재 이유다.

## 파이프라인

```
scene.js (그리기 코드)  →  render.sh  →  PNG
                            │
                            ├ rough.js + sketch.js 인라인
                            ├ 손글씨 TTF 3종을 base64로 임베드
                            └ headless Chrome 스크린샷 (2배 해상도)
```

```bash
.claude/skills/handdrawn-diagram/scripts/render.sh <scene.js> <out.png> <W> <H> [seed]
```

`W`/`H`는 CSS 픽셀. 실제 PNG는 그 2배로 나온다(1000×700 → 2000×1400). 문서에 넣을 때
Word가 절반 크기로 배치하면 인쇄 품질이 유지된다.

`seed`를 고정하면 같은 scene은 항상 같은 그림이 된다. 문서를 다시 뽑을 때 선이
제멋대로 달라지면 어디가 바뀐 건지 볼 수 없다. 다이어그램마다 다른 seed를 주되,
한번 정한 seed는 바꾸지 않는다.

## scene.js 작성법

`render.sh`가 scene 파일의 내용을 async 함수 본문에 그대로 끼워 넣는다.
`initSketch`로 시작하고, `__W` `__H` `__SEED` 전역을 그대로 넘긴다.

```js
initSketch('c', __W, __H, __SEED);

text('LoRA SFT 학습 흐름', 40, 62, { size: 44, font: 'gaegu-bold', color: PALETTE.blue });

const ds   = box(60, 130, 220, 90, 'hr_sft_train\n582행');
const base = rbox(360, 130, 250, 90, 'Qwen2.5-1.5B', { color: PALETTE.green });
arrow(ds.right, ds.cy, base.left, base.cy, { label: 'chat template' });

cylinder(480, 420, 170, 130, 'LoRA\nAdapter');
person(90, 400, '인사팀 담당자');
circleMark(base.cx, base.cy, 300, 130, { color: PALETTE.red });
```

### 헬퍼 목록 (assets/sketch.js)

| 함수 | 쓰임 |
|---|---|
| `initSketch(id, w, h, seed)` | 캔버스 초기화. 항상 첫 줄 |
| `text(str, x, y, opts)` | 글씨. `\n`으로 여러 줄. `opts.rotate`로 기울임 |
| `box(x, y, w, h, label, opts)` | 각진 상자 |
| `rbox(x, y, w, h, label, opts)` | 둥근 상자 — 서비스/컴포넌트 |
| `cylinder(cx, cy, w, h, label)` | 원통 — DB |
| `person(cx, cy, label, opts)` | 졸라맨 — 사용자/이해관계자 |
| `arrow(x1,y1,x2,y2,opts)` | 화살표. `curve`로 휘고 `label`로 라벨 |
| `dashArrow(...)` | 점선 화살표 — **비동기 이벤트 전용** |
| `circleMark(cx,cy,w,h,opts)` | 강조 동그라미 |
| `underline(x1,x2,y,opts)` | 강조 밑줄 |
| `brace(x, yTop, yBot, opts)` | 중괄호 묶음 |

`box`/`rbox`/`cylinder`는 `{left,right,top,bottom,cx,cy}`를 돌려준다. 좌표를 손으로
계산해 박지 말고 이 값을 이어 붙여라 — 나중에 상자 하나를 옮기면 화살표가 따라온다.

### 색 규칙

`PALETTE`: `ink`(기본 검정) `blue` `green` `teal` `orange` `red` `gray` `violet`.

한 장에 3색을 넘기지 않는다. 실제로 손으로 그린 노트는 검정 펜 하나에 형광펜 한두
자루가 전부다. 색이 많아지면 "정성껏 만든 디지털 도표"로 보이기 시작한다.

- 검정 = 구조와 흐름
- 파랑/초록 = 제목, 기술 이름
- 빨강 = 이번 그림에서 진짜 하고 싶은 말 하나 (동그라미·밑줄)

### 폰트

- `pen` (기본) — 나눔손글씨 펜. 흘려 쓴 느낌. 라벨·주석용
- `gaegu` — 개구. 또박또박. 표 안의 글씨처럼 읽혀야 할 때
- `gaegu-bold` — 제목용

한글 크기는 24 아래로 내리지 마라. 펜 글씨체는 획이 얇아서 22px 밑으로 가면
2배 해상도로 뽑아도 Word에서 뭉갠 것처럼 보인다.

## 배치 원칙

레이아웃은 `references/layout-recipes.md`에 흐름형·계층형·분기형 3가지 골격이 있다.
새 다이어그램을 짤 때 먼저 그 파일에서 골격을 고르고 좌표만 바꿔라.

한 장에 담는 개념은 **최대 7개**. 그 이상이면 그림이 두 장으로 쪼개져야 한다는 신호다.
데이터셋 3종, Base 모델, Adapter, 학습, 평가, 지표 3종을 한 장에 다 넣으려는 충동이
가장 흔한 실패다. 아키텍처 구성도는 데이터 흐름 한 줄과 Adapter 결합 하나로 충분하다.

## 검수

PNG를 굽고 나면 **반드시 Read로 이미지를 열어 눈으로 확인**한다. 자동 실패하지 않고
조용히 망가지는 사고가 세 가지 있다:

1. 글자가 상자 밖으로 삐져나옴 — `measure()`로 폭을 재지 않고 상자 크기를 정했을 때
2. 캔버스 밖으로 잘림 — `cylinder`/`person`의 라벨은 도형 **아래**에 그려진다
3. 화살표가 상자 위를 지나감 — 시작·끝을 `.right`/`.left` 대신 `.cx`로 잡았을 때

## 자주 하는 실수

- **깔끔하게 만들려는 습관**: 상자를 격자에 정렬하고 화살표를 직각으로 꺾으면
  rough.js를 쓴 의미가 없다. 상자 높이를 5~10px씩 어긋나게 두고 화살표에 `curve`를
  조금 줘라. 완벽한 정렬이야말로 사람이 그리지 않았다는 증거다.
- **설명을 그림에 다 넣기**: 그림은 구조를, 본문은 설명을 맡는다. 그림 안 글자가
  한 문장을 넘어가면 본문으로 옮겨라.
- **seed를 매번 바꾸기**: 재생성마다 그림이 달라져 리뷰가 불가능해진다.

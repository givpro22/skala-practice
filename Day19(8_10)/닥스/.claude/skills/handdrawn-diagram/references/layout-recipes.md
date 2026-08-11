# 레이아웃 골격 3종

새 다이어그램은 처음부터 좌표를 짜지 말고 여기서 골격을 고른 뒤 이름과 좌표만 바꾼다.

## 목차
- [1. 흐름형 (좌→우 파이프라인)](#1-흐름형)
- [2. 계층형 (위→아래 스택)](#2-계층형)
- [3. 분기형 (조건에 따라 갈라짐)](#3-분기형)
- [공통 여백 규칙](#공통-여백-규칙)

---

## 1. 흐름형

단계가 순서대로 이어질 때. "요청 → 처리 → 응답", "입력 → 판정 → 분기".

```js
initSketch('c', __W, __H, __SEED);           // 권장 캔버스 1100 × 380

text('제목', 40, 60, { size: 42, font: 'gaegu-bold', color: PALETTE.blue });

const Y = 150, H = 100, W = 190, GAP = 70;
const steps = ['1단계', '2단계', '3단계', '4단계'];
let prev = null;
steps.forEach((s, i) => {
  const x = 60 + i * (W + GAP);
  // 높이를 조금씩 어긋나게 — 자로 잰 듯 맞으면 손그림이 아니다
  const cur = rbox(x, Y + (i % 2 ? 6 : -4), W, H, s);
  if (prev) arrow(prev.right, prev.cy, cur.left, cur.cy, { curve: i % 2 ? 8 : -8 });
  prev = cur;
});
```

4단계를 넘으면 두 줄로 접는다. 5개를 억지로 한 줄에 넣으면 상자가 좁아져 글씨가 넘친다.

## 2. 계층형

위에서 아래로 책임이 쌓일 때. "브라우저 → 게이트웨이 → 서비스 → DB".

```js
initSketch('c', __W, __H, __SEED);           // 권장 캔버스 1000 × 780

const cx = 500;
const l1 = rbox(cx - 150, 110, 300, 88, '브라우저');
const l2 = rbox(cx - 165, 250, 330, 88, 'API Gateway', { color: PALETTE.green });
// 같은 층에 여러 개가 오면 가로로 편다
const s1 = box(140, 400, 200, 86, 'user\nservice');
const s2 = box(400, 396, 200, 86, 'course\nservice');
const s3 = box(660, 404, 200, 86, 'payment\nservice');

arrow(l1.cx, l1.bottom, l2.cx, l2.top);
[s1, s2, s3].forEach(s => arrow(l2.cx, l2.bottom, s.cx, s.top, { curve: (s.cx - cx) / 14 }));

// cylinder 는 cy 기준이라 top = cy - h/2 다. 화살표는 top 위에서 멈춰야 원통을 뚫지 않는다.
const db = cylinder(cx, 620, 170, 120, 'MariaDB');
[s1, s2, s3].forEach(s => arrow(s.cx, s.bottom, cx + (s.cx - cx) / 5, db.top - 12, { head: false }));
```

같은 층의 상자는 **y좌표를 4~8px씩 흔든다**. 층 구분은 유지되면서 손그림 느낌이 산다.

맨 아래가 `cylinder`면 캔버스 높이를 두 번 확인하라. 라벨이 도형 아래 30px에 그려지므로
`cy + h/2 + 30 + 60` 이 캔버스 높이를 넘으면 라벨이 잘린다. 이 골격의 780은 그렇게 나온 값이다.

## 3. 분기형

조건에 따라 두 길로 갈릴 때. 이 실습 도메인에서는 "확신도 ≥ 임계값?"이 대표적이다.

```js
initSketch('c', __W, __H, __SEED);           // 권장 캔버스 1100 × 620

const inp = rbox(60, 250, 210, 92, '품목 설명\n입력');
const ai  = rbox(340, 244, 220, 100, 'AI 판정', { color: PALETTE.violet });
arrow(inp.right, inp.cy, ai.left, ai.cy);

// 분기점은 상자가 아니라 손글씨 질문 한 줄로 두는 편이 노트답다
text('확신도 ≥ 85% ?', 600, 292, { size: 30, font: 'gaegu-bold', color: PALETTE.red });

const yes = box(860, 130, 210, 92, '자동 확정');
const no  = box(860, 400, 210, 100, '관세사\n검토 의뢰');
arrow(790, 275, yes.left, yes.cy, { curve: -22, label: 'YES', labelColor: PALETTE.green });
arrow(790, 305, no.left,  no.cy,  { curve:  22, label: 'NO',  labelColor: PALETTE.red });

underline(600, 800, 305, { color: PALETTE.red });   // 이 그림의 핵심 한 곳만
```

분기 라벨(YES/NO)은 화살표 `label`로 붙인다. 별도 상자를 만들면 그림이 무거워진다.

## 공통 여백 규칙

| 항목 | 값 | 이유 |
|---|---|---|
| 캔버스 좌우 여백 | 40px 이상 | Word에서 이미지 테두리에 글자가 붙어 보이는 걸 막는다 |
| 제목 baseline | y = 60 안팎 | 그 위는 비워 둔다. 노트 맨 위는 원래 빈다 |
| 상자 간 가로 간격 | 60~90px | 화살표 라벨이 들어갈 자리 |
| 상자 간 세로 간격 | 100px 이상 | `cylinder`/`person` 라벨이 도형 아래로 30px 나간다 |
| 캔버스 아래 여백 | 60px 이상 | 맨 아래 도형이 `person`이면 80px |

## 비동기 이벤트는 반드시 점선

Kafka 이벤트처럼 "호출한 쪽이 응답을 기다리지 않는" 관계는 `dashArrow`로 그린다.
동기 호출과 같은 실선으로 그리면 그림이 거짓말을 한다 — 이 실습에서 결제가
수강 상태를 **직접 바꾸지 않는다**는 사실이 다이어그램의 핵심 정보이기 때문이다.

```js
dashArrow(pay.right, pay.cy, enr.left, enr.cy,
          { label: 'payment.completed', color: PALETTE.orange });
```

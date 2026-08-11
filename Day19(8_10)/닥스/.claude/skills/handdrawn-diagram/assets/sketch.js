/* sketch.js — 손그림 다이어그램 헬퍼
 *
 * rough.js 위에 얹은 얇은 레이어다. 도형은 rough.js 가 그리고(선이 두 번 겹치고
 * 미세하게 어긋나는 그 느낌), 글씨는 한글 손글씨 폰트로 canvas 에 직접 쓴다.
 *
 * 왜 canvas 인가: SVG 로 하면 폰트 임베딩이 스크린샷 시점에 늦게 붙어 글자가
 * 잘리는 일이 잦다. canvas 는 document.fonts.ready 를 기다린 뒤 한 번에 그리면
 * 결과가 결정적이다.
 *
 * 좌표계는 CSS 픽셀. 실제 캔버스는 DPR 2배로 잡아 인쇄해도 뭉개지지 않는다.
 */

const INK = '#1a1a1a';
const PALETTE = {
  ink: INK,
  blue: '#1971c2',
  green: '#2f9e44',
  teal: '#0ca678',
  orange: '#e8930c',
  red: '#e03131',
  gray: '#868e96',
  violet: '#6741d9',
};

let _ctx = null;
let _rc = null;
let _seed = 42;

/* 같은 입력이면 같은 그림이 나와야 한다. 문서를 다시 만들 때마다
 * 선이 제멋대로 흔들리면 diff 를 볼 수 없다. rough.js 는 seed 를 받는다. */
function nextSeed() {
  _seed = (_seed * 1103515245 + 12345) % 2147483648;
  return _seed;
}

function initSketch(canvasId, w, h, seed) {
  const cv = document.getElementById(canvasId);
  const dpr = 2;
  cv.width = w * dpr;
  cv.height = h * dpr;
  cv.style.width = w + 'px';
  cv.style.height = h + 'px';
  _ctx = cv.getContext('2d');
  _ctx.scale(dpr, dpr);
  _ctx.fillStyle = '#ffffff';
  _ctx.fillRect(0, 0, w, h);
  _rc = rough.canvas(cv);
  _seed = seed || 42;
  return { ctx: _ctx, rc: _rc };
}

function ro(opts = {}) {
  return Object.assign(
    {
      stroke: INK,
      strokeWidth: 1.9,
      roughness: 1.5,
      bowing: 1.6,
      seed: nextSeed(),
    },
    opts
  );
}

/* ---------- 글씨 ---------- */

/* size 는 CSS px. font 는 'pen'(나눔손글씨 펜) 또는 'gaegu'(개구, 좀 더 또박또박).
 * 제목은 gaegu-bold, 본문 라벨은 pen 을 쓰면 실제 필기 노트에 가깝다. */
function text(str, x, y, opts = {}) {
  const size = opts.size || 26;
  const font = opts.font || 'pen';
  const family = font === 'gaegu' ? 'Gaegu' : font === 'gaegu-bold' ? 'GaeguBold' : 'PenScript';
  _ctx.save();
  _ctx.fillStyle = opts.color || INK;
  _ctx.font = `${size}px "${family}"`;
  _ctx.textAlign = opts.align || 'left';
  _ctx.textBaseline = opts.baseline || 'alphabetic';
  /* 손으로 쓴 글씨는 베이스라인이 미세하게 논다. ±1px 이면 충분하고,
   * 그 이상 흔들면 '흉내'가 티가 난다. */
  const jitter = opts.jitter === false ? 0 : 1;
  const lines = String(str).split('\n');
  const lh = opts.lineHeight || size * 1.25;
  lines.forEach((ln, i) => {
    const dx = jitter ? (Math.sin((i + 1) * 12.9898 + x) * 43758.5453 % 1) * jitter : 0;
    const dy = jitter ? (Math.sin((i + 1) * 78.233 + y) * 43758.5453 % 1) * jitter : 0;
    if (opts.rotate) {
      _ctx.save();
      _ctx.translate(x + dx, y + i * lh + dy);
      _ctx.rotate(opts.rotate);
      _ctx.fillText(ln, 0, 0);
      _ctx.restore();
    } else {
      _ctx.fillText(ln, x + dx, y + i * lh + dy);
    }
  });
  _ctx.restore();
}

function measure(str, size = 26, font = 'pen') {
  const family = font === 'gaegu' ? 'Gaegu' : font === 'gaegu-bold' ? 'GaeguBold' : 'PenScript';
  _ctx.save();
  _ctx.font = `${size}px "${family}"`;
  const w = _ctx.measureText(String(str)).width;
  _ctx.restore();
  return w;
}

/* ---------- 도형 ---------- */

/* 라벨을 품은 상자. 여러 줄이면 \n 으로 넘긴다. */
function box(x, y, w, h, label, opts = {}) {
  const o = ro({ stroke: opts.stroke || INK, roughness: opts.roughness || 1.4 });
  if (opts.fill) {
    _rc.rectangle(x, y, w, h, Object.assign({}, o, {
      fill: opts.fill,
      fillStyle: opts.fillStyle || 'solid',
      fillWeight: 1,
    }));
  } else {
    _rc.rectangle(x, y, w, h, o);
  }
  if (label) {
    const size = opts.size || 25;
    const font = opts.font || 'pen';
    const lines = String(label).split('\n');
    const lh = size * 1.2;
    const startY = y + h / 2 - ((lines.length - 1) * lh) / 2;
    lines.forEach((ln, i) => {
      text(ln, x + w / 2, startY + i * lh, {
        size, font, align: 'center', baseline: 'middle',
        color: opts.color || INK,
      });
    });
  }
  return { x, y, w, h, cx: x + w / 2, cy: y + h / 2,
           left: x, right: x + w, top: y, bottom: y + h };
}

/* 둥근 상자 — 서비스/컴포넌트 표현에 쓴다. */
function rbox(x, y, w, h, label, opts = {}) {
  const r = opts.r || 12;
  const o = ro({ stroke: opts.stroke || INK });
  const p = `M ${x + r} ${y} L ${x + w - r} ${y} Q ${x + w} ${y} ${x + w} ${y + r}` +
            ` L ${x + w} ${y + h - r} Q ${x + w} ${y + h} ${x + w - r} ${y + h}` +
            ` L ${x + r} ${y + h} Q ${x} ${y + h} ${x} ${y + h - r}` +
            ` L ${x} ${y + r} Q ${x} ${y} ${x + r} ${y} Z`;
  if (opts.fill) {
    _rc.path(p, Object.assign({}, o, { fill: opts.fill, fillStyle: opts.fillStyle || 'solid', fillWeight: 1 }));
  } else {
    _rc.path(p, o);
  }
  if (label) {
    const size = opts.size || 25;
    const lines = String(label).split('\n');
    const lh = size * 1.2;
    const startY = y + h / 2 - ((lines.length - 1) * lh) / 2;
    lines.forEach((ln, i) => {
      text(ln, x + w / 2, startY + i * lh, {
        size, font: opts.font || 'pen', align: 'center', baseline: 'middle',
        color: opts.color || INK,
      });
    });
  }
  return { x, y, w, h, cx: x + w / 2, cy: y + h / 2,
           left: x, right: x + w, top: y, bottom: y + h };
}

/* 원통 = DB. 실습 다이어그램에서 제일 많이 쓰인다. */
function cylinder(cx, cy, w, h, label, opts = {}) {
  const o = ro({ stroke: opts.stroke || INK });
  const rx = w / 2, ry = h * 0.14;
  const top = cy - h / 2, bot = cy + h / 2;
  _rc.ellipse(cx, top, w, ry * 2, o);
  _rc.line(cx - rx, top, cx - rx, bot, ro());
  _rc.line(cx + rx, top, cx + rx, bot, ro());
  _rc.path(`M ${cx - rx} ${bot} A ${rx} ${ry} 0 0 0 ${cx + rx} ${bot}`, ro());
  /* 안쪽 결 두 줄 — 이게 있어야 원통으로 읽힌다 */
  _rc.path(`M ${cx - rx} ${top + h * 0.3} A ${rx} ${ry} 0 0 0 ${cx + rx} ${top + h * 0.3}`, ro({ strokeWidth: 1.3 }));
  _rc.path(`M ${cx - rx} ${top + h * 0.6} A ${rx} ${ry} 0 0 0 ${cx + rx} ${top + h * 0.6}`, ro({ strokeWidth: 1.3 }));
  if (label) text(label, cx, bot + 30, { size: opts.size || 25, align: 'center', color: opts.color || INK });
  return { cx, cy, top, bottom: bot, left: cx - rx, right: cx + rx };
}

/* 졸라맨 — 사용자/이해관계자 */
function person(cx, cy, label, opts = {}) {
  const s = opts.scale || 1;
  const headR = 20 * s;
  _rc.circle(cx, cy - 26 * s, headR * 2, ro());
  _rc.line(cx, cy - 6 * s, cx, cy + 26 * s, ro());
  _rc.line(cx - 22 * s, cy + 4 * s, cx + 22 * s, cy + 4 * s, ro());
  _rc.line(cx, cy + 26 * s, cx - 16 * s, cy + 54 * s, ro());
  _rc.line(cx, cy + 26 * s, cx + 16 * s, cy + 54 * s, ro());
  if (label) text(label, cx, cy + 80 * s, { size: opts.size || 24, align: 'center', color: opts.color || INK });
  return { cx, cy, top: cy - 46 * s, bottom: cy + 54 * s };
}

/* ---------- 화살표 ---------- */

/* 손으로 그은 화살표. curve 를 주면 그만큼 휘어진다(양수=시계방향 바깥쪽). */
function arrow(x1, y1, x2, y2, opts = {}) {
  const o = ro({ stroke: opts.color || INK, strokeWidth: opts.width || 1.9 });
  const curve = opts.curve || 0;
  if (curve) {
    const mx = (x1 + x2) / 2, my = (y1 + y2) / 2;
    const dx = x2 - x1, dy = y2 - y1;
    const len = Math.hypot(dx, dy) || 1;
    const nx = -dy / len, ny = dx / len;
    _rc.path(`M ${x1} ${y1} Q ${mx + nx * curve} ${my + ny * curve} ${x2} ${y2}`, o);
  } else {
    _rc.line(x1, y1, x2, y2, o);
  }
  if (opts.head === false) return;
  /* 화살촉: 진행 방향 기준 ±28°, 길이 14. 두 획을 따로 그어야 손맛이 난다. */
  const ang = curve
    ? Math.atan2(y2 - (y1 + y2) / 2 - (x2 - x1) / Math.hypot(x2 - x1, y2 - y1) * curve,
                 x2 - (x1 + x2) / 2 + (y2 - y1) / Math.hypot(x2 - x1, y2 - y1) * curve)
    : Math.atan2(y2 - y1, x2 - x1);
  const L = opts.headLen || 15;
  const a = 0.48;
  _rc.line(x2, y2, x2 - L * Math.cos(ang - a), y2 - L * Math.sin(ang - a), ro({ stroke: opts.color || INK }));
  _rc.line(x2, y2, x2 - L * Math.cos(ang + a), y2 - L * Math.sin(ang + a), ro({ stroke: opts.color || INK }));
  if (opts.label) {
    const mx = (x1 + x2) / 2, my = (y1 + y2) / 2;
    const dx = x2 - x1, dy = y2 - y1;
    const len = Math.hypot(dx, dy) || 1;
    const nx = -dy / len, ny = dx / len;
    const off = opts.labelOffset === undefined ? 16 : opts.labelOffset;
    text(opts.label, mx + nx * (curve / 2 + off) + (opts.labelDx || 0),
                     my + ny * (curve / 2 + off) + (opts.labelDy || 0),
         { size: opts.labelSize || 22, align: 'center', baseline: 'middle', color: opts.labelColor || opts.color || INK });
  }
}

/* 점선 — 비동기(이벤트) 흐름과 동기 호출을 눈으로 구분하려고 쓴다. */
function dashArrow(x1, y1, x2, y2, opts = {}) {
  const segs = opts.segs || 9;
  for (let i = 0; i < segs; i++) {
    if (i % 2) continue;
    const t0 = i / segs, t1 = (i + 1) / segs;
    _rc.line(x1 + (x2 - x1) * t0, y1 + (y2 - y1) * t0,
             x1 + (x2 - x1) * t1, y1 + (y2 - y1) * t1,
             ro({ stroke: opts.color || INK, strokeWidth: opts.width || 1.9 }));
  }
  arrow(x1 + (x2 - x1) * 0.93, y1 + (y2 - y1) * 0.93, x2, y2,
        Object.assign({}, opts, { label: undefined }));
  if (opts.label) {
    const mx = (x1 + x2) / 2, my = (y1 + y2) / 2;
    const dx = x2 - x1, dy = y2 - y1, len = Math.hypot(dx, dy) || 1;
    const nx = -dy / len, ny = dx / len;
    const off = opts.labelOffset === undefined ? 16 : opts.labelOffset;
    text(opts.label, mx + nx * off + (opts.labelDx || 0), my + ny * off + (opts.labelDy || 0),
         { size: opts.labelSize || 22, align: 'center', baseline: 'middle', color: opts.labelColor || opts.color || INK });
  }
}

/* 강조용 동그라미 — 손으로 친 것처럼 한 바퀴 반 돈다. */
function circleMark(cx, cy, w, h, opts = {}) {
  _rc.ellipse(cx, cy, w, h, ro({ stroke: opts.color || PALETTE.red, strokeWidth: 2.1, roughness: 2.2 }));
}

/* 밑줄 — 손으로 그은 강조선 */
function underline(x1, x2, y, opts = {}) {
  _rc.line(x1, y, x2, y, ro({ stroke: opts.color || PALETTE.red, strokeWidth: 2.2, roughness: 2.4 }));
}

/* 중괄호 — 여러 항목을 하나로 묶어 설명 붙일 때 */
function brace(x, yTop, yBot, opts = {}) {
  const d = opts.dir === 'right' ? -1 : 1;
  const mid = (yTop + yBot) / 2;
  const w = opts.w || 14;
  _rc.path(
    `M ${x + d * w} ${yTop} Q ${x} ${yTop} ${x} ${(yTop + mid) / 2}` +
    ` Q ${x} ${mid} ${x - d * 4} ${mid}` +
    ` Q ${x} ${mid} ${x} ${(mid + yBot) / 2}` +
    ` Q ${x} ${yBot} ${x + d * w} ${yBot}`,
    ro({ stroke: opts.color || INK, strokeWidth: 1.7 })
  );
}

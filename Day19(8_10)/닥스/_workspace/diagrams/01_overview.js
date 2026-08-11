initSketch('c', __W, __H, __SEED);

text('우리 팀 서비스 = 통관 중개 (CustomsBridge)', 45, 62,
     { size: 42, font: 'gaegu-bold', color: PALETTE.blue });
text('강의 템플릿(수강신청)의 뼈대를 그대로 두고 의미만 바꿨다', 45, 100,
     { size: 24, color: PALETTE.gray });

const user = person(105, 210, '수입기업 담당자', { scale: 0.95 });
const vue  = box(225, 152, 205, 92, 'Vue 프론트\n:3000');
const gw   = rbox(500, 146, 265, 100, 'API Gateway\n:8080', { color: PALETTE.green, size: 26 });

arrow(160, 200, vue.left - 6, vue.cy - 4, { curve: -6 });
arrow(vue.right, vue.cy + 2, gw.left - 4, gw.cy + 6, { label: '토큰 달고\n요청', labelSize: 21, labelOffset: 30 });

text('단일 진입점.', 800, 175, { size: 24, color: PALETTE.red });
text('토큰 없으면 경로 불문 401', 800, 205, { size: 24, color: PALETTE.red });

const svcY = 390, svcW = 190, svcH = 96;
const s1 = box(45,  svcY - 4, svcW, svcH, 'user\n:8081');
const s2 = box(285, svcY + 5, svcW, svcH, 'course\n:8082');
const s3 = box(525, svcY - 6, svcW, svcH, 'enrollment\n:8083');
const s4 = box(765, svcY + 3, svcW, svcH, 'payment\n:8084');
const s5 = rbox(1005, svcY - 3, svcW, svcH, 'recommend\n:8085', { color: PALETTE.violet, size: 24 });

[s1, s2, s3, s4, s5].forEach(s => {
  arrow(gw.cx + (s.cx - gw.cx) / 9, gw.bottom + 4, s.cx, s.top - 4, { curve: (s.cx - gw.cx) / 20 });
});

text('Python / FastAPI', 1100, 530, { size: 21, align: 'center', color: PALETTE.violet });
text('HS부호 12,469행 CSV', 1100, 558, { size: 21, align: 'center', color: PALETTE.violet });

const db = cylinder(590, 660, 175, 110, 'MariaDB  :3379');
[s1, s2, s3, s4].forEach(s => {
  arrow(s.cx, s.bottom + 4, db.cx + (s.cx - db.cx) / 4.5, db.top - 6, { head: false, curve: (s.cx - db.cx) / 26 });
});

text('DB는 하나를 나눠 쓴다 (실습 범위)', 800, 690, { size: 22, color: PALETTE.gray });

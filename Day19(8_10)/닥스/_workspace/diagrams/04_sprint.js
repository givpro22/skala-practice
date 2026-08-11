initSketch('c', __W, __H, __SEED);

text('Sprint 1 / Sprint 2 — 이렇게 자를 수 있었던 이유', 45, 62,
     { size: 40, font: 'gaegu-bold', color: PALETTE.blue });

const s1 = box(55, 130, 470, 320, '', { stroke: PALETTE.blue });
text('Sprint 1', 90, 180, { size: 34, font: 'gaegu-bold', color: PALETTE.blue });
text('한 흐름을 끝까지', 250, 180, { size: 23, color: PALETTE.gray });
box(95, 220, 180, 70, 'user');
box(295, 228, 180, 70, 'course');
box(190, 330, 190, 70, 'enrollment');
text('로그인 → 조회 → 의뢰(PENDING)', 90, 435, { size: 24 });

const s2 = box(615, 138, 480, 320, '', { stroke: PALETTE.green });
text('Sprint 2', 650, 188, { size: 34, font: 'gaegu-bold', color: PALETTE.green });
text('나머지를 붙인다', 810, 188, { size: 23, color: PALETTE.gray });
box(655, 228, 175, 70, 'payment');
box(855, 236, 200, 70, 'Kafka 이벤트');
box(755, 338, 200, 70, 'recommend');
text('결제 → 확정 → AI 판정, 추천', 650, 443, { size: 24 });

arrow(s1.right + 8, 290, s2.left - 8, 296, { label: '확장', labelSize: 24, labelOffset: -28 });
text('Sprint1 코드는', 570, 340, { size: 21, align: 'center', color: PALETTE.red });
text('건드리지 않음', 570, 366, { size: 21, align: 'center', color: PALETTE.red });

text('서비스가 나뉘어 있으니까 이렇게 자를 수 있는 것이다.', 55, 520, { size: 28 });
text('하나로 뭉쳐 있었다면 결제를 붙이면서 회원, 과목까지 다시 배포해야 한다.', 55, 558, { size: 26, color: PALETTE.gray });

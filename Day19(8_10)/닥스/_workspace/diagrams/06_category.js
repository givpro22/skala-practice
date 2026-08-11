initSketch('c', __W, __H, __SEED);

text('값 하나가 네 언어에 흩어져 있다', 45, 62,
     { size: 40, font: 'gaegu-bold', color: PALETTE.blue });

const en = box(390, 130, 330, 130,
  'Category\nELECTRONICS, CHEMICAL\nTEXTILE, FOOD_AGRI …', { size: 22 });

const t1 = box(45,  400, 220, 90, 'Java\nenum, 정규화');
const t2 = box(300, 408, 220, 90, 'Python\nCourseCategory');
const t3 = box(555, 398, 220, 90, 'Vue\n카테고리 맵');
const t4 = box(810, 406, 220, 90, 'SQL\ninit-db');

[t1, t2, t3, t4].forEach(t => arrow(en.cx + (t.cx - en.cx) / 8, en.bottom + 6, t.cx, t.top - 6,
                                    { curve: (t.cx - en.cx) / 22 }));

text('모두 합쳐 7개 지점', 800, 200, { size: 27, color: PALETTE.red });
circleMark(880, 192, 300, 66, { color: PALETTE.red });

text('하나만 바꾸면 안 바꾼 것보다 나쁘다.', 45, 570, { size: 28 });
text('recommend가 파싱에 실패하고, 프론트 필터는 조용히 빈 목록을 돌려준다.', 45, 608, { size: 25, color: PALETTE.gray });
text('에러가 안 난다는 게 제일 무서웠다.', 45, 646, { size: 26, color: PALETTE.red });

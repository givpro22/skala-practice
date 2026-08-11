initSketch('c', __W, __H, __SEED);

text('확신도가 가르는 것은 확정이 아니라 관세사다', 45, 62,
     { size: 38, font: 'gaegu-bold', color: PALETTE.blue });

const inp = rbox(45, 288, 185, 96, '품목 설명\n입력');
const ai  = rbox(280, 282, 200, 104, 'AI 품목분류', { color: PALETTE.blue, size: 26 });
arrow(inp.right + 6, inp.cy - 4, ai.left - 6, ai.cy + 4);

text('호 후보 3개 + 확신도', 272, 450, { size: 23, color: PALETTE.blue });

// 등급 넷. 위 셋은 묶이고 HIGH 하나만 따로 나간다 (recommend_router.py:50)
// NONE 은 후보가 없을 때만이 아니다. hs_classifier.py:789 의 is_search_failure 가
// 1위 점수 0.4 미만도 검색 실패로 보고 등급을 통째로 덮어쓴다 (:962)
const nNone = box(542, 92, 265, 112, 'NONE\n못 찾음 (1위 점수 0.4 미만)\n75건 중 9건', { size: 24 });
const nTie  = box(555, 220, 245, 112, 'TIE\n1위와 2위 동점\n75건 중 54건', { size: 24 });
const nLow  = box(564, 350, 245,  84, 'LOW\n그 밖의 경우',          { size: 24 });
const nHigh = box(557, 468, 245,  88, 'HIGH\n확신도 0.85 이상',     { size: 24 });

arrow(ai.right + 8, ai.cy - 12, nNone.left - 8, nNone.cy + 8, { curve: -20 });
arrow(ai.right + 8, ai.cy -  4, nTie.left  - 8, nTie.cy  + 6, { curve:  -9 });
arrow(ai.right + 8, ai.cy +  4, nLow.left  - 8, nLow.cy  - 4, { curve:   9 });
arrow(ai.right + 8, ai.cy + 12, nHigh.left - 8, nHigh.cy - 10, { curve: 20 });

brace(834, 96, 434, { dir: 'right' });
const out = rbox(920, 216, 272, 112, '관세사 목록을\n함께 보낸다');
arrow(848, 271, out.left - 8, out.cy - 1, { curve: -5 });

arrow(nHigh.right + 8, nHigh.cy, 900, nHigh.cy - 4, { curve: 5 });
text('관세사 목록 없이', 912, 498, { size: 24 });
text('후보 3개만', 912, 530, { size: 24 });

text('0.85를 넘긴 자동 확정 4건 중 1건이 오답', 45, 512, { size: 26 });
text('LED 모듈, 확신도 0.888 → 8539.51 램프', 45, 550, { size: 24 });
text('정답은 8541.41 발광다이오드 소자', 45, 584, { size: 24 });
text('그래서 자동 확정을 설계에서 뺐다', 45, 618, { size: 24 });

text('확정은 네 갈래 어디에서도 사람이 한다', 560, 660, { size: 28, color: PALETTE.red });
underline(556, 886, 674, { color: PALETTE.red });

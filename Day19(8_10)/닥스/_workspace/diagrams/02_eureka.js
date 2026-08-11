initSketch('c', __W, __H, __SEED);

text('Eureka — 주소를 모른 채 이름으로 부른다', 45, 62,
     { size: 40, font: 'gaegu-bold', color: PALETTE.blue });

const eu = rbox(400, 120, 300, 100, 'Eureka\n:8761', { color: PALETTE.teal, size: 26 });
text('누가 어디 떠 있는지', 730, 155, { size: 23, color: PALETTE.gray });
text('알고 있는 전화번호부', 730, 185, { size: 23, color: PALETTE.gray });

const enr = box(70,  360, 230, 100, 'enrollment\nservice');
const crs = box(800, 368, 230, 100, 'course\nservice');

dashArrow(enr.cx - 20, enr.top - 6, eu.cx - 90, eu.bottom + 6,
          { label: '나 여기 있어요', labelSize: 21, labelOffset: 34, color: PALETTE.teal });
dashArrow(crs.cx + 15, crs.top - 6, eu.cx + 95, eu.bottom + 6,
          { label: '나 여기 있어요', labelSize: 21, labelOffset: -34, color: PALETTE.teal });

arrow(enr.right + 6, enr.cy - 8, crs.left - 6, crs.cy - 6,
      { label: 'lb://course-service', labelSize: 25, labelOffset: 26 });
text('IP도 포트도 안 적었다', 550, 512, { size: 24, align: 'center', color: PALETTE.red });

underline(425, 680, 458, { color: PALETTE.red });

text('서비스가 하나였을 땐 필요 없던 물건.', 70, 560, { size: 26 });
text('쪼개는 순간 어느 서비스가 몇 번 포트에 떠 있는지를 누군가는 알아야 한다.', 70, 596, { size: 26 });

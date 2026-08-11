initSketch('c', __W, __H, __SEED);

text('결제는 의뢰 상태를 직접 바꾸지 않는다', 45, 62,
     { size: 40, font: 'gaegu-bold', color: PALETTE.blue });

const pay = rbox(60, 210, 250, 105, 'payment\nservice');
const kfk = box(470, 200, 270, 120, 'Kafka\npayment.completed', { color: PALETTE.orange, size: 24 });
const enr = rbox(900, 212, 260, 105, 'enrollment\nservice');

dashArrow(pay.right + 6, pay.cy - 4, kfk.left - 6, kfk.cy,
          { label: '발행', labelSize: 24, color: PALETTE.orange, labelOffset: 30 });
dashArrow(kfk.right + 6, kfk.cy, enr.left - 6, enr.cy - 2,
          { label: '수신', labelSize: 24, color: PALETTE.orange, labelOffset: 30 });

text('paymentId, userId,', 470, 370, { size: 21, color: PALETTE.gray });
text('courseId, status', 470, 396, { size: 21, color: PALETTE.gray });

text('PENDING → ACTIVE', enr.cx, 380, { size: 27, align: 'center', color: PALETTE.green });
text('실측 1초 안', enr.cx, 414, { size: 22, align: 'center', color: PALETTE.gray });

// 직접 호출했다면? — 그 길에 X 를 친다
arrow(pay.cx + 40, 500, enr.cx - 40, 500,
      { curve: 70, color: PALETTE.gray, width: 1.5 });
arrow(578, 508, 642, 562, { head: false, color: PALETTE.red, width: 2.4 });
arrow(642, 508, 578, 562, { head: false, color: PALETTE.red, width: 2.4 });
text('직접 호출', 610, 612, { size: 25, align: 'center', color: PALETTE.gray });

text('한쪽이 죽어도 다른 쪽은 자기 일을 계속한다.', 60, 705, { size: 27 });
text('대신 언제 반영됐는지를 아무도 즉시 보장해 주지 않는다.', 60, 745, { size: 27, color: PALETTE.red });

-- =====================================================================
-- Q7) 재고가 임계치(reorder_point)보다 낮은 상품 — 곧 품절 위험 상품
--   요구사항: qty_on_hand < reorder_point 인 상품, 부족량 큰 순
--   선택 컬럼: product_id, product_name, qty_on_hand, reorder_point, shortage
-- ---------------------------------------------------------------------
-- [튜닝 전] inventory 전량 Seq Scan 후 qty_on_hand < reorder_point 필터(600→61)
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT i.product_id, p.product_name, i.qty_on_hand, i.reorder_point,
       (i.reorder_point - i.qty_on_hand) AS shortage
FROM inventory i
JOIN products p ON p.product_id = i.product_id
WHERE i.qty_on_hand < i.reorder_point
ORDER BY shortage DESC;

-- ---------------------------------------------------------------------
-- [튜닝] 두 컬럼 비교 조건을 그대로 담은 '부분 인덱스'(품절 위험 상품만 인덱싱):
--   CREATE INDEX idx_inventory_low_stock ON inventory(product_id)
--     WHERE qty_on_hand < reorder_point;
-- [튜닝 후] SET enable_seqscan=off 시 Bitmap Index Scan(idx_inventory_low_stock)로
--   61행만 접근(Seq Scan은 600행 전수). 접근 행수/버퍼 감소 확인.
--   단, 600행 소형 테이블이라 절대시간은 Seq Scan(0.13ms)이 최저 → 옵티마이저 판단 정당.
--   → 교훈: 부분 인덱스의 이점(스캔 대상 축소)은 재고 테이블이 커질수록 커진다.
-- =====================================================================
SET enable_seqscan = off;  -- 인덱스 활용 계획을 명시적으로 확인
EXPLAIN (ANALYZE, BUFFERS)
SELECT i.product_id, p.product_name, i.qty_on_hand, i.reorder_point,
       (i.reorder_point - i.qty_on_hand) AS shortage
FROM inventory i
JOIN products p ON p.product_id = i.product_id
WHERE i.qty_on_hand < i.reorder_point
ORDER BY shortage DESC;
RESET enable_seqscan;

-- 결과(전후 동일): 품절 위험 61건, 상위는 재고 0 / reorder_point 30 (shortage 30)

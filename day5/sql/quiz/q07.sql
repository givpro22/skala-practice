-- =====================================================================
-- Q7) 재고가 임계치(reorder_point)보다 낮은 상품 — 곧 품절 위험 상품
--   요구사항: qty_on_hand < reorder_point 인 상품, 부족량 큰 순
--   선택 컬럼: product_id, product_name, qty_on_hand, reorder_point, shortage
-- ---------------------------------------------------------------------
-- [튜닝 전] inventory 전량 Seq Scan 후 qty_on_hand < reorder_point 필터(600→61)
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT i.product_id, p.product_name, i.qty_on_hand, i.reorder_point,  -- 상품/현재고/재주문점 표시
       (i.reorder_point - i.qty_on_hand) AS shortage  -- 부족량 = 재주문점 - 현재고
FROM inventory i                                     -- 재고 테이블(수량 비교 대상)
JOIN products p ON p.product_id = i.product_id       -- 상품명 얻기 위해 상품 연결
WHERE i.qty_on_hand < i.reorder_point                -- 현재고가 재주문점 미만 = 품절 위험
ORDER BY shortage DESC;                              -- 부족량 큰 순(급한 발주부터)

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
EXPLAIN (ANALYZE, BUFFERS)                          -- 동일 쿼리, 부분 인덱스 사용 계획 비교
SELECT i.product_id, p.product_name, i.qty_on_hand, i.reorder_point,  -- 상품/현재고/재주문점 표시
       (i.reorder_point - i.qty_on_hand) AS shortage  -- 부족량 = 재주문점 - 현재고
FROM inventory i                                     -- 재고 테이블(부분 인덱스로 위험 상품만 스캔)
JOIN products p ON p.product_id = i.product_id       -- 상품명 얻기 위해 상품 연결
WHERE i.qty_on_hand < i.reorder_point                -- 부분 인덱스 조건과 일치 → 61행만 접근
ORDER BY shortage DESC;                              -- 부족량 큰 순(급한 발주부터)
RESET enable_seqscan;                                -- 세션 설정 원복(옵티마이저 자동 판단 복귀)

-- 결과(전후 동일): 품절 위험 61건, 상위는 재고 0 / reorder_point 30 (shortage 30)

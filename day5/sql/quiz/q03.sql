-- =====================================================================
-- Q3) 최근 90일 카테고리 Top10 (매출 기준)
--   요구사항: 최근 90일, 카테고리별 매출 합계 상위 10
--   선택 컬럼: category_id, category_name, revenue
-- ---------------------------------------------------------------------
-- [튜닝 전] orders를 (상태 AND 90일) 필터로 Seq Scan → order_items/products/categories 조인
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT c.category_id, c.category_name, sum(oi.line_total) AS revenue  -- 카테고리별 라인 금액 합산 = 매출
FROM orders o                                       -- 주문(헤더): 상태/기간 필터 대상
JOIN order_items oi ON oi.order_id = o.order_id     -- 주문에 딸린 상세 라인 연결
JOIN products   p  ON p.product_id = oi.product_id  -- 상세의 제품으로 제품 정보 연결
JOIN categories c  ON c.category_id = p.category_id -- 제품의 카테고리로 분류 정보 연결
WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출로 인정되는 상태만
  AND o.order_ts >= now() - interval '90 days'      -- 최근 90일 주문으로 기간 한정
GROUP BY c.category_id, c.category_name             -- 카테고리 단위로 매출 집계
ORDER BY revenue DESC                               -- 매출 큰 순으로 정렬(상위 추출용)
LIMIT 10;                                           -- 상위 10개 카테고리만 반환(Top-N)

-- ---------------------------------------------------------------------
-- [튜닝] Q1과 동일한 부분 인덱스(idx_orders_rev_ts) 활용 가능.
--   다만 '최근 90일'은 전체의 약 60%로 선택도가 낮아, 비용기반 옵티마이저는
--   이 데이터 규모에서 여전히 Seq Scan을 선택(강제 인덱스 시 오히려 5→12ms로 느려짐).
--   → 교훈: 인덱스는 '선택적 조건'일 때 효과. 90일→14일처럼 좁히면 Bitmap Index Scan 채택.
--   [검증] SET enable_seqscan=off 시 idx_orders_rev_ts Bitmap Index Scan(4,059행)로 동작 확인.
--   ANALYZE로 통계 최신화하면 categories 추정행(1070→14) 정확화되어 계획이 안정화됨.
-- =====================================================================
-- (동일 쿼리 재실행 — 계획/통계 비교용)
EXPLAIN (ANALYZE, BUFFERS)                          -- 인덱스 후보 존재 시 계획 변화 비교용 재측정
SELECT c.category_id, c.category_name, sum(oi.line_total) AS revenue  -- (쿼리 동일) 카테고리별 매출 합산
FROM orders o                                       -- (쿼리 동일) 90일은 선택도 낮아 여전히 Seq Scan 채택
JOIN order_items oi ON oi.order_id = o.order_id     -- 주문 상세 라인 연결
JOIN products   p  ON p.product_id = oi.product_id  -- 제품 정보 연결
JOIN categories c  ON c.category_id = p.category_id -- 카테고리 정보 연결
WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출 인정 상태만
  AND o.order_ts >= now() - interval '90 days'      -- 최근 90일 한정(범위 좁히면 Bitmap Index Scan 유리)
GROUP BY c.category_id, c.category_name             -- 카테고리 단위 집계
ORDER BY revenue DESC                               -- 매출 내림차순 정렬
LIMIT 10;                                           -- 상위 10개만 반환(Top-N)

-- 결과(전후 동일): Women 132만 > Shoes 88만 > Fitness 21만 ... (Top10)

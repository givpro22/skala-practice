-- =====================================================================
-- Q3) 최근 90일 카테고리 Top10 (매출 기준)
--   요구사항: 최근 90일, 카테고리별 매출 합계 상위 10
--   선택 컬럼: category_id, category_name, revenue
-- ---------------------------------------------------------------------
-- [튜닝 전] orders를 (상태 AND 90일) 필터로 Seq Scan → order_items/products/categories 조인
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.category_id, c.category_name, sum(oi.line_total) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products   p  ON p.product_id = oi.product_id
JOIN categories c  ON c.category_id = p.category_id
WHERE o.order_status IN ('paid','shipped','delivered')
  AND o.order_ts >= now() - interval '90 days'
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- [튜닝] Q1과 동일한 부분 인덱스(idx_orders_rev_ts) 활용 가능.
--   다만 '최근 90일'은 전체의 약 60%로 선택도가 낮아, 비용기반 옵티마이저는
--   이 데이터 규모에서 여전히 Seq Scan을 선택(강제 인덱스 시 오히려 5→12ms로 느려짐).
--   → 교훈: 인덱스는 '선택적 조건'일 때 효과. 90일→14일처럼 좁히면 Bitmap Index Scan 채택.
--   [검증] SET enable_seqscan=off 시 idx_orders_rev_ts Bitmap Index Scan(4,059행)로 동작 확인.
--   ANALYZE로 통계 최신화하면 categories 추정행(1070→14) 정확화되어 계획이 안정화됨.
-- =====================================================================
-- (동일 쿼리 재실행 — 계획/통계 비교용)
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.category_id, c.category_name, sum(oi.line_total) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products   p  ON p.product_id = oi.product_id
JOIN categories c  ON c.category_id = p.category_id
WHERE o.order_status IN ('paid','shipped','delivered')
  AND o.order_ts >= now() - interval '90 days'
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC
LIMIT 10;

-- 결과(전후 동일): Women 132만 > Shoes 88만 > Fitness 21만 ... (Top10)

-- =====================================================================
-- Q4) 제품별 누적 매출 RANK() Top20
--   요구사항: 제품별 매출 합계에 RANK() 부여, 상위 20
--   선택 컬럼: product_id, product_name, revenue, rnk
-- ---------------------------------------------------------------------
-- [튜닝 전] 필터가 상태(paid/shipped/delivered)뿐이라 order_items 전량 집계 불가피
--   → Hash Join(14,250행) → HashAggregate(600) → Sort → WindowAgg → Top-N Sort
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_name, revenue,
       RANK() OVER (ORDER BY revenue DESC) AS rnk
FROM (
  SELECT p.product_id, p.product_name, sum(oi.line_total) AS revenue
  FROM order_items oi
  JOIN orders   o ON o.order_id  = oi.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.order_status IN ('paid','shipped','delivered')
  GROUP BY p.product_id, p.product_name
) t
ORDER BY rnk
LIMIT 20;

-- ---------------------------------------------------------------------
-- [튜닝] order_items(order_id, product_id, line_total) 커버링 인덱스 생성으로
--   조인 시 heap 접근을 줄이는 Index Only Scan 후보 제공.
--   단, 전량 집계형 쿼리라 이 규모에선 Seq Scan이 여전히 최저 비용(계산 바운드).
--   → 근본 개선책은 '사전 집계'로, Materialized View(제출물 3)에서 다룸.
--   [핵심] RANK()의 Sort는 윈도우 정의상 불가피 → 인덱스가 아닌 '전처리(MV)'가 정답.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_name, revenue,
       RANK() OVER (ORDER BY revenue DESC) AS rnk
FROM (
  SELECT p.product_id, p.product_name, sum(oi.line_total) AS revenue
  FROM order_items oi
  JOIN orders   o ON o.order_id  = oi.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.order_status IN ('paid','shipped','delivered')
  GROUP BY p.product_id, p.product_name
) t
ORDER BY rnk
LIMIT 20;

-- 결과(전후 동일): 1위 Product 175(162만), 2위 Product 299(69만) ...

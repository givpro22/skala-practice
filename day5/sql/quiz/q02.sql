-- =====================================================================
-- Q2) 월별 주문 수 / 매출 / 주문당 평균 금액(AOV)
--   요구사항: 월(month)별로 몇 건 주문, 매출 합계, AOV(=매출/주문수)
--   선택 컬럼: mon, orders, revenue, aov (요구 4개만)
-- ---------------------------------------------------------------------
-- [튜닝 전] AOV를 위해 count(DISTINCT order_id) 사용
--   → GroupAggregate 입력을 (month, order_id)로 정렬하는 14k행 Sort 발생
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('month', o.order_ts) AS mon,
       count(DISTINCT o.order_id)        AS orders,
       sum(oi.line_total)                AS revenue,
       sum(oi.line_total) / count(DISTINCT o.order_id) AS aov
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------
-- [튜닝] 주문 단위로 먼저 집계(order_id로 GROUP)한 뒤 월별 재집계
--   → count(DISTINCT) 제거 = 14k행 Sort 제거, HashAggregate 2단으로 처리
--   계획에서 14,250행 Sort 노드 제거(정상상태 CLI 약 10ms→7ms). 인덱스 없이 재작성만으로 개선.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('month', order_ts) AS mon,
       count(*)                       AS orders,
       sum(order_rev)                 AS revenue,
       round(sum(order_rev)/count(*), 2) AS aov
FROM (
  SELECT o.order_id, o.order_ts, sum(oi.line_total) AS order_rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status IN ('paid','shipped','delivered')
  GROUP BY o.order_id, o.order_ts
) t
GROUP BY 1 ORDER BY 1;

-- 결과(전후 동일): 2026-04 ~ 2026-07 월매출 약 108만~140만, AOV 약 880~977

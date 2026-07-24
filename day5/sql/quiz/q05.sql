-- =====================================================================
-- Q5) RFM 분석 — 고객이 얼마나 최근에(Recency)/자주(Frequency)/많이(Monetary) 샀나
--   요구사항: 고객별 최근성(일), 빈도(주문수), 금액(매출). 금액 상위 20 표시.
--   선택 컬럼: customer_id, recency_days, frequency, monetary
-- ---------------------------------------------------------------------
-- [튜닝 전] frequency = count(DISTINCT order_id)
--   → GroupAggregate 입력을 (customer_id, order_id)로 정렬하는 14k행 Sort 발생
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.customer_id,
       (now()::date - max(o.order_ts)::date) AS recency_days,
       count(DISTINCT o.order_id)            AS frequency,
       sum(oi.line_total)                    AS monetary
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY o.customer_id
ORDER BY monetary DESC
LIMIT 20;

-- ---------------------------------------------------------------------
-- [튜닝] 주문 단위 선집계 후 고객별 재집계 → count(DISTINCT) 제거(14k Sort 제거)
--   계획에서 14,250행 Sort 노드 제거(정상상태 CLI 약 9ms→8ms). 쿼리 재작성만으로 개선.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT t.customer_id,
       (now()::date - max(t.order_ts)::date) AS recency_days,
       count(*)          AS frequency,
       sum(t.order_rev)  AS monetary
FROM (
  SELECT o.order_id, o.customer_id, o.order_ts, sum(oi.line_total) AS order_rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status IN ('paid','shipped','delivered')
  GROUP BY o.order_id, o.customer_id, o.order_ts
) t
GROUP BY t.customer_id
ORDER BY monetary DESC
LIMIT 20;

-- 결과(전후 동일): 헤비고객 19번(37,420) ~ 17번(20,941), frequency 21로 균일

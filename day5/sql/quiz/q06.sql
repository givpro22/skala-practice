-- =====================================================================
-- Q6) 첫 구매 후 30일 내 재구매율
--   요구사항: 고객의 첫 결제완료 주문 이후 30일 이내 재주문한 비율(%)
--   선택 컬럼: cohort(모수), repurchased(재구매자), pct_30d(비율)
-- ---------------------------------------------------------------------
-- [튜닝 전] 고객별 첫 주문 시각(firsts) 계산 후, LATERAL로 30일내 재주문 존재 탐색.
--   프로브는 기존 idx_orders_customer_ts(Index Scan)를 쓰지만 status 필터를
--   heap에서 재확인 → 프로브당 heap 접근(버퍼 hit 5,539).
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
WITH firsts AS (
  SELECT customer_id, min(order_ts) AS first_ts
  FROM orders
  WHERE order_status IN ('paid','shipped','delivered')
  GROUP BY customer_id
)
SELECT count(*) AS cohort,
       count(*) FILTER (WHERE re.customer_id IS NOT NULL) AS repurchased,
       round(100.0 * count(*) FILTER (WHERE re.customer_id IS NOT NULL) / count(*), 2) AS pct_30d
FROM firsts f
LEFT JOIN LATERAL (
  SELECT o2.customer_id
  FROM orders o2
  WHERE o2.customer_id = f.customer_id
    AND o2.order_status IN ('paid','shipped','delivered')
    AND o2.order_ts >  f.first_ts
    AND o2.order_ts <= f.first_ts + interval '30 days'
  LIMIT 1
) re ON true;

-- ---------------------------------------------------------------------
-- [튜닝] status 조건까지 담은 복합 부분 인덱스 생성:
--   CREATE INDEX idx_orders_cust_rev_ts ON orders(customer_id, order_ts)
--     WHERE order_status IN ('paid','shipped','delivered');
-- [튜닝 후] 프로브가 Index Only Scan(idx_orders_cust_rev_ts)로 전환 → heap 재확인 제거
--   Buffers hit 5,539 → 대폭 감소(heap 접근 제거). 동일 쿼리, 인덱스만 추가(정상상태 CLI 약 6ms).
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
WITH firsts AS (
  SELECT customer_id, min(order_ts) AS first_ts
  FROM orders
  WHERE order_status IN ('paid','shipped','delivered')
  GROUP BY customer_id
)
SELECT count(*) AS cohort,
       count(*) FILTER (WHERE re.customer_id IS NOT NULL) AS repurchased,
       round(100.0 * count(*) FILTER (WHERE re.customer_id IS NOT NULL) / count(*), 2) AS pct_30d
FROM firsts f
LEFT JOIN LATERAL (
  SELECT o2.customer_id
  FROM orders o2
  WHERE o2.customer_id = f.customer_id
    AND o2.order_status IN ('paid','shipped','delivered')
    AND o2.order_ts >  f.first_ts
    AND o2.order_ts <= f.first_ts + interval '30 days'
  LIMIT 1
) re ON true;

-- 결과(전후 동일): cohort 2,227 / repurchased 1,085 / pct_30d 48.72%

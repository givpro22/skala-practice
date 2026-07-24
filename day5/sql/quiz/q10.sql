-- =====================================================================
-- Q10) 상위 1% 고객의 최근 60일 매출
--   요구사항: 최근 60일 매출 기준 상위 1%(99퍼센타일 이상) 고객 목록
--   선택 컬럼: customer_id, rev
-- ---------------------------------------------------------------------
-- [튜닝 전] 최근 60일 매출을 고객별 집계(cust_rev CTE). orders를
--   (상태 AND 60일) 필터로 Seq Scan(3,892행 제거) → 임계값(percentile) 비교
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
WITH cust_rev AS (
  SELECT o.customer_id, sum(oi.line_total) AS rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status IN ('paid','shipped','delivered')
    AND o.order_ts >= now() - interval '60 days'
  GROUP BY o.customer_id
)
SELECT customer_id, rev
FROM cust_rev
WHERE rev >= (SELECT percentile_cont(0.99) WITHIN GROUP (ORDER BY rev) FROM cust_rev)
ORDER BY rev DESC;

-- ---------------------------------------------------------------------
-- [튜닝] 부분 인덱스 idx_orders_rev_ts 활용 (60일=약 42%로 Q3보다 선택적).
-- [튜닝 후] Seq Scan → Bitmap Index Scan(idx_orders_rev_ts)로 60일치만 접근
--   Seq Scan → Bitmap Index Scan(60일≈42%로 선택적). 동일 쿼리, 인덱스만 추가(정상상태 CLI 약 6ms).
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
WITH cust_rev AS (
  SELECT o.customer_id, sum(oi.line_total) AS rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status IN ('paid','shipped','delivered')
    AND o.order_ts >= now() - interval '60 days'
  GROUP BY o.customer_id
)
SELECT customer_id, rev
FROM cust_rev
WHERE rev >= (SELECT percentile_cont(0.99) WITHIN GROUP (ORDER BY rev) FROM cust_rev)
ORDER BY rev DESC;

-- 결과(전후 동일): 상위 1% = 18명 (고객 19번 33,828 ~ 29번 20,696)

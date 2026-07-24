-- =====================================================================
-- Q9) 쿠폰 사용 영향 — 쿠폰 쓴 주문 vs 안 쓴 주문의 평균 주문금액(AOV) 비교
--   요구사항: coupon_code 유무별 주문수와 AOV
--   선택 컬럼: used_coupon, orders, aov
-- ---------------------------------------------------------------------
-- [튜닝 전] 주문 단위 집계 후, 바깥에서 GroupAggregate가 (used_coupon, order_id)
--   기준 Sort(5,216행) 후 그룹핑 → 불필요한 정렬 발생
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT (o.coupon_code IS NOT NULL) AS used_coupon,
       count(DISTINCT o.order_id)   AS orders,
       round(avg(order_rev), 2)     AS aov
FROM (
  SELECT o.order_id, o.coupon_code, sum(oi.line_total) AS order_rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status IN ('paid','shipped','delivered')
  GROUP BY o.order_id, o.coupon_code
) o
GROUP BY 1;

-- ---------------------------------------------------------------------
-- [튜닝] 안쪽에서 (order_id, used_coupon)로 선집계 → 바깥은 used_coupon으로
--   HashAggregate. count(DISTINCT) 제거 + 바깥 Sort 제거
--   외부 5,216행 Sort 노드 제거(정상상태 CLI 약 7.1ms→6.3ms). 쿼리 재작성만으로 개선.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT used_coupon, count(*) AS orders, round(avg(order_rev), 2) AS aov
FROM (
  SELECT o.order_id, (o.coupon_code IS NOT NULL) AS used_coupon,
         sum(oi.line_total) AS order_rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status IN ('paid','shipped','delivered')
  GROUP BY o.order_id, (o.coupon_code IS NOT NULL)
) t
GROUP BY used_coupon;

-- 결과(전후 동일): 쿠폰無 3,953건 AOV 635.61 vs 쿠폰有 1,263건 AOV 1,827.10
--   (SAVE10 쿠폰이 고액 주문에 주로 사용됨을 시사)

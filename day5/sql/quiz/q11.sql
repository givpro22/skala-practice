-- =====================================================================
-- Q11) 0으로 나누어도 에러 안 나는 나눗셈 함수(f_safe_div)로 안전하게 AOV 계산
--   요구사항: 분모가 0이어도 에러 없이 0 반환하는 UDF 사용해 채널별 AOV 계산
--   선택 컬럼: channel, revenue, orders, safe_aov
--   f_safe_div(numer, denom): denom=0 이면 0 반환 (스키마에 정의됨)
-- ---------------------------------------------------------------------
-- [튜닝 전] orders=count(DISTINCT order_id)
--   → GroupAggregate 입력을 (channel, order_id)로 정렬하는 14k행 Sort 발생
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.channel,
       sum(oi.line_total)         AS revenue,
       count(DISTINCT o.order_id) AS orders,
       round(f_safe_div(sum(oi.line_total), count(DISTINCT o.order_id)), 2) AS safe_aov
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY o.channel
ORDER BY revenue DESC;

-- ---------------------------------------------------------------------
-- [튜닝] 주문 단위 선집계 후 채널별 재집계 → count(DISTINCT) 제거(14k Sort 제거)
--   이중 Sort(14,250행+외부) → HashAggregate(정상상태 CLI 약 10.5ms→6ms).
--   f_safe_div는 분모(주문수)가 0이어도 0 반환 → 무주문 채널 안전.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT channel,
       sum(order_rev) AS revenue,
       count(*)       AS orders,
       round(f_safe_div(sum(order_rev), count(*)), 2) AS safe_aov
FROM (
  SELECT o.order_id, o.channel, sum(oi.line_total) AS order_rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status IN ('paid','shipped','delivered')
  GROUP BY o.order_id, o.channel
) t
GROUP BY channel
ORDER BY revenue DESC;

-- 안전 나눗셈 데모: f_safe_div(100,0)=0 (에러 없음),  f_safe_div(100,4)=25
-- 결과(전후 동일): mobile 240만/2,633건/913 · web 125만/1,310건/954 · marketplace 117만/1,273건/916

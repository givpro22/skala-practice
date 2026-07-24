-- =====================================================================
-- Q11) 0으로 나누어도 에러 안 나는 나눗셈 함수(f_safe_div)로 안전하게 AOV 계산
--   요구사항: 분모가 0이어도 에러 없이 0 반환하는 UDF 사용해 채널별 AOV 계산
--   선택 컬럼: channel, revenue, orders, safe_aov
--   f_safe_div(numer, denom): denom=0 이면 0 반환 (스키마에 정의됨)
-- ---------------------------------------------------------------------
-- [튜닝 전] orders=count(DISTINCT order_id)
--   → GroupAggregate 입력을 (channel, order_id)로 정렬하는 14k행 Sort 발생
-- =====================================================================
SET search_path = ecom, public;                        -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT o.channel,                                       -- 유입 채널별로 집계
       sum(oi.line_total)         AS revenue,           -- 채널 총매출(상세금액 합계)
       count(DISTINCT o.order_id) AS orders,            -- 채널 주문 건수(조인 중복 제거 위해 DISTINCT)
       round(f_safe_div(sum(oi.line_total), count(DISTINCT o.order_id)), 2) AS safe_aov  -- 안전 나눗셈으로 AOV(주문수 0이면 0)
FROM orders o                                           -- 주문(헤더)
JOIN order_items oi ON oi.order_id = o.order_id         -- 주문에 딸린 상세 라인 연결
WHERE o.order_status IN ('paid','shipped','delivered') -- 매출 인정 상태만
GROUP BY o.channel                                      -- 채널 단위로 집계
ORDER BY revenue DESC;                                  -- 매출 높은 채널 순 정렬

-- ---------------------------------------------------------------------
-- [튜닝] 주문 단위 선집계 후 채널별 재집계 → count(DISTINCT) 제거(14k Sort 제거)
--   이중 Sort(14,250행+외부) → HashAggregate(정상상태 CLI 약 10.5ms→6ms).
--   f_safe_div는 분모(주문수)가 0이어도 0 반환 → 무주문 채널 안전.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT channel,                                         -- 유입 채널별로 재집계
       sum(order_rev) AS revenue,                       -- 주문별 매출을 채널 단위로 합산 = 채널 총매출
       count(*)       AS orders,                        -- 채널 주문 건수(이미 주문 단위라 DISTINCT 불필요)
       round(f_safe_div(sum(order_rev), count(*)), 2) AS safe_aov  -- 안전 나눗셈으로 AOV(주문수 0이면 0 반환)
FROM (                                                  -- 주문 단위로 먼저 선집계
  SELECT o.order_id, o.channel, sum(oi.line_total) AS order_rev  -- 주문 1건의 상세금액 합계
  FROM orders o                                         -- 주문(헤더)
  JOIN order_items oi ON oi.order_id = o.order_id       -- 주문에 딸린 상세 라인 연결
  WHERE o.order_status IN ('paid','shipped','delivered') -- 매출 인정 상태만
  GROUP BY o.order_id, o.channel                        -- 주문+채널로 선집계(order_id 단위라 중복 없음)
) t
GROUP BY channel                                        -- 바깥은 채널로 재집계(count DISTINCT 제거)
ORDER BY revenue DESC;                                  -- 매출 높은 채널 순 정렬

-- 안전 나눗셈 데모: f_safe_div(100,0)=0 (에러 없음),  f_safe_div(100,4)=25
-- 결과(전후 동일): mobile 240만/2,633건/913 · web 125만/1,310건/954 · marketplace 117만/1,273건/916

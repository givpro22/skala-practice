-- =====================================================================
-- Q9) 쿠폰 사용 영향 — 쿠폰 쓴 주문 vs 안 쓴 주문의 평균 주문금액(AOV) 비교
--   요구사항: coupon_code 유무별 주문수와 AOV
--   선택 컬럼: used_coupon, orders, aov
-- ---------------------------------------------------------------------
-- [튜닝 전] 주문 단위 집계 후, 바깥에서 GroupAggregate가 (used_coupon, order_id)
--   기준 Sort(5,216행) 후 그룹핑 → 불필요한 정렬 발생
-- =====================================================================
SET search_path = ecom, public;                        -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT (o.coupon_code IS NOT NULL) AS used_coupon,     -- 쿠폰 사용 여부(있으면 true)로 그룹 구분
       count(DISTINCT o.order_id)   AS orders,          -- 주문 건수(서브쿼리 조인 중복 방지 위해 DISTINCT)
       round(avg(order_rev), 2)     AS aov              -- 주문별 매출의 평균 = 평균 주문금액(AOV)
FROM (                                                  -- 주문 단위 선집계 서브쿼리
  SELECT o.order_id, o.coupon_code, sum(oi.line_total) AS order_rev  -- 주문 1건의 상세금액 합계
  FROM orders o                                         -- 주문(헤더)
  JOIN order_items oi ON oi.order_id = o.order_id       -- 주문에 딸린 상세 라인 연결
  WHERE o.order_status IN ('paid','shipped','delivered') -- 매출 인정 상태만
  GROUP BY o.order_id, o.coupon_code                    -- 주문별로 먼저 합산
) o
GROUP BY 1;                                             -- 바깥에서 쿠폰 유무(1번 컬럼)로 재집계

-- ---------------------------------------------------------------------
-- [튜닝] 안쪽에서 (order_id, used_coupon)로 선집계 → 바깥은 used_coupon으로
--   HashAggregate. count(DISTINCT) 제거 + 바깥 Sort 제거
--   외부 5,216행 Sort 노드 제거(정상상태 CLI 약 7.1ms→6.3ms). 쿼리 재작성만으로 개선.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT used_coupon, count(*) AS orders, round(avg(order_rev), 2) AS aov  -- 그룹당 주문수와 평균매출(AOV)
FROM (                                                  -- 주문+쿠폰여부 단위로 선집계
  SELECT o.order_id, (o.coupon_code IS NOT NULL) AS used_coupon,  -- 쿠폰 사용 여부를 안쪽에서 미리 계산
         sum(oi.line_total) AS order_rev                -- 주문 1건의 상세금액 합계
  FROM orders o                                         -- 주문(헤더)
  JOIN order_items oi ON oi.order_id = o.order_id       -- 주문에 딸린 상세 라인 연결
  WHERE o.order_status IN ('paid','shipped','delivered') -- 매출 인정 상태만
  GROUP BY o.order_id, (o.coupon_code IS NOT NULL)      -- 주문+쿠폰여부로 선집계(order_id 단위라 중복 없음)
) t
GROUP BY used_coupon;                                   -- 바깥은 쿠폰여부로 HashAggregate(count DISTINCT 불필요)

-- 결과(전후 동일): 쿠폰無 3,953건 AOV 635.61 vs 쿠폰有 1,263건 AOV 1,827.10
--   (SAVE10 쿠폰이 고액 주문에 주로 사용됨을 시사)

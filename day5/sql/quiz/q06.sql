-- =====================================================================
-- Q6) 첫 구매 후 30일 내 재구매율
--   요구사항: 고객의 첫 결제완료 주문 이후 30일 이내 재주문한 비율(%)
--   선택 컬럼: cohort(모수), repurchased(재구매자), pct_30d(비율)
-- ---------------------------------------------------------------------
-- [튜닝 전] 고객별 첫 주문 시각(firsts) 계산 후, LATERAL로 30일내 재주문 존재 탐색.
--   프로브는 기존 idx_orders_customer_ts(Index Scan)를 쓰지만 status 필터를
--   heap에서 재확인 → 프로브당 heap 접근(버퍼 hit 5,539).
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
WITH firsts AS (                                     -- CTE: 고객별 첫 구매 시점 산출
  SELECT customer_id, min(order_ts) AS first_ts     -- 고객별 최초 주문시각 = 첫 구매일
  FROM orders                                        -- 주문 헤더 전체에서
  WHERE order_status IN ('paid','shipped','delivered')  -- 실구매로 인정되는 상태만 집계
  GROUP BY customer_id                               -- 고객 단위로 묶어 min() 계산
)
SELECT count(*) AS cohort,                           -- 첫 구매 고객 수 = 재구매율 모수(분모)
       count(*) FILTER (WHERE re.customer_id IS NOT NULL) AS repurchased,  -- 30일내 재주문 있는 고객 수(분자)
       round(100.0 * count(*) FILTER (WHERE re.customer_id IS NOT NULL) / count(*), 2) AS pct_30d  -- 재구매율(%) 소수2자리
FROM firsts f                                        -- 고객별 첫 구매 시점(기준행)
LEFT JOIN LATERAL (                                  -- 각 첫구매행마다 상관 서브쿼리 실행(프로브)
  SELECT o2.customer_id                              -- 재주문 존재 여부만 확인(고객id 반환)
  FROM orders o2                                      -- 같은 주문 테이블에서 재주문 탐색
  WHERE o2.customer_id = f.customer_id               -- 동일 고객의 주문으로 한정
    AND o2.order_status IN ('paid','shipped','delivered')  -- 실구매 상태 재주문만
    AND o2.order_ts >  f.first_ts                    -- 첫 구매 이후(초과) 발생분
    AND o2.order_ts <= f.first_ts + interval '30 days'  -- 첫 구매 후 30일 이내
  LIMIT 1                                             -- 1건만 있으면 재구매 성립 → 조기 종료
) re ON true;                                         -- LATERAL: 재주문 없어도 모수는 유지(LEFT)

-- ---------------------------------------------------------------------
-- [튜닝] status 조건까지 담은 복합 부분 인덱스 생성:
--   CREATE INDEX idx_orders_cust_rev_ts ON orders(customer_id, order_ts)
--     WHERE order_status IN ('paid','shipped','delivered');
-- [튜닝 후] 프로브가 Index Only Scan(idx_orders_cust_rev_ts)로 전환 → heap 재확인 제거
--   Buffers hit 5,539 → 대폭 감소(heap 접근 제거). 동일 쿼리, 인덱스만 추가(정상상태 CLI 약 6ms).
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)                          -- 동일 쿼리, 부분 인덱스 추가 후 계획 비교
WITH firsts AS (                                     -- CTE: 고객별 첫 구매 시점 산출
  SELECT customer_id, min(order_ts) AS first_ts     -- 고객별 최초 주문시각 = 첫 구매일
  FROM orders                                        -- 주문 헤더 전체에서
  WHERE order_status IN ('paid','shipped','delivered')  -- 실구매로 인정되는 상태만 집계
  GROUP BY customer_id                               -- 고객 단위로 묶어 min() 계산
)
SELECT count(*) AS cohort,                           -- 첫 구매 고객 수 = 재구매율 모수(분모)
       count(*) FILTER (WHERE re.customer_id IS NOT NULL) AS repurchased,  -- 30일내 재주문 있는 고객 수(분자)
       round(100.0 * count(*) FILTER (WHERE re.customer_id IS NOT NULL) / count(*), 2) AS pct_30d  -- 재구매율(%) 소수2자리
FROM firsts f                                        -- 고객별 첫 구매 시점(기준행)
LEFT JOIN LATERAL (                                  -- 각 첫구매행마다 상관 서브쿼리 실행(프로브)
  SELECT o2.customer_id                              -- 재주문 존재 여부만 확인(고객id 반환)
  FROM orders o2                                      -- 부분 인덱스로 재주문 탐색(Index Only Scan 유도)
  WHERE o2.customer_id = f.customer_id               -- 동일 고객의 주문으로 한정
    AND o2.order_status IN ('paid','shipped','delivered')  -- 인덱스 조건과 일치(heap 재확인 제거)
    AND o2.order_ts >  f.first_ts                    -- 첫 구매 이후(초과) 발생분
    AND o2.order_ts <= f.first_ts + interval '30 days'  -- 첫 구매 후 30일 이내
  LIMIT 1                                             -- 1건만 있으면 재구매 성립 → 조기 종료
) re ON true;                                         -- LATERAL: 재주문 없어도 모수는 유지(LEFT)

-- 결과(전후 동일): cohort 2,227 / repurchased 1,085 / pct_30d 48.72%

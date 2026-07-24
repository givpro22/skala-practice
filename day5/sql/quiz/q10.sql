-- =====================================================================
-- Q10) 상위 1% 고객의 최근 60일 매출
--   요구사항: 최근 60일 매출 기준 상위 1%(99퍼센타일 이상) 고객 목록
--   선택 컬럼: customer_id, rev
-- ---------------------------------------------------------------------
-- [튜닝 전] 최근 60일 매출을 고객별 집계(cust_rev CTE). orders를
--   (상태 AND 60일) 필터로 Seq Scan(3,892행 제거) → 임계값(percentile) 비교
-- =====================================================================
SET search_path = ecom, public;                        -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
WITH cust_rev AS (                                      -- 고객별 최근 60일 매출을 미리 집계하는 CTE
  SELECT o.customer_id, sum(oi.line_total) AS rev       -- 고객별 상세금액 합계 = 고객 매출
  FROM orders o                                         -- 주문(헤더)
  JOIN order_items oi ON oi.order_id = o.order_id       -- 주문에 딸린 상세 라인 연결
  WHERE o.order_status IN ('paid','shipped','delivered') -- 매출 인정 상태만
    AND o.order_ts >= now() - interval '60 days'        -- 최근 60일 주문만
  GROUP BY o.customer_id                                -- 고객 단위로 매출 합산
)
SELECT customer_id, rev                                 -- 상위 1%에 든 고객과 매출 출력
FROM cust_rev                                           -- 위에서 집계한 고객별 매출
WHERE rev >= (SELECT percentile_cont(0.99) WITHIN GROUP (ORDER BY rev) FROM cust_rev)  -- 99퍼센타일(상위1%) 임계값 이상만
ORDER BY rev DESC;                                      -- 매출 높은 순 정렬

-- ---------------------------------------------------------------------
-- [튜닝] 부분 인덱스 idx_orders_rev_ts 활용 (60일=약 42%로 Q3보다 선택적).
-- [튜닝 후] Seq Scan → Bitmap Index Scan(idx_orders_rev_ts)로 60일치만 접근
--   Seq Scan → Bitmap Index Scan(60일≈42%로 선택적). 동일 쿼리, 인덱스만 추가(정상상태 CLI 약 6ms).
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
WITH cust_rev AS (                                      -- 고객별 최근 60일 매출을 미리 집계하는 CTE
  SELECT o.customer_id, sum(oi.line_total) AS rev       -- 고객별 상세금액 합계 = 고객 매출
  FROM orders o                                         -- 주문(헤더)
  JOIN order_items oi ON oi.order_id = o.order_id       -- 주문에 딸린 상세 라인 연결
  WHERE o.order_status IN ('paid','shipped','delivered') -- 매출 인정 상태만
    AND o.order_ts >= now() - interval '60 days'        -- 최근 60일 주문만(부분 인덱스가 적용되는 조건)
  GROUP BY o.customer_id                                -- 고객 단위로 매출 합산
)
SELECT customer_id, rev                                 -- 상위 1%에 든 고객과 매출 출력
FROM cust_rev                                           -- 위에서 집계한 고객별 매출
WHERE rev >= (SELECT percentile_cont(0.99) WITHIN GROUP (ORDER BY rev) FROM cust_rev)  -- 99퍼센타일(상위1%) 임계값 이상만
ORDER BY rev DESC;                                      -- 매출 높은 순 정렬

-- 결과(전후 동일): 상위 1% = 18명 (고객 19번 33,828 ~ 29번 20,696)

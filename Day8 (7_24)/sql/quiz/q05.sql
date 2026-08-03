-- =====================================================================
-- Q5) RFM 분석 — 고객이 얼마나 최근에(Recency)/자주(Frequency)/많이(Monetary) 샀나
--   요구사항: 고객별 최근성(일), 빈도(주문수), 금액(매출). 금액 상위 20 표시.
--   선택 컬럼: customer_id, recency_days, frequency, monetary
-- ---------------------------------------------------------------------
-- [튜닝 전] frequency = count(DISTINCT order_id)
--   → GroupAggregate 입력을 (customer_id, order_id)로 정렬하는 14k행 Sort 발생
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT o.customer_id,                              -- 분석 단위: 고객
       (now()::date - max(o.order_ts)::date) AS recency_days,  -- 오늘-최근주문일 = 최근성(Recency, 일수)
       count(DISTINCT o.order_id)            AS frequency,  -- 조인 중복 제거한 순수 주문수 = 빈도(Frequency)
       sum(oi.line_total)                    AS monetary  -- 라인 금액 합산 = 총구매액(Monetary)
FROM orders o                                       -- 주문(헤더): 상태 필터 및 고객/시각 원천
JOIN order_items oi ON oi.order_id = o.order_id     -- 상세 라인 연결(금액 집계용, 행 증식 발생)
WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출 인정 상태만
GROUP BY o.customer_id                              -- 고객 단위로 RFM 집계
ORDER BY monetary DESC                              -- 구매액 큰 순(헤비고객 우선) 정렬
LIMIT 20;                                           -- 상위 20명만 반환(Top-N)

-- ---------------------------------------------------------------------
-- [튜닝] 주문 단위 선집계 후 고객별 재집계 → count(DISTINCT) 제거(14k Sort 제거)
--   계획에서 14,250행 Sort 노드 제거(정상상태 CLI 약 9ms→8ms). 쿼리 재작성만으로 개선.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)                          -- 재작성 쿼리의 실행계획 측정(Sort 노드 제거 확인)
SELECT t.customer_id,                              -- 분석 단위: 고객
       (now()::date - max(t.order_ts)::date) AS recency_days,  -- 오늘-최근주문일 = 최근성(Recency)
       count(*)          AS frequency,            -- 이미 주문 단위라 단순 count(*)로 빈도(DISTINCT 불필요)
       sum(t.order_rev)  AS monetary              -- 주문별 매출 합산 = 총구매액(Monetary)
FROM (                                              -- ↓ 주문 단위 선집계(count(DISTINCT) 대체용 사전집계)
  SELECT o.order_id, o.customer_id, o.order_ts, sum(oi.line_total) AS order_rev  -- 주문 1건의 금액 선합산
  FROM orders o                                     -- 주문(헤더)
  JOIN order_items oi ON oi.order_id = o.order_id   -- 상세 라인 연결
  WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출 인정 상태만
  GROUP BY o.order_id, o.customer_id, o.order_ts    -- 주문 단위로 묶어 1행/주문으로 축약(중복 제거 효과)
) t
GROUP BY t.customer_id                              -- 축약된 주문행을 고객별로 재집계
ORDER BY monetary DESC                              -- 구매액 큰 순(헤비고객 우선) 정렬
LIMIT 20;                                           -- 상위 20명만 반환(Top-N)

-- 결과(전후 동일): 헤비고객 19번(37,420) ~ 17번(20,941), frequency 21로 균일

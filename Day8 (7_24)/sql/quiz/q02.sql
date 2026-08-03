-- =====================================================================
-- Q2) 월별 주문 수 / 매출 / 주문당 평균 금액(AOV)
--   요구사항: 월(month)별로 몇 건 주문, 매출 합계, AOV(=매출/주문수)
--   선택 컬럼: mon, orders, revenue, aov (요구 4개만)
-- ---------------------------------------------------------------------
-- [튜닝 전] AOV를 위해 count(DISTINCT order_id) 사용
--   → GroupAggregate 입력을 (month, order_id)로 정렬하는 14k행 Sort 발생
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT date_trunc('month', o.order_ts) AS mon,     -- 주문시각을 '월' 단위로 절삭해 집계키로 사용
       count(DISTINCT o.order_id)        AS orders,  -- 조인으로 중복된 주문을 중복제거해 순수 주문 건수
       sum(oi.line_total)                AS revenue, -- 상세 라인 금액 합산 = 월 매출
       sum(oi.line_total) / count(DISTINCT o.order_id) AS aov  -- 매출/주문수 = 주문당 평균금액(AOV)
FROM orders o                                       -- 주문(헤더): 상태/기간 필터 대상
JOIN order_items oi ON oi.order_id = o.order_id     -- 주문 1건에 딸린 상세 라인 연결(행 증식 발생)
WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출로 인정되는 상태만(취소/환불/생성 제외)
GROUP BY 1 ORDER BY 1;                              -- 월(1번 컬럼)별로 묶고 월 오름차순 정렬

-- ---------------------------------------------------------------------
-- [튜닝] 주문 단위로 먼저 집계(order_id로 GROUP)한 뒤 월별 재집계
--   → count(DISTINCT) 제거 = 14k행 Sort 제거, HashAggregate 2단으로 처리
--   계획에서 14,250행 Sort 노드 제거(정상상태 CLI 약 10ms→7ms). 인덱스 없이 재작성만으로 개선.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)                          -- 재작성 쿼리의 실행계획 측정(Sort 노드 제거 확인)
SELECT date_trunc('month', order_ts) AS mon,       -- 선집계 결과의 주문시각을 월 단위로 절삭
       count(*)                       AS orders,   -- 이미 주문 단위라 단순 count(*)로 주문 건수(DISTINCT 불필요)
       sum(order_rev)                 AS revenue,  -- 주문별 매출을 월 단위로 재합산 = 월 매출
       round(sum(order_rev)/count(*), 2) AS aov    -- 월매출/주문수 = AOV(소수 2자리 반올림)
FROM (                                              -- ↓ 주문 단위 선집계(count(DISTINCT) 대체용 사전집계)
  SELECT o.order_id, o.order_ts, sum(oi.line_total) AS order_rev  -- 주문 1건의 라인 금액을 먼저 합산
  FROM orders o                                     -- 주문(헤더)
  JOIN order_items oi ON oi.order_id = o.order_id   -- 상세 라인 연결
  WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출 인정 상태만
  GROUP BY o.order_id, o.order_ts                   -- 주문 단위로 묶어 1행/주문으로 축약(중복 제거 효과)
) t
GROUP BY 1 ORDER BY 1;                              -- 축약된 주문행을 월별로 재집계, 월 오름차순 정렬

-- 결과(전후 동일): 2026-04 ~ 2026-07 월매출 약 108만~140만, AOV 약 880~977

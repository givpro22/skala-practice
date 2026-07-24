-- =====================================================================
-- Q4) 제품별 누적 매출 RANK() Top20
--   요구사항: 제품별 매출 합계에 RANK() 부여, 상위 20
--   선택 컬럼: product_id, product_name, revenue, rnk
-- ---------------------------------------------------------------------
-- [튜닝 전] 필터가 상태(paid/shipped/delivered)뿐이라 order_items 전량 집계 불가피
--   → Hash Join(14,250행) → HashAggregate(600) → Sort → WindowAgg → Top-N Sort
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT product_id, product_name, revenue,          -- 선집계된 제품별 매출 그대로 출력
       RANK() OVER (ORDER BY revenue DESC) AS rnk  -- 매출 내림차순 순위 부여(동순위 허용, WindowAgg)
FROM (                                              -- ↓ 제품 단위 매출 선집계(윈도우 입력용)
  SELECT p.product_id, p.product_name, sum(oi.line_total) AS revenue  -- 제품별 라인 금액 합산 = 매출
  FROM order_items oi                               -- 상세 라인(집계 대상 전량)
  JOIN orders   o ON o.order_id  = oi.order_id      -- 주문 헤더 연결(상태 필터용)
  JOIN products p ON p.product_id = oi.product_id   -- 제품명 조회용 연결
  WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출 인정 상태만
  GROUP BY p.product_id, p.product_name             -- 제품 단위로 묶어 1행/제품으로 집계
) t
ORDER BY rnk                                        -- 순위 오름차순(1위부터) 정렬
LIMIT 20;                                           -- 상위 20개 제품만 반환(Top-N)

-- ---------------------------------------------------------------------
-- [튜닝] order_items(order_id, product_id, line_total) 커버링 인덱스 생성으로
--   조인 시 heap 접근을 줄이는 Index Only Scan 후보 제공.
--   단, 전량 집계형 쿼리라 이 규모에선 Seq Scan이 여전히 최저 비용(계산 바운드).
--   → 근본 개선책은 '사전 집계'로, Materialized View(제출물 3)에서 다룸.
--   [핵심] RANK()의 Sort는 윈도우 정의상 불가피 → 인덱스가 아닌 '전처리(MV)'가 정답.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)                          -- 커버링 인덱스 후보 존재 시 계획 변화 비교용 재측정
SELECT product_id, product_name, revenue,          -- (쿼리 동일) 제품별 매출 출력
       RANK() OVER (ORDER BY revenue DESC) AS rnk  -- RANK()의 Sort는 윈도우 정의상 불가피(인덱스로 제거 불가)
FROM (                                              -- ↓ 제품 단위 매출 선집계
  SELECT p.product_id, p.product_name, sum(oi.line_total) AS revenue  -- 제품별 매출 합산
  FROM order_items oi                               -- 상세 라인: 커버링 인덱스 시 Index Only Scan 후보
  JOIN orders   o ON o.order_id  = oi.order_id      -- 주문 헤더 연결(상태 필터용)
  JOIN products p ON p.product_id = oi.product_id   -- 제품명 조회용 연결
  WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출 인정 상태만(전량 집계형)
  GROUP BY p.product_id, p.product_name             -- 제품 단위 집계
) t
ORDER BY rnk                                        -- 순위 오름차순 정렬
LIMIT 20;                                           -- 상위 20개만 반환(근본 개선은 MV 사전집계)

-- 결과(전후 동일): 1위 Product 175(162만), 2위 Product 299(69만) ...

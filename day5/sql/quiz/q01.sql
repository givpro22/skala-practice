-- =====================================================================
-- Q1) 지난 한 달간 실제 팔린 총 금액 (order_status = paid/shipped/delivered)
--   요구사항: 취소/환불/생성 상태는 제외, 최근 1개월(now 기준) 매출 합계
--   선택 컬럼: sum(line_total) 하나만 (불필요 컬럼 없음)
-- ---------------------------------------------------------------------
-- [튜닝 전] orders에 (상태 AND 기간) 필터가 있으나 이를 지원하는 인덱스가 없어
--           Seq Scan on orders (수천 행 필터로 제거) → Hash Join
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT sum(oi.line_total) AS revenue               -- 주문상세 금액을 전부 합산 = 총매출
FROM orders o                                       -- 주문(헤더): 상태/기간 필터 대상
JOIN order_items oi ON oi.order_id = o.order_id     -- 주문 1건에 딸린 상세 라인 연결
WHERE o.order_status IN ('paid','shipped','delivered')  -- 매출로 인정되는 상태만(취소/환불/생성 제외)
  AND o.order_ts >= now() - interval '1 month';     -- 최근 1개월 주문으로 기간 한정

-- ---------------------------------------------------------------------
-- [튜닝] 매출 상태만 담고 order_ts로 정렬한 '부분 인덱스' 생성
--   CREATE INDEX idx_orders_rev_ts ON orders(order_ts)
--     WHERE order_status IN ('paid','shipped','delivered');
-- [튜닝 후] Seq Scan → Bitmap Index Scan(idx_orders_rev_ts)로 1개월치(1,431행)만 접근
--   ※ ms 단위 계측 오버헤드로 절대시간 편차 큼 → 핵심 근거는 계획/버퍼 변화.
--     총시간은 order_items 공유 스캔이 지배하여 유사(정상상태 CLI 약 4.5ms→3.8ms),
--     이득은 필터 테이블 접근이 인덱스화된 점 + 대용량 확장성.
-- =====================================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT sum(oi.line_total) AS revenue               -- (쿼리 동일) 매출 합계
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')  -- ← 이 조건이 부분 인덱스 WHERE와 일치 → 인덱스 사용
  AND o.order_ts >= now() - interval '1 month';     -- ← 인덱스 정렬키(order_ts)로 범위 스캔

-- 결과(튜닝 전후 동일): revenue = 1,395,893.20

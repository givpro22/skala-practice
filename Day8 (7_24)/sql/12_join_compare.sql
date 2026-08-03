-- =====================================================================
-- 제출물 2) 3가지 조인 알고리즘 비교 (Nested Loop / Hash / Merge)
--   동일 쿼리를 enable_* 플래그로 각 조인 전략을 강제하여 실행계획·특성 비교
--   대상 쿼리: 최근 30일 주문(외부 1,836행) × order_items(내부 18,393행) 집계
-- =====================================================================
SET search_path = ecom, public;                        -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

-- [0] 옵티마이저 자동 선택 (기본값) → 이 데이터에선 Hash Join 채택
EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT o.order_id, sum(oi.line_total) AS order_total   -- 주문별 상세금액 합계
FROM orders o                                          -- 주문(헤더, 최근 30일 외부 입력)
JOIN order_items oi ON oi.order_id = o.order_id        -- 주문에 딸린 상세 라인 연결
WHERE o.order_ts >= now() - interval '30 days'         -- 최근 30일 주문만
GROUP BY o.order_id;                                   -- 주문 단위로 합산

-- ---------------------------------------------------------------------
-- [1] Nested Loop Join (NLJ) 강제
--   특성: 외부 각 행마다 내부를 인덱스로 반복 탐색. 외부가 작고 내부에 인덱스가
--   있을 때 유리. 여기선 외부 1,836행 × 커버링 인덱스 프로브(Index Only Scan).
-- ---------------------------------------------------------------------
SET enable_hashjoin = off; SET enable_mergejoin = off; SET enable_nestloop = on;  -- Hash·Merge 끄고 Nested Loop만 허용
EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT o.order_id, sum(oi.line_total) AS order_total   -- 주문별 상세금액 합계
FROM orders o                                          -- 주문(헤더, 최근 30일 외부 입력)
JOIN order_items oi ON oi.order_id = o.order_id        -- 외부 각 행마다 내부를 인덱스로 프로브
WHERE o.order_ts >= now() - interval '30 days'         -- 최근 30일 주문만
GROUP BY o.order_id;                                   -- 주문 단위로 합산
RESET enable_hashjoin; RESET enable_mergejoin; RESET enable_nestloop;  -- 조인 플래그를 기본값으로 원복

-- ---------------------------------------------------------------------
-- [2] Hash Join 강제
--   특성: 작은 쪽으로 해시 테이블을 만들고 큰 쪽을 스캔하며 매칭. 인덱스가 없거나
--   대량 등가 조인에 유리. 여기선 orders(작은쪽) 해시 + order_items 전량 Seq Scan.
-- ---------------------------------------------------------------------
SET enable_nestloop = off; SET enable_mergejoin = off; SET enable_hashjoin = on;  -- Nested Loop·Merge 끄고 Hash Join만 허용
EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT o.order_id, sum(oi.line_total) AS order_total   -- 주문별 상세금액 합계
FROM orders o                                          -- 주문(작은 쪽 → 해시 테이블 빌드)
JOIN order_items oi ON oi.order_id = o.order_id        -- 큰 쪽(order_items)을 스캔하며 해시 매칭
WHERE o.order_ts >= now() - interval '30 days'         -- 최근 30일 주문만
GROUP BY o.order_id;                                   -- 주문 단위로 합산
RESET enable_nestloop; RESET enable_mergejoin; RESET enable_hashjoin;  -- 조인 플래그를 기본값으로 원복

-- ---------------------------------------------------------------------
-- [3] Merge Join 강제
--   특성: 양쪽을 조인 키로 정렬한 뒤 병합. 이미 정렬된(인덱스) 입력이면 매우 효율.
--   여기선 order_items는 인덱스 정렬 스캔, orders는 Sort 후 Merge.
-- ---------------------------------------------------------------------
SET enable_nestloop = off; SET enable_hashjoin = off; SET enable_mergejoin = on;  -- Nested Loop·Hash 끄고 Merge Join만 허용
EXPLAIN (ANALYZE, BUFFERS)                              -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT o.order_id, sum(oi.line_total) AS order_total   -- 주문별 상세금액 합계
FROM orders o                                          -- 주문(조인 키로 Sort 후 병합)
JOIN order_items oi ON oi.order_id = o.order_id        -- 양쪽을 order_id로 정렬해 병합 매칭
WHERE o.order_ts >= now() - interval '30 days'         -- 최근 30일 주문만
GROUP BY o.order_id;                                   -- 주문 단위로 합산
RESET enable_nestloop; RESET enable_hashjoin; RESET enable_mergejoin;  -- 조인 플래그를 기본값으로 원복

-- =====================================================================
-- 요약 (이 데이터 규모 기준, 수 ms대라 상대 비교):
--   Nested Loop : 외부 1,836행 × 인덱스 프로브. 외부가 더 커지면 프로브 폭증에 불리.
--   Hash Join   : order_items 전량 스캔 + 해시. 옵티마이저 기본 선택(대량 조인 안정적).
--   Merge Join  : 정렬 비용이 들지만 정렬된 입력이면 유리. 대용량 정렬 조인에 강점.
-- =====================================================================

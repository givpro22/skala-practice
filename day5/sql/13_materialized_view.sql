-- =====================================================================
-- 제출물 3) Materialized View — mv_daily_gmv (일자별 총 판매금액)
--   목적: 매일 총 판매금액(GMV) 리포트를 매번 JOIN+SUM 하면 느리므로
--         Materialized View로 사전 집계하여 리포트 질의를 가속.
-- =====================================================================
SET search_path = ecom, public;

-- [1] MV 생성 스크립트 (스키마에 정의된 것과 동일; 재현용 CREATE)
DROP MATERIALIZED VIEW IF EXISTS mv_daily_gmv CASCADE;
CREATE MATERIALIZED VIEW mv_daily_gmv AS
SELECT date_trunc('day', o.order_ts) AS day,
       sum(oi.line_total)            AS gmv
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY 1;

-- 조회 가속용 인덱스 (day로 정렬 조회 → Index Scan)
CREATE INDEX IF NOT EXISTS idx_mv_daily_gmv_day ON mv_daily_gmv(day);
-- (고급) 무중단 갱신 REFRESH ... CONCURRENTLY 를 쓰려면 UNIQUE 인덱스 필요:
CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_daily_gmv_day ON mv_daily_gmv(day);

-- [2] MV 미사용 — 매번 JOIN+SUM 직접 집계 (튜닝 전)
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('day', o.order_ts) AS day, sum(oi.line_total) AS gmv
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY 1
ORDER BY 1 DESC
LIMIT 10;

-- [3] MV 갱신 (데이터 변경 반영; 자동 갱신 아님)
REFRESH MATERIALIZED VIEW mv_daily_gmv;
--   (고급/무중단) REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_gmv;
--   갱신 전략: 리포트가 오후 3시 기준이면 매일 15:00 스케줄러(cron/pg_cron)로 REFRESH.

-- [4] MV 사용 — 같은 리포트를 사전 집계된 MV에서 조회 (튜닝 후)
EXPLAIN (ANALYZE, BUFFERS)
SELECT day, gmv
FROM mv_daily_gmv
ORDER BY day DESC
LIMIT 10;

-- [5] 결과 미리보기 & 행 수
SELECT day::date, gmv FROM mv_daily_gmv ORDER BY day DESC LIMIT 10;
SELECT count(*) AS mv_rows FROM mv_daily_gmv;

-- =====================================================================
-- 개선 요약:
--   MV 미사용(JOIN+SUM, 14,250행 집계): 약 8.5ms, Seq Scan×2 + HashAggregate
--   MV 사용(사전 집계 124행 조회)      : 약 0.04ms, Index Scan Backward
--   → 약 200배 단축(CLI 정상상태). 집계를 미리 계산해 전량 스캔·집계를 통째로 건너뜀.
--     리포트성(반복) 질의에 Materialized View가 효과적.
--   비용: 저장공간 + 갱신(REFRESH) 필요 → 데이터 변경 주기에 맞춰 갱신 스케줄 설계.
-- =====================================================================

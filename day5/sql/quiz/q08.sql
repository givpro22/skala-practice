-- =====================================================================
-- Q8) 효자상품 — 평점 4.5 이상 & 리뷰 50개 이상 (리뷰 많고 평가도 좋은 상품)
--   요구사항: HAVING avg(rating) >= 4.5 AND count(*) >= 50
--   선택 컬럼: product_id, product_name, avg_rating, review_cnt
-- ---------------------------------------------------------------------
-- [튜닝 전] reviews 전량 Seq Scan → products 조인 → HashAggregate + HAVING
-- =====================================================================
SET search_path = ecom, public;                    -- ecom 스키마 우선 탐색(lab.* 오조회 방지)

EXPLAIN (ANALYZE, BUFFERS)                          -- 실제 실행계획+수행시간+버퍼까지 측정
SELECT p.product_id, p.product_name,                 -- 상품 식별자/이름
       round(avg(r.rating), 2) AS avg_rating,        -- 상품별 평균 평점(소수2자리)
       count(*)                AS review_cnt         -- 상품별 리뷰 개수
FROM reviews r                                       -- 리뷰(평점/건수 집계 원천)
JOIN products p ON p.product_id = r.product_id       -- 상품명 얻기 위해 상품 연결
GROUP BY p.product_id, p.product_name                -- 상품 단위로 묶어 집계
HAVING avg(r.rating) >= 4.5 AND count(*) >= 50       -- 효자상품 조건: 고평점(4.5+) & 충분한 표본(리뷰 50+)
ORDER BY avg_rating DESC, review_cnt DESC;           -- 평점 높은 순, 동점이면 리뷰 많은 순

-- ---------------------------------------------------------------------
-- [튜닝] product_id로 그룹하고 rating만 필요하므로 커버링 인덱스:
--   CREATE INDEX idx_reviews_prod_rating ON reviews(product_id) INCLUDE (rating);
-- [튜닝 후] SET enable_seqscan=off 시 Index Only Scan(idx_reviews_prod_rating)로
--   heap 접근 없이 (product_id, rating)만 읽어 집계. 2,064행 규모라 절대시간은
--   Seq Scan(0.69ms)과 유사하지만, heap I/O 제거는 리뷰 폭증 시 확장성 확보.
-- =====================================================================
SET enable_seqscan = off;  -- Index Only Scan 계획 확인
EXPLAIN (ANALYZE, BUFFERS)                          -- 동일 쿼리, 커버링 인덱스 사용 계획 비교
SELECT p.product_id, p.product_name,                 -- 상품 식별자/이름
       round(avg(r.rating), 2) AS avg_rating,        -- 상품별 평균 평점(소수2자리)
       count(*)                AS review_cnt         -- 상품별 리뷰 개수
FROM reviews r                                       -- 리뷰(커버링 인덱스로 heap 없이 집계)
JOIN products p ON p.product_id = r.product_id       -- 상품명 얻기 위해 상품 연결
GROUP BY p.product_id, p.product_name                -- 상품 단위로 묶어 집계
HAVING avg(r.rating) >= 4.5 AND count(*) >= 50       -- 효자상품 조건: 고평점(4.5+) & 충분한 표본(리뷰 50+)
ORDER BY avg_rating DESC, review_cnt DESC;           -- 평점 높은 순, 동점이면 리뷰 많은 순
RESET enable_seqscan;                                -- 세션 설정 원복(옵티마이저 자동 판단 복귀)

-- 결과(전후 동일): 효자상품 12개 (avg 4.71~4.83, 리뷰 160~161개)

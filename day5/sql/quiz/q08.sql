-- =====================================================================
-- Q8) 효자상품 — 평점 4.5 이상 & 리뷰 50개 이상 (리뷰 많고 평가도 좋은 상품)
--   요구사항: HAVING avg(rating) >= 4.5 AND count(*) >= 50
--   선택 컬럼: product_id, product_name, avg_rating, review_cnt
-- ---------------------------------------------------------------------
-- [튜닝 전] reviews 전량 Seq Scan → products 조인 → HashAggregate + HAVING
-- =====================================================================
SET search_path = ecom, public;

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_id, p.product_name,
       round(avg(r.rating), 2) AS avg_rating,
       count(*)                AS review_cnt
FROM reviews r
JOIN products p ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name
HAVING avg(r.rating) >= 4.5 AND count(*) >= 50
ORDER BY avg_rating DESC, review_cnt DESC;

-- ---------------------------------------------------------------------
-- [튜닝] product_id로 그룹하고 rating만 필요하므로 커버링 인덱스:
--   CREATE INDEX idx_reviews_prod_rating ON reviews(product_id) INCLUDE (rating);
-- [튜닝 후] SET enable_seqscan=off 시 Index Only Scan(idx_reviews_prod_rating)로
--   heap 접근 없이 (product_id, rating)만 읽어 집계. 2,064행 규모라 절대시간은
--   Seq Scan(0.69ms)과 유사하지만, heap I/O 제거는 리뷰 폭증 시 확장성 확보.
-- =====================================================================
SET enable_seqscan = off;  -- Index Only Scan 계획 확인
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_id, p.product_name,
       round(avg(r.rating), 2) AS avg_rating,
       count(*)                AS review_cnt
FROM reviews r
JOIN products p ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name
HAVING avg(r.rating) >= 4.5 AND count(*) >= 50
ORDER BY avg_rating DESC, review_cnt DESC;
RESET enable_seqscan;

-- 결과(전후 동일): 효자상품 12개 (avg 4.71~4.83, 리뷰 160~161개)

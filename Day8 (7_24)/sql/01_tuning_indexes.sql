-- =====================================================================
-- 01. 튜닝용 인덱스 모음 (튜닝 후 실행계획을 위해 사전 생성)
--   * 각 인덱스가 어느 문항을 가속하는지 주석으로 명시
--   * 부분(partial)/커버링(covering) 인덱스를 상황에 맞게 선택
-- =====================================================================
SET search_path = ecom, public;

-- [Q1, Q3, Q10] 매출 대상 상태(paid/shipped/delivered)만 담고 order_ts로 정렬한 부분 인덱스
--   → 기간 필터가 선택적일 때 Seq Scan 대신 (Bitmap) Index Scan 유도
CREATE INDEX IF NOT EXISTS idx_orders_rev_ts
  ON orders(order_ts)
  WHERE order_status IN ('paid','shipped','delivered');

-- [Q6] 고객별 재구매 탐색(LATERAL)에서 인덱스만으로 프로브하도록 복합 부분 인덱스
CREATE INDEX IF NOT EXISTS idx_orders_cust_rev_ts
  ON orders(customer_id, order_ts)
  WHERE order_status IN ('paid','shipped','delivered');

-- [Q4] order_items 조인/집계에 필요한 컬럼만 담은 커버링 인덱스(Index Only Scan 후보)
CREATE INDEX IF NOT EXISTS idx_oi_order_prod_cov
  ON order_items(order_id, product_id, line_total);

-- [Q7] "재고 < 재주문점" 조건을 그대로 담은 부분 인덱스 (곧 품절 위험 상품만 인덱싱)
CREATE INDEX IF NOT EXISTS idx_inventory_low_stock
  ON inventory(product_id)
  WHERE qty_on_hand < reorder_point;

-- [Q8] 효자상품 평점 집계용 커버링 인덱스 (product_id로 그룹, rating은 INCLUDE)
CREATE INDEX IF NOT EXISTS idx_reviews_prod_rating
  ON reviews(product_id) INCLUDE (rating);

-- 통계 최신화 (옵티마이저가 정확한 카디널리티로 계획을 세우도록)
VACUUM ANALYZE orders;
VACUUM ANALYZE order_items;
VACUUM ANALYZE inventory;
VACUUM ANALYZE reviews;

-- (튜닝 전 baseline 재현이 필요하면 아래로 제거)
-- DROP INDEX IF EXISTS idx_orders_rev_ts, idx_orders_cust_rev_ts,
--   idx_oi_order_prod_cov, idx_inventory_low_stock, idx_reviews_prod_rating;

-- =====================================================================
-- Day5 종합실습-4 : ecommerce 매출 분석 및 성능 튜닝
-- 00. 실행 환경 확인
-- DB: skala_db / 스키마: ecom / PostgreSQL 17.10
-- =====================================================================
SET search_path = ecom, public;

-- 접속 정보
\conninfo

-- ecom 스키마 테이블 목록
\dt ecom.*

-- 테이블별 행 수 (분석 대상 데이터 규모 확인)
SELECT 'customers'   AS tbl, count(*) FROM customers
UNION ALL SELECT 'products',    count(*) FROM products
UNION ALL SELECT 'orders',      count(*) FROM orders
UNION ALL SELECT 'order_items', count(*) FROM order_items
UNION ALL SELECT 'payments',    count(*) FROM payments
UNION ALL SELECT 'shipments',   count(*) FROM shipments
UNION ALL SELECT 'reviews',     count(*) FROM reviews
UNION ALL SELECT 'inventory',   count(*) FROM inventory
ORDER BY 1;

-- 주문 상태 분포 (매출 집계는 paid/shipped/delivered 만 포함)
SELECT order_status, count(*) FROM orders GROUP BY order_status ORDER BY 2 DESC;

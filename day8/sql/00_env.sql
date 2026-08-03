-- =====================================================================
-- Day8 종합실습-4 : ecommerce 매출 분석 및 성능 튜닝
-- 00. 실행 환경 확인
-- DB: skala_db / 스키마: ecom / PostgreSQL 17.10
-- =====================================================================
SET search_path = ecom, public;

-- 접속 정보
\conninfo

-- ecom 스키마 테이블 목록
\dt ecom.*

-- 테이블별 행 수 (분석 대상 데이터 규모 확인 → 옵티마이저 계획 판단 근거)
SELECT 'customers'   AS tbl, count(*) FROM customers          -- 고객 마스터
UNION ALL SELECT 'products',    count(*) FROM products        -- 상품 마스터
UNION ALL SELECT 'orders',      count(*) FROM orders          -- 주문 헤더(필터 대상 핵심 테이블)
UNION ALL SELECT 'order_items', count(*) FROM order_items     -- 주문 상세(매출 집계의 최대 테이블)
UNION ALL SELECT 'payments',    count(*) FROM payments        -- 결제
UNION ALL SELECT 'shipments',   count(*) FROM shipments       -- 배송
UNION ALL SELECT 'reviews',     count(*) FROM reviews         -- 리뷰(Q8 평점 집계)
UNION ALL SELECT 'inventory',   count(*) FROM inventory       -- 재고(Q7 품절 위험)
ORDER BY 1;                                                   -- 테이블명 알파벳순 정렬

-- 주문 상태 분포 (매출 집계는 paid/shipped/delivered 만 포함)
SELECT order_status, count(*)          -- 상태별 주문 건수 → 매출상태 비중 파악
FROM orders
GROUP BY order_status                  -- 상태값으로 그룹핑
ORDER BY 2 DESC;                       -- 건수 많은 상태부터

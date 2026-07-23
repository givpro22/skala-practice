-- ============================================================
-- 8. 종합실습 - 1 : 학사관리시스템 DB 설계 → 구축 → 조회
-- 01. 데이터베이스 및 스키마 생성
-- 실행: psql postgres -f sql/01_create_database.sql
-- ============================================================

-- 과정 기간 내 계속 활용할 데이터베이스 생성
-- (종합실습 2/3/4에서 동일 DB에 스키마를 추가하여 재사용)
CREATE DATABASE skala_edu
    ENCODING 'UTF8'
    TEMPLATE template0;

COMMENT ON DATABASE skala_edu IS 'SKALA 교육과정 실습용 DB (종합실습 1~4 공용)';

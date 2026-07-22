-- [단계 4] CREATE TABLE 결과 확인 — 테이블별 제약조건 목록
SET search_path TO academy;
SELECT c.relname  AS table_name,
       con.conname AS constraint_name,
       CASE con.contype
            WHEN 'p' THEN 'PRIMARY KEY'
            WHEN 'f' THEN 'FOREIGN KEY'
            WHEN 'u' THEN 'UNIQUE'
            WHEN 'c' THEN 'CHECK'
       END AS constraint_type
FROM   pg_constraint con
JOIN   pg_class c    ON c.oid = con.conrelid
JOIN   pg_namespace n ON n.oid = c.relnamespace
WHERE  n.nspname = 'academy'
ORDER BY c.relname, con.contype;

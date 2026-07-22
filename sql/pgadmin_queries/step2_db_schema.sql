-- [단계 2] CREATE DATABASE / CREATE SCHEMA 확인
-- (\l, \dn은 psql 전용이라 pgAdmin에서는 카탈로그 조회로 확인)
SELECT d.datname  AS database,
       s.nspname  AS schema,
       pg_get_userbyid(s.nspowner) AS owner
FROM   pg_database d
JOIN   pg_namespace s ON d.datname = current_database()
WHERE  d.datname = 'skala_edu'
  AND  s.nspname IN ('academy', 'public');

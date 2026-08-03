-- [단계 1] PostgreSQL 접속 확인 (pgAdmin Query Tool)
SET search_path TO academy;
SELECT version(),
       current_database() AS db,
       current_user       AS "user",
       current_schema     AS schema;

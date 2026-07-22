-- [단계 5] INSERT INTO 결과 확인 — 테이블별 건수 (전부 10건 이상)
SET search_path TO academy;
SELECT 'department' AS table_name, COUNT(*) FROM department
UNION ALL SELECT 'professor',  COUNT(*) FROM professor
UNION ALL SELECT 'student',    COUNT(*) FROM student
UNION ALL SELECT 'course',     COUNT(*) FROM course
UNION ALL SELECT 'enroll',     COUNT(*) FROM enroll;

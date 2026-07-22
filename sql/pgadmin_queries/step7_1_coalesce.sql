-- [단계 7-1] COALESCE — 연락처 NULL을 '연락처 미등록'으로 표시
SET search_path TO academy;
SELECT student_id,
       student_name,
       COALESCE(phone, '연락처 미등록') AS phone_display
FROM   student
ORDER BY student_id;

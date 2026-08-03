-- [단계 6] SELECT + WHERE + ORDER BY 기초 조회
SET search_path TO academy;
SELECT student_id, student_name, grade, status
FROM   student
WHERE  status = '재학'
  AND  grade >= 2
ORDER BY grade DESC, student_name ASC;

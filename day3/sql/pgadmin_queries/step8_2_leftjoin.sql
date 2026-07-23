-- [단계 8-2] (심화) LEFT JOIN + GROUP BY + HAVING — 수강신청 없는 학생
SET search_path TO academy;
SELECT s.student_id,
       s.student_name,
       s.status,
       COALESCE(COUNT(e.enroll_id), 0) AS enroll_count
FROM   student s
LEFT JOIN enroll e ON e.student_id = s.student_id
GROUP BY s.student_id, s.student_name, s.status
HAVING COUNT(e.enroll_id) = 0
ORDER BY s.student_id;

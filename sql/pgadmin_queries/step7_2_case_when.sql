-- [단계 7-2] CASE WHEN — 성적 등급 변환 (A/B/C/F, NULL은 미평가)
SET search_path TO academy;
SELECT e.enroll_id,
       s.student_name,
       c.course_name,
       e.score,
       COALESCE(
           CASE
               WHEN e.score >= 90 THEN 'A'
               WHEN e.score >= 80 THEN 'B'
               WHEN e.score >= 70 THEN 'C'
               WHEN e.score IS NOT NULL THEN 'F'
           END, '미평가'
       ) AS grade_letter
FROM   enroll e
JOIN   student s ON s.student_id = e.student_id
JOIN   course  c ON c.course_id  = e.course_id
ORDER BY e.enroll_id;

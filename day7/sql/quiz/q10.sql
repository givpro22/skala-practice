-- Q10. "모든 학생 기준"으로 과목 분포 → LEFT JOIN + 집계 (미수강은 NULL 그룹으로 표시)
SELECT e.course, COUNT(s.student_id) AS student_count
FROM   student s
LEFT JOIN enroll e ON e.student_id = s.student_id
GROUP BY e.course
ORDER BY e.course NULLS LAST;

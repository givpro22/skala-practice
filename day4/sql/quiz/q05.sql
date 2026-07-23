-- Q5. 한 번도 수강하지 않은 학생 목록 (LEFT JOIN + IS NULL)
SELECT s.student_id, s.name
FROM   student s
LEFT JOIN enroll e ON e.student_id = s.student_id
WHERE  e.student_id IS NULL
ORDER BY s.student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

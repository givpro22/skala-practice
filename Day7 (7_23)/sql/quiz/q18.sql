-- Q18. 한 번도 수강하지 않은 학생 (NOT EXISTS)
SELECT s.student_id, s.name
FROM   student s
WHERE  NOT EXISTS (SELECT 1 FROM enroll e WHERE e.student_id = s.student_id)
ORDER BY s.student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

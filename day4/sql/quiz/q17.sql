-- Q17. 수강(enroll) 기록이 있는 학생만 (EXISTS)
SELECT s.student_id, s.name
FROM   student s
WHERE  EXISTS (SELECT 1 FROM enroll e WHERE e.student_id = s.student_id)
ORDER BY s.student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

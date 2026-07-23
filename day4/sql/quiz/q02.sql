-- Q2. 모든 학생 기준으로 수강을 붙이고, 과목(없으면 NULL)까지 보이기 (LEFT JOIN)
SELECT s.student_id, s.name, e.course
FROM   student s
LEFT JOIN enroll e ON e.student_id = s.student_id
ORDER BY s.student_id, e.course
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

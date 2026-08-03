-- Q11. DB 과목을 듣지 않은 모든 학생을 나열 (NOT EXISTS)
SELECT s.student_id, s.name
FROM   student s
WHERE  NOT EXISTS (
  SELECT 1 FROM enroll e
  WHERE  e.student_id = s.student_id AND e.course = 'DB'
)
ORDER BY s.student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

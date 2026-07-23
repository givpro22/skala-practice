-- Q6. 한 과목 이상 수강한 학생 목록 (중복 제거)
SELECT DISTINCT s.student_id, s.name
FROM   student s
JOIN   enroll  e ON e.student_id = s.student_id
ORDER BY s.student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

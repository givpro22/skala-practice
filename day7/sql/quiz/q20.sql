-- Q20. CS 학과 학생 또는 DB 과목을 수강한 학생 목록 (UNION으로 중복 제거)
SELECT s.student_id, s.name
FROM   student s
WHERE  s.major = 'CS'
UNION
SELECT s.student_id, s.name
FROM   student s
JOIN   enroll e ON e.student_id = s.student_id
WHERE  e.course = 'DB'
ORDER BY student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

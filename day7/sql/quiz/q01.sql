-- Q1. 학생과 수강을 INNER JOIN하여 수강 존재 학생의 과목/성적을 조회
SELECT s.student_id, s.name, e.course, e.grade
FROM   student s
JOIN   enroll  e ON e.student_id = s.student_id
ORDER BY s.student_id, e.course
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

-- Q16. 자신의 학과 평균 GPA보다 높은 학생 (Correlated subquery)
SELECT s.student_id, s.name, s.major, s.gpa
FROM   student s
WHERE  s.gpa > (SELECT AVG(s2.gpa) FROM student s2 WHERE s2.major = s.major)
ORDER BY s.student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

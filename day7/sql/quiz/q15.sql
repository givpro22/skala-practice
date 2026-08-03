-- Q15. 평균 GPA보다 높은 학생 (WHERE 서브쿼리)
SELECT student_id, name, gpa
FROM   student
WHERE  gpa > (SELECT AVG(gpa) FROM student)
ORDER BY student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

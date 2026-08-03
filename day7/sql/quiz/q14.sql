-- Q14. 스칼라 서브쿼리(SELECT 절)로 학생 + 소속 학과명 붙이기
SELECT s.student_id,
       s.name,
       (SELECT s2.major FROM student s2 WHERE s2.student_id = s.student_id) AS major
FROM   student s
ORDER BY s.student_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

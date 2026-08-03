-- Q3. 수강이 기준. 학생이 없으면 학생 정보가 NULL (RIGHT JOIN)
SELECT e.student_id, e.course, e.grade, s.name
FROM   student s
RIGHT JOIN enroll e ON e.student_id = s.student_id
ORDER BY (s.student_id IS NULL) DESC,   -- 학생 정보 없는 행(유령)이 위로 오도록
         e.student_id, e.course
LIMIT 5;   -- 출력 확인용 (전체 2,302행)

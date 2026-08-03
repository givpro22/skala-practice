-- Q4. 학생/수강 모두 포함 (FULL OUTER JOIN)
SELECT s.student_id AS s_id, s.name, e.student_id AS e_id, e.course
FROM   student s
FULL OUTER JOIN enroll e ON e.student_id = s.student_id
ORDER BY (s.student_id IS NULL) DESC,   -- 비매칭 행(유령 수강, 미수강 학생)이 위로 오도록
         (e.student_id IS NULL) DESC,
         COALESCE(s.student_id, e.student_id), e.course
LIMIT 5;   -- 출력 확인용 (전체 2,402행)

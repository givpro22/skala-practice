-- Q23. 학과별 GPA 상위 3명 — Window Function (서브쿼리 방식과 CTE 방식 모두 작성)
--      ROW_NUMBER(동점 시 student_id 2차) + RANK/DENSE_RANK 비교 + COUNT() OVER

-- [방식 1] 서브쿼리 방식
SELECT student_id, name, major, gpa, rn, rnk, drnk, total_in_major
FROM (
  SELECT student_id, name, major, gpa,
         ROW_NUMBER() OVER (PARTITION BY major ORDER BY gpa DESC, student_id) AS rn,
         RANK()       OVER (PARTITION BY major ORDER BY gpa DESC)             AS rnk,
         DENSE_RANK() OVER (PARTITION BY major ORDER BY gpa DESC)             AS drnk,
         COUNT(*)     OVER (PARTITION BY major)                               AS total_in_major
  FROM student
) x
WHERE rn <= 3
ORDER BY major, rn;

-- [방식 2] CTE 방식
WITH ranked AS (
  SELECT student_id, name, major, gpa,
         ROW_NUMBER() OVER (PARTITION BY major ORDER BY gpa DESC, student_id) AS rn,
         RANK()       OVER (PARTITION BY major ORDER BY gpa DESC)             AS rnk,
         DENSE_RANK() OVER (PARTITION BY major ORDER BY gpa DESC)             AS drnk,
         COUNT(*)     OVER (PARTITION BY major)                               AS total_in_major
  FROM student
)
SELECT student_id, name, major, gpa, rn, rnk, drnk, total_in_major
FROM   ranked
WHERE  rn <= 3
ORDER BY major, rn;

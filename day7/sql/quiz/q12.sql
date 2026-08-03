-- Q12. 과목별 매니저 운영 책임 가정: course_owner(course, manager_id) 생성 후
--      과목별 수강 인원 + 책임 매니저 이름 리포트
DROP TABLE IF EXISTS course_owner;

CREATE TABLE course_owner AS
SELECT c.course,
       m.emp_id AS manager_id
FROM  (SELECT DISTINCT course FROM enroll) c
JOIN LATERAL (
  SELECT emp_id
  FROM   emp
  WHERE  name LIKE 'Mgr\_%'
  ORDER  BY emp_id
  OFFSET (ascii(right(c.course, 1)) % 10) LIMIT 1   -- 과목→매니저 임의 매핑
) m ON TRUE;

SELECT co.course,
       COUNT(e.student_id) AS enroll_count,
       m.name              AS owner_manager
FROM   course_owner co
LEFT JOIN enroll e ON e.course = co.course
JOIN   emp m ON m.emp_id = co.manager_id
GROUP BY co.course, m.name
ORDER BY co.course;

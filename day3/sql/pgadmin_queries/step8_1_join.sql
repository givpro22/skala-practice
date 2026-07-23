-- [단계 8-1] 수강신청 교차 테이블 JOIN — 5개 테이블 통합 조회
SET search_path TO academy;
SELECT s.student_name          AS 학생,
       d.dept_name             AS 소속학과,
       c.course_name           AS 수강과목,
       c.credits               AS 학점,
       p.prof_name             AS 담당교수,
       e.enroll_date           AS 신청일
FROM   enroll e
JOIN   student    s ON s.student_id = e.student_id
JOIN   course     c ON c.course_id  = e.course_id
JOIN   professor  p ON p.prof_id    = c.prof_id
JOIN   department d ON d.dept_id    = s.dept_id
ORDER BY s.student_name, c.course_name;

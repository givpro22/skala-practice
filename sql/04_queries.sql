-- ============================================================
-- 8. 종합실습 - 1 : 학사관리시스템 DB 설계 → 구축 → 조회
-- 04. 문항별 조회 쿼리
-- 실행: psql skala_edu -f sql/04_queries.sql
-- ============================================================

SET search_path TO academy;

-- ------------------------------------------------------------
-- Q1. PostgreSQL 접속 확인 (버전 / 현재 DB / 현재 사용자)
-- ------------------------------------------------------------
SELECT version();
SELECT current_database(), current_user, current_schema;

-- ------------------------------------------------------------
-- Q2. SELECT + WHERE + ORDER BY 기초 조회
--     : 재학 중인 2학년 이상 학생을 학년 내림차순, 이름 오름차순 조회
-- ------------------------------------------------------------
SELECT student_id, student_name, grade, status
FROM   student
WHERE  status = '재학'
  AND  grade >= 2
ORDER BY grade DESC, student_name ASC;

-- ------------------------------------------------------------
-- Q3. COALESCE 활용
--     : 연락처가 NULL인 학생은 '연락처 미등록'으로 표시
-- ------------------------------------------------------------
SELECT student_id,
       student_name,
       COALESCE(phone, '연락처 미등록') AS phone_display
FROM   student
ORDER BY student_id;

-- ------------------------------------------------------------
-- Q4. CASE WHEN 활용
--     : 수강 성적을 등급(A/B/C/F)으로 변환, 미평가는 COALESCE로 처리
-- ------------------------------------------------------------
SELECT e.enroll_id,
       s.student_name,
       c.course_name,
       e.score,
       COALESCE(
           CASE
               WHEN e.score >= 90 THEN 'A'
               WHEN e.score >= 80 THEN 'B'
               WHEN e.score >= 70 THEN 'C'
               WHEN e.score IS NOT NULL THEN 'F'
           END, '미평가'
       ) AS grade_letter
FROM   enroll e
JOIN   student s ON s.student_id = e.student_id
JOIN   course  c ON c.course_id  = e.course_id
ORDER BY e.enroll_id;

-- ------------------------------------------------------------
-- Q5. 날짜 함수 활용
--     : 학생의 나이(AGE), 입학 연도(EXTRACT), 재학 일수 계산
-- ------------------------------------------------------------
SELECT student_name,
       birth_date,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))  AS age,
       EXTRACT(YEAR FROM admission_date)                 AS admission_year,
       CURRENT_DATE - admission_date                     AS days_since_admission
FROM   student
ORDER BY age DESC;

-- ------------------------------------------------------------
-- Q6. 수강신청 교차 테이블 JOIN 조회
--     : 학생 - 수강신청 - 과목 - 담당교수 - 개설학과 연결
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Q7. (심화) LEFT JOIN — 수강신청 내역이 없는 학생 찾기
-- ------------------------------------------------------------
SELECT s.student_id,
       s.student_name,
       s.status,
       COALESCE(COUNT(e.enroll_id), 0) AS enroll_count
FROM   student s
LEFT JOIN enroll e ON e.student_id = s.student_id
GROUP BY s.student_id, s.student_name, s.status
HAVING COUNT(e.enroll_id) = 0
ORDER BY s.student_id;

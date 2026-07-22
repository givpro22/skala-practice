-- [단계 7-3] 날짜 함수 — 나이(AGE), 입학연도(EXTRACT), 재학일수
SET search_path TO academy;
SELECT student_name,
       birth_date,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))  AS age,
       EXTRACT(YEAR FROM admission_date)                 AS admission_year,
       CURRENT_DATE - admission_date                     AS days_since_admission
FROM   student
ORDER BY age DESC;

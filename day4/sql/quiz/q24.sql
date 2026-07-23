-- Q24. LAG()로 학생별 이전 수강 과목 대비 성적 변화 (A=4, B=3, C=2, D=1)
--      diff(현재-이전) + 상승/유지/하락 표시 + 학생별 최고-최저 차(score_range)
SELECT student_id, course, score, prev_score,
       diff,
       CASE WHEN diff > 0 THEN '상승'
            WHEN diff = 0 THEN '유지'
            WHEN diff < 0 THEN '하락'
       END AS trend,
       score_range
FROM (
  SELECT student_id, course, score,
         LAG(score) OVER (PARTITION BY student_id ORDER BY course)  AS prev_score,
         score - LAG(score) OVER (PARTITION BY student_id ORDER BY course) AS diff,
         MAX(score) OVER (PARTITION BY student_id)
           - MIN(score) OVER (PARTITION BY student_id)              AS score_range
  FROM (
    SELECT student_id, course,
           CASE grade WHEN 'A' THEN 4 WHEN 'B' THEN 3
                      WHEN 'C' THEN 2 WHEN 'D' THEN 1 END AS score
    FROM enroll
  ) g
) w
ORDER BY student_id, course
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

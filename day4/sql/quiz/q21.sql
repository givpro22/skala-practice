-- Q21. 학과별·GPA 구간별 인원 집계 + ROLLUP 소계/총계
--      - gpa_tier 파생 컬럼(3.0 미만 / 3.0~3.5 / 3.5 초과)
--      - GROUP BY ROLLUP(major, gpa_tier), GROUPING(major)으로 '전체' 라벨
--      - 소계 행은 하단 정렬
SELECT CASE WHEN GROUPING(t.major)    = 1 THEN '전체' ELSE t.major    END AS major,
       CASE WHEN GROUPING(t.gpa_tier) = 1 THEN '소계' ELSE t.gpa_tier END AS gpa_tier,
       COUNT(*) AS student_count
FROM (
  SELECT major,
         CASE WHEN gpa < 3.0 THEN '3.0 미만'
              WHEN gpa <= 3.5 THEN '3.0~3.5'
              ELSE '3.5 초과'
         END AS gpa_tier
  FROM student
) t
GROUP BY ROLLUP(t.major, t.gpa_tier)
ORDER BY GROUPING(t.major), t.major, GROUPING(t.gpa_tier), t.gpa_tier;

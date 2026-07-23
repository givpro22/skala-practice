-- Q13. 학생 × 과목 전체 조합(CROSS JOIN)으로 "학생별 과목 추천 후보" 생성, 샘플 100건만 조회
SELECT s.student_id, s.name, c.course
FROM   student s
CROSS JOIN (SELECT DISTINCT course FROM enroll) c
ORDER BY s.student_id, c.course
LIMIT 100;

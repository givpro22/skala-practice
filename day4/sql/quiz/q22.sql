-- Q22. WITH RECURSIVE 조직 트리: 모든 직원의 계층 경로(path)와 깊이(depth)
WITH RECURSIVE org AS (
  SELECT emp_id, name, manager_id, 0 AS depth, name::text AS path
  FROM   emp
  WHERE  manager_id IS NULL                     -- CEO에서 시작
  UNION ALL
  SELECT e.emp_id, e.name, e.manager_id, o.depth + 1, o.path || ' > ' || e.name
  FROM   emp e
  JOIN   org o ON o.emp_id = e.manager_id
)
SELECT emp_id, name, depth, path
FROM   org
ORDER BY path
LIMIT 5;   -- 출력 확인용 (전체 311행)

-- Q22-2. 매니저별 직속 부하 직원 수 (direct_reports)
SELECT m.name AS manager, COUNT(*) AS direct_reports
FROM   emp e
JOIN   emp m ON m.emp_id = e.manager_id
GROUP BY m.name
ORDER BY direct_reports DESC, m.name;

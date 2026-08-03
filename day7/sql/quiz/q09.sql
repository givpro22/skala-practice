-- Q9. 모든 직원과 그 매니저 이름 (CEO는 매니저가 없어 NULL, LEFT SELF JOIN)
SELECT e.name AS employee, m.name AS manager
FROM   emp e
LEFT JOIN emp m ON m.emp_id = e.manager_id
ORDER BY e.emp_id
LIMIT 5;   -- 출력 확인용 (전체 311행)

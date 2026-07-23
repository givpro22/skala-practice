-- Q8. 총액 상위 10명과 금액
SELECT c.customer_name, SUM(o.amount) AS total_amount
FROM   customers c
JOIN   orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_amount DESC
LIMIT 10;

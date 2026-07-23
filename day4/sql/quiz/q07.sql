-- Q7. 고객별 주문건수/총액
SELECT c.customer_id, c.customer_name, COUNT(*) AS order_count, SUM(o.amount) AS total_amount
FROM   customers c
JOIN   orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY c.customer_id
LIMIT 5;   -- 출력 확인용 (전체 행 수는 리포트에 별도 표기)

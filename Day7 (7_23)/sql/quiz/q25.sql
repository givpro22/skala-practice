-- Q25. orders를 order_id 순으로 정렬하여 누적 주문금액과 3개 주문 이동평균 계산 (ROWS BETWEEN)
--      + customer_id별 PARTITION 고객별 누적 구매금액
SELECT order_id, customer_id, amount,
       SUM(amount) OVER (ORDER BY order_id
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
       ROUND(AVG(amount) OVER (ORDER BY order_id
                         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)     AS moving_avg_3,
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_id
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cust_running_total
FROM   orders
ORDER BY order_id
LIMIT 5;   -- 출력 확인용 (전체 3,000행)

-- Q25-2. 누적합이 전체 합의 50%를 초과하는 첫 번째 order_id
SELECT order_id, running_total, total_sum
FROM (
  SELECT order_id,
         SUM(amount) OVER (ORDER BY order_id
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
         SUM(amount) OVER () AS total_sum
  FROM orders
) t
WHERE  running_total > total_sum * 0.5
ORDER BY order_id
LIMIT 1;

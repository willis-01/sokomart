--Section C — Advanced aggregation with subqueries
select tier, COUNT(*) AS customer_count, ROUND(MIN(total_spent), 2) AS min_spent,ROUND(MAX(total_spent), 2) AS max_spent,
    ROUND(AVG(total_spent), 2) AS avg_spent,
    ROUND(SUM(total_spent) * 100.0 /
        (SELECT SUM(oi.quantity * oi.unit_price)
         FROM sokomart.orders o
         JOIN sokomart.order_items oi
             ON o.order_id = oi.order_id
         WHERE o.order_status = 'completed'),
        2
    ) AS revenue_share_pct
FROM (
    SELECT  customer_id,total_spent,
        CASE
            WHEN total_spent >= 1000000 THEN 'Platinum'
            WHEN total_spent >= 500000 THEN 'Gold'
            WHEN total_spent >= 100000 THEN 'Silver'
            ELSE 'Bronze'
        END AS tier
    FROM (
        SELECT
            o.customer_id,
            SUM(oi.quantity * oi.unit_price) AS total_spent
        FROM sokomart.orders o
        JOIN sokomart.order_items oi
            ON o.order_id = oi.order_id
        WHERE o.order_status = 'completed'
        GROUP BY o.customer_id
    ) AS customer_revenue
) AS customer_tiers
GROUP BY tier
ORDER BY
    CASE tier
        WHEN 'Platinum' THEN 1
        WHEN 'Gold' THEN 2
        WHEN 'Silver' THEN 3
        WHEN 'Bronze' THEN 4
    END;

--Question 12 — What did Mombasa buy in October? (Medium)
--Customer shopping lists
SELECT c.customer_id,CONCAT(c.first_name, ' ', c.last_name) AS full_name,COUNT(DISTINCT p.product_id) AS product_count,
    STRING_AGG(
        DISTINCT p.product_name,
        '; ' ORDER BY p.product_name
    ) AS products_ordered
FROM sokomart.customers c
JOIN sokomart.orders o ON c.customer_id = o.customer_id
JOIN sokomart.order_items oi ON o.order_id = oi.order_id
JOIN sokomart.products p ON oi.product_id = p.product_id
WHERE c.county = 'Mombasa'
  AND o.order_status <> 'cancelled'
  AND o.order_date >= '2026-10-01'
  AND o.order_date < '2026-11-01'
  AND EXISTS (
      SELECT 1
      FROM sokomart.orders o2
      WHERE o2.customer_id = c.customer_id
        AND o2.order_status <> 'cancelled'
        AND o2.order_date >= '2026-10-01'
        AND o2.order_date < '2026-11-01'
  )
GROUP BY c.customer_id,c.first_name, c.last_name
ORDER by product_count DESC,c.customer_id;

--Question 13 — Payment health by method, 2026 (Medium)
WITH payments_2026 AS (
    select payment_method, payment_status,amount
    FROM sokomart.payments
    WHERE payment_date >= '2026-01-01'
      AND payment_date < '2027-01-01'
)
select payment_method,COUNT(*) AS total_payments,
    COUNT(*) FILTER (WHERE payment_status = 'successful'
    ) AS successful,
    COUNT(*) FILTER ( WHERE payment_status = 'failed'
    ) AS failed,
    COUNT(*) FILTER ( WHERE payment_status = 'pending'
    ) AS pending,
    ROUND(COUNT(*) FILTER ( WHERE payment_status = 'successful' ) * 100.0 / COUNT(*), 2
    ) AS success_rate_pct,
    ROUND( SUM(amount) FILTER (
   WHERE payment_status = 'failed'),2
    ) AS failed_amount
FROM payments_2026
GROUP BY payment_method
ORDER BY total_payments DESC;

--Question 14 — Which departments carry the profit? (Medium)
WITH category_profit AS (
    SELECT p.category,SUM(oi.quantity * oi.unit_price) AS revenue,SUM(oi.quantity * (oi.unit_price - p.cost_price)) AS gross_profit
    FROM sokomart.products p
    JOIN sokomart.order_items oi ON p.product_id = oi.product_id
    JOIN sokomart.orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'AND o.order_date >= '2025-01-01'AND o.order_date < '2026-01-01'
    GROUP BY p.category
)
select category, ROUND(revenue, 2) AS revenue,ROUND(gross_profit, 2) AS gross_profit,
    ROUND(gross_profit * 100.0 / NULLIF(revenue, 0), 2) AS margin_pct,
    ROUND(
        (SELECT AVG(gross_profit)
         FROM category_profit),2
    ) AS avg_category_gross_profit,
    ROUND(
        (
            gross_profit -
            (SELECT AVG(gross_profit)
             FROM category_profit)
        ) * 100.0 /
        NULLIF(
            (SELECT AVG(gross_profit)
             FROM category_profit),
            0 ), 2
    ) AS pct_above_avg
FROM category_profit
WHERE gross_profit > (
    SELECT AVG(gross_profit)
    FROM category_profit
)
ORDER BY gross_profit DESC;
























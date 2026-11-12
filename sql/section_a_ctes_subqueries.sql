--Question 1 — Big spenders of 2025 (Medium)
WITH customer_2025_revenue AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        c.county,
        SUM(
            oi.quantity * oi.unit_price *
            (1 - COALESCE(oi.discount, 0) / 100.0)
        ) AS total_spent_2025
    FROM sokomart.customers c
    INNER JOIN sokomart.orders o
        ON c.customer_id = o.customer_id
    INNER JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-01-01'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.county
)

SELECT
    customer_id,
    full_name,
    county,
    ROUND(total_spent_2025, 2) AS total_spent_2025,

    ROUND((
        SELECT AVG(total_spent_2025)
        FROM customer_2025_revenue
    ), 2) AS avg_spent_2025,

    ROUND(
        total_spent_2025 -
        (
            SELECT AVG(total_spent_2025)
            FROM customer_2025_revenue
        ),
        2
    ) AS amount_above_avg

FROM customer_2025_revenue
WHERE total_spent_2025 > (
    SELECT AVG(total_spent_2025)
    FROM customer_2025_revenue
)
ORDER BY total_spent_2025 DESC;


--Question 2 — Premium-priced products (Medium)
--Query 1: Active products priced above their category average
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,

    ROUND((
        SELECT AVG(p2.unit_price)
        FROM sokomart.products p2
        WHERE p2.category = p.category
    ), 2) AS category_avg_price,

    ROUND(
        p.unit_price - (
            SELECT AVG(p2.unit_price)
            FROM sokomart.products p2
            WHERE p2.category = p.category
        ), 2
    ) AS price_gap

FROM sokomart.products p
WHERE p.product_status = 'active'
  AND p.unit_price > (
      SELECT AVG(p2.unit_price)
      FROM sokomart.products p2
      WHERE p2.category = p.category
  )
ORDER BY
    p.category,
    price_gap DESC;
--Count qualifying products per category
SELECT
    p.category,
    COUNT(*) AS products_above_category_average
FROM sokomart.products p
WHERE p.product_status = 'active'
  AND p.unit_price > (
      SELECT AVG(p2.unit_price)
      FROM sokomart.products p2
      WHERE p2.category = p.category
  )
GROUP BY p.category
ORDER BY p.category;

--Question 3 — 2026 monthly profit and loss (Medium)
WITH completed_order_lines AS (
    -- CTE 1: Get completed order lines and calculate revenue and cost
    select DATE_TRUNC('month', o.order_date)::DATE AS month,
        oi.quantity * oi.unit_price AS line_revenue,
        oi.quantity * p.cost_price AS line_cost
    FROM sokomart.orders o
    INNER JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    INNER JOIN sokomart.products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'completed'
      AND o.order_date >= '2026-01-01'
      AND o.order_date < '2026-11-01'
),
monthly_totals AS (
    -- CTE 2: Calculate monthly revenue and cost
    select month,SUM(line_revenue) AS revenue,SUM(line_cost) AS cost
    FROM completed_order_lines
    GROUP BY month
),
monthly_profit AS (
    -- CTE 3: Calculate gross profit
    SELECT month,revenue,cost, revenue - cost AS gross_profit
    FROM monthly_totals
),
monthly_pnl AS (
    -- CTE 4: Calculate gross profit margin
    select month, revenue,cost,gross_profit,
        case
            when revenue = 0 THEN 0
            else (gross_profit / revenue) * 100
        END AS margin_pct
    from monthly_profit
)
-- Final output
select TO_CHAR(month, 'Mon YYYY') AS month,ROUND(revenue, 2) AS revenue,
    ROUND(cost, 2) AS cost,ROUND(gross_profit, 2) AS gross_profit,
    ROUND(margin_pct, 2) AS margin_pct
FROM monthly_pnl
ORDER BY month;

--Question 4 — Cross-category shoppers in Nakuru (Medium)
--Nakuru customers who purchased from 3 or more categories
select c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS full_name, c.county,
    customer_summary.category_count, ROUND(customer_summary.total_spent, 2) AS total_spent
FROM sokomart.customers c
INNER JOIN (
    select o.customer_id, COUNT(DISTINCT p.category) AS category_count,
        SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM sokomart.orders o
    INNER JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    INNER JOIN sokomart.products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
) AS customer_summary
    ON c.customer_id = customer_summary.customer_id
WHERE c.county = 'Nakuru'
  AND customer_summary.category_count >= 3
ORDER BY
    customer_summary.category_count DESC,
    customer_summary.total_spent DESC;
--Summary of qualifying customers
select COUNT(*) AS qualifying_customers,
    COUNT(*) FILTER (WHERE customer_summary.category_count = 5
    ) AS customers_bought_all_five_categories
FROM sokomart.customers c
INNER JOIN (
    select o.customer_id,COUNT(DISTINCT p.category) AS category_count
    FROM sokomart.orders o
    INNER JOIN sokomart.order_items oi ON o.order_id = oi.order_id
    INNER JOIN sokomart.products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'completed'
    GROUP BY o.customer_id
) AS customer_summary ON c.customer_id = customer_summary.customer_id
WHERE c.county = 'Nakuru'
  AND customer_summary.category_count >= 3;

--Question 5 — Products nobody has ordered (Easy)
select p.product_id,p.product_name,p.category,p.product_status, p.stock_quantity,
    p.created_at
FROM sokomart.products p
WHERE NOT EXISTS (
    SELECT 1
    FROM sokomart.order_items oi
    WHERE oi.product_id = p.product_id
)
ORDER BY
    p.category,
    p.product_name;


























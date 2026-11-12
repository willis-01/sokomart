--Section B — Window functions
--Question 6 — County leaderboards (Medium)
WITH customer_revenue AS (
    -- CTE 1: Calculate lifetime revenue for every customer
    SELECT c.customer_id,c.first_name,c.last_name,c.county,
        SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM sokomart.customers c
    INNER JOIN sokomart.orders o
        ON c.customer_id = o.customer_id
    INNER JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    GROUP BY c.customer_id,c.first_name,c.last_name,c.county
),
customer_rankings AS (
    -- CTE 2: Rank customers within each county
    select county,customer_id,CONCAT(first_name, ' ', last_name) AS full_name,total_spent,
        DENSE_RANK() OVER (PARTITION BY county
            ORDER BY total_spent DESC
        ) AS county_rank
    FROM customer_revenue
)

-- Final output: Keep the top 3 ranks in each county
SELECT
    county,
    county_rank,
    customer_id,
    full_name,
    ROUND(total_spent, 2) AS total_spent

FROM customer_rankings
WHERE county_rank <= 3

ORDER BY
    county,
    county_rank,
    customer_id;

--Question 7 — Best sellers per category, 2025 (Medium)
WITH product_sales_2025 AS (
    -- CTE 1: Calculate revenue and units sold per product
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        SUM(oi.quantity) AS units_sold

    FROM sokomart.products p

    INNER JOIN sokomart.order_items oi
        ON p.product_id = oi.product_id

    INNER JOIN sokomart.orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-01-01'

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked_products AS (
    -- CTE 2: Rank products within each category
    SELECT
        category,
        product_id,
        product_name,
        revenue,
        units_sold,

        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC, product_id
        ) AS rank_in_category

    FROM product_sales_2025
)

-- Final output: Keep the top 3 products per category
WITH product_sales_2025 AS (
    -- CTE 1: Calculate revenue and units sold per product
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        SUM(oi.quantity) AS units_sold

    FROM sokomart.products p

    INNER JOIN sokomart.order_items oi
        ON p.product_id = oi.product_id

    INNER JOIN sokomart.orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'completed'
      AND o.order_date >= '2025-01-01'
      AND o.order_date < '2026-01-01'

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked_products AS (
    -- CTE 2: Rank products within each category
    SELECT
        category,
        product_id,
        product_name,
        revenue,
        units_sold,

        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC, product_id
        ) AS rank_in_category

    FROM product_sales_2025
)

-- Final output: Keep the top 3 products per category
SELECT
    category,
    rank_in_category,
    product_id,
    product_name,
    ROUND(revenue, 2) AS revenue,
    units_sold

FROM ranked_products
WHERE rank_in_category <= 3

ORDER BY
    category,
    rank_in_category;

--Question 8 — Month-over-month growth (Medium)
--Question 9 — Is each order bigger than the last? (Hard)
--Question 10 — Year-to-date revenue (Medium)
WITH monthly_sales AS (
    -- CTE 1: Calculate monthly revenue
    SELECT EXTRACT(YEAR FROM o.order_date)::INTEGER AS year,DATE_TRUNC('month', o.order_date)::DATE AS month,
        SUM(oi.quantity * oi.unit_price) AS monthly_revenue
    FROM sokomart.orders o
    INNER JOIN sokomart.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'completed'
    group by EXTRACT(YEAR FROM o.order_date),DATE_TRUNC('month', o.order_date)
),
running_totals AS (
    -- CTE 2: Calculate both running totals
    select year,month,monthly_revenue,
        SUM(monthly_revenue) OVER (PARTITION BY year
            ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_revenue_ytd,
        SUM(monthly_revenue) OVER (
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_revenue_all_time
    FROM monthly_sales
)
-- Final output
select year,TO_CHAR(month, 'Mon') AS month,ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(running_revenue_ytd, 2) AS running_revenue_ytd,
    ROUND(running_revenue_all_time, 2) AS running_revenue_all_time
FROM running_totals
ORDER BY month;
























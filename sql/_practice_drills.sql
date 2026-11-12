
--D1 List the products whose unit_price is above the average unit_price of all products. Show the 10 most expensive, then on a second query the count.
select product_id,product_name, unit_price
FROM sokomart.products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM sokomart.products
)
ORDER BY unit_price DESC
LIMIT 10;

SELECT
    COUNT(*) AS products_above_average
FROM sokomart.products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM sokomart.products
);

--D2 List customers living in Mombasa who placed at least one order (any status) in December 2025.
SELECT distinct c.customer_id,c.first_name,c.last_name, c.email,  c.county
FROM sokomart.customers c
INNER JOIN sokomart.orders o
    ON c.customer_id = o.customer_id
WHERE c.county = 'Mombasa'
  AND o.order_date >= '2025-12-01'
  AND o.order_date < '2026-01-01'
ORDER BY c.customer_id;

--D3 How many customers living in Kisumu have at least one payment with payment_status = 'failed'?
SELECT
    COUNT(DISTINCT c.customer_id) AS failed_payment_customers
FROM sokomart.customers c
INNER JOIN sokomart.orders o
    ON c.customer_id = o.customer_id
INNER JOIN sokomart.payments p
    ON o.order_id = p.order_id
WHERE c.county = 'Kisumu'
  AND p.payment_status = 'failed';

--D4 For each order_status, show the number of orders, the average number of lines per order and the average number of units per order. Compute the per-order figures in a subquery in FROM.

select order_status,COUNT(*) AS number_of_orders,
    ROUND(AVG(lines_per_order), 2) AS avg_lines_per_order,
    ROUND(AVG(units_per_order), 2) AS avg_units_per_order
FROM (
    SELECT o.order_id,o.order_status,
        COUNT(oi.product_id) AS lines_per_order,
        SUM(oi.quantity) AS units_per_order
    FROM sokomart.orders o
    INNER JOIN sokomart.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id,o.order_status
) AS order_summary
GROUP BY order_status
ORDER BY order_status;

--D5 Top 5 **shipping counties** by number of completed orders in 2026. Put the filtered orders in a CTE.
WITH completed_orders_2026 AS (
    select order_id,shipping_county
    FROM sokomart.orders
    WHERE order_status = 'completed'
      AND order_date >= '2026-01-01'
      AND order_date < '2027-01-01'
)

SELECT
    shipping_county,
    COUNT(order_id) AS total_completed_orders
FROM completed_orders_2026
GROUP BY shipping_county
ORDER BY total_completed_orders DESC
LIMIT 5;

--D6 For 2025: completed orders per month, the 2025 monthly average, and whether each month is above average or at/below average. Use two CTEs (monthly counts, then the stats).

WITH monthly_counts AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS order_month,
        COUNT(*) AS completed_orders
    FROM sokomart.orders
    WHERE order_status = 'completed'
      AND order_date >= '2025-01-01'
      AND order_date < '2026-01-01'
    GROUP BY DATE_TRUNC('month', order_date)
),

monthly_stats AS (
    SELECT
        AVG(completed_orders) AS monthly_average
    FROM monthly_counts
)

SELECT
    TO_CHAR(mc.order_month, 'Month') AS month,
    mc.completed_orders,
    ROUND(ms.monthly_average, 2) AS monthly_average,
    CASE
        WHEN mc.completed_orders > ms.monthly_average
            THEN 'above average'
        ELSE 'at/below average'
    END AS performance
FROM monthly_counts mc
CROSS JOIN monthly_stats ms
ORDER BY mc.order_month;

--D7 Write sokomart.fn_order_count(p_customer_id INTEGER) RETURNS INTEGER — the number of orders (any status) a customer has. Call it for customer 177 and for a customer that does not exist (-1).
CREATE OR REPLACE FUNCTION sokomart.fn_order_count(
    p_customer_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_order_count
    FROM sokomart.orders
    WHERE customer_id = p_customer_id;

    RETURN v_order_count;
END;
$$;

--Write sokomart.sp_set_customer_status(p_customer_id INTEGER, p_status VARCHAR). It raises an exception for a status other than active / inactive / suspended, and for a customer that does not exist. Inside BEGIN … ROLLBACK, set customer 177 to suspended, show it, roll back, show it is active again. Then show the exception for status 'vip'
CREATE OR REPLACE PROCEDURE sokomart.sp_set_customer_status(
    p_customer_id INTEGER,
    p_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate the customer status
    IF p_status NOT IN ('active', 'inactive', 'suspended') THEN
        RAISE EXCEPTION 'Invalid status: %. Allowed values are active, inactive, suspended.',
            p_status;
    END IF;

    -- Check whether the customer exists
    IF NOT EXISTS (
        SELECT 1
        FROM sokomart.customers
        WHERE customer_id = p_customer_id
    ) THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', p_customer_id;
    END IF;

    -- Update the customer status
    UPDATE sokomart.customers
    SET customer_status = p_status
    WHERE customer_id = p_customer_id;

END;
$$;

--Beauty products whose stock_quantity is below the average Beauty stock. Put the Beauty products in a CTE and compare with a scalar subquery on that CTE.

WITH beauty_products AS (
    SELECT
        product_id,
        product_name,
        category,
        stock_quantity
    FROM sokomart.products
    WHERE category = 'Beauty'
)

SELECT
    product_id,
    product_name,
    stock_quantity
FROM beauty_products
WHERE stock_quantity < (
    SELECT AVG(stock_quantity)
    FROM beauty_products
)
ORDER BY stock_quantity ASC;



























































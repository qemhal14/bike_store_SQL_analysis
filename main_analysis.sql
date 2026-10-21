-- Project: Bike Store Sales Analysis
-- Main Analysis

-- Business Questions:
-- 1. How can the business grow revenue 
-- 2. and improve delivery performance across its three stores?

-- Analysis Categories:
-- A. REVENUE: where the money come from and is it growing?
-- B. CUSTOMERS: who are the most valuable customers?
-- C. PRODUCTS: what sells and is stock in the right place?
-- D. DELIVERY: are orders arriving on time? 

-- Definitions
-- * Revenue =  quantity * list_price * (1 - discount), from order_items
-- * Revenue counts completed orders only (order_status = 4)
-- * Late delivery = shipped_date > required_date, shipped orders only

-- Setting up definition of revenue
CREATE OR REPLACE VIEW completed_sales AS
SELECT
	o.order_id,
	o.customer_id,
	o.store_id,
	o.order_date,
	oi.product_id,
	oi.quantity,
	oi.list_price,
	oi.discount,
	oi.quantity * oi.list_price * (1 - oi.discount) net_revenue
FROM orders o
INNER JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status = 4;

-- A. REVENUE

-- A1. How has revenue change over the years?

WITH yearly AS (
	SELECT
		DATE_PART('year', order_date)::int order_year,
		COUNT(DISTINCT order_id) completed_orders,
		SUM(net_revenue) revenue
	FROM completed_sales
	GROUP BY order_year
)
SELECT
	order_year,
	completed_orders,
	ROUND(revenue, 2) revenue,
	ROUND(100 * (revenue - LAG(revenue) OVER(ORDER BY order_year))
		/ LAG(revenue) OVER(ORDER BY order_year), 2) growth_percent
FROM yearly
ORDER BY order_year DESC;

-- A2. Which store generates the most revenue, and how much proportion?
SELECT
	s.store_name,
	COUNT(DISTINCT cs.order_id) completed_orders,
	ROUND(SUM(cs.net_revenue), 2) revenue,
	ROUND(100 * SUM(cs.net_revenue) / SUM(SUM(cs.net_revenue)) OVER(), 2) percent_rev
FROM completed_sales cs
INNER JOIN stores s
	ON cs.store_id = s.store_id
GROUP BY s.store_name
ORDER BY revenue DESC;

-- A3. Monthly revenue per store
SELECT
	s.store_name,
	DATE_TRUNC('month', cs.order_date)::date order_month,
	ROUND(SUM(cs.net_revenue), 2) revenue
FROM completed_sales cs
INNER JOIN stores s
	ON cs.store_id = s.store_id
GROUP BY s.store_name, order_month
ORDER BY s.store_name, order_month;

-- A4. Which product categories drive revenue?
SELECT
	ct.category_name,
	SUM(cs.quantity) bikes_sold,
	ROUND(SUM(cs.net_revenue), 2) revenue,
	ROUND(100.0 * SUM(cs.net_revenue) / SUM(SUM(cs.net_revenue)) OVER(), 2) percent_rev
FROM completed_sales cs
INNER JOIN products p
	ON cs.product_id = p.product_id
INNER JOIN categories ct
	ON p.category_id = ct.category_id
GROUP BY ct.category_name
ORDER BY revenue DESC;

-- B. CUSTOMERS

-- B1 Who are the top 10 customers by revenue?
WITH customer_revenue AS (
	SELECT
		customer_id,
		COUNT(DISTINCT order_id) orders,
		SUM(net_revenue) revenue
	FROM completed_sales
	GROUP BY customer_id
)
SELECT
	RANK() OVER(ORDER BY cr.revenue DESC) customer_rank,
	c.customer_id,
	CONCAT(c.first_name, ' ', c.last_name) full_name,
	c.state,
	cr.orders,
	ROUND(cr.revenue, 2) revenue
FROM customer_revenue cr
INNER JOIN customers c
	ON cr.customer_id = c.customer_id
ORDER BY customer_rank
LIMIT 10;

-- B2. How many customers come back to buy again?
WITH orders_per_customer AS (
	SELECT
		customer_id,
		COUNT(DISTINCT order_id) orders,
		SUM(net_revenue) revenue
	FROM completed_sales
	GROUP BY customer_id
)
SELECT
	CASE
		WHEN orders = 1 THEN 'One time customer'
		ELSE 'Repeat customer'
	END customer_type,
	COUNT(*) total_customers,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) percent_customers,
	ROUND(SUM(revenue), 2) revenue,
	ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER(), 2) percent_revenue
FROM orders_per_customer
GROUP BY customer_type;

-- B3. Which state generates the most revenue?

SELECT
	c.state,
	COUNT(DISTINCT cs.customer_id) customers,
	ROUND(SUM(cs.net_revenue), 2) revenue,
	ROUND(SUM(cs.net_revenue) / COUNT(DISTINCT cs.customer_id), 2) revenue_per_customer
FROM completed_sales cs
INNER JOIN customers c
	ON cs.customer_id = c.customer_id
GROUP BY c.state
ORDER BY revenue DESC;

-- C. Products and Inventory

-- C1. What are the top 10 products by revenue?
SELECT
	p.product_name,
	b.brand_name,
	SUM(cs.quantity) bikes_sold,
	ROUND(SUM(cs.net_revenue), 2) revenue
FROM completed_sales cs
INNER JOIN products p
	ON cs.product_id = p.product_id
INNER JOIN brands b
	ON p.brand_id = b.brand_id
GROUP BY p.product_name, b.brand_name
ORDER BY revenue DESC
LIMIT 10;

-- C2. Do bigger discounts leads to more bikes sold per order line?
SELECT
	discount,
	COUNT(*) order_lines,
	ROUND(AVG(quantity), 2) avg_bikes_per_line,
	ROUND(SUM(net_revenue), 2) revenue,
	ROUND(SUM(quantity * list_price * discount), 2) discount_given
FROM completed_sales
GROUP BY discount
ORDER BY discount;

-- C3. Is stock in line with sales?
-- Logic: months_of_cover = current stock / average units sold per month

WITH months_in_data AS (
	SELECT COUNT(DISTINCT DATE_TRUNC('month', order_date)) months
	FROM completed_sales
),
units_sold AS (
	SELECT
		product_id,
		SUM(quantity) total_units_sold
	FROM completed_sales
	GROUP BY product_id
),
current_stock AS (
	SELECT
		product_id,
		SUM(quantity) stock_ready
	FROM stocks
	GROUP BY product_id
),
product_cover AS (
	SELECT
		p.product_id,
		p.product_name,
		COALESCE(st.stock_ready, 0) stock_ready,
		COALESCE(us.total_units_sold, 0) total_units_sold,
		COALESCE(us.total_units_sold, 0)::numeric / m.months avg_monthly_sales
	FROM products p
	CROSS JOIN months_in_data m
	LEFT JOIN current_stock st
		ON p.product_id = st.product_id
	LEFT JOIN units_sold us
		ON p.product_id = us.product_id
)
SELECT
	CASE
		WHEN total_units_sold = 0 AND stock_ready > 0 THEN '1. No sales, in stock'
		WHEN stock_ready = 0 THEN '2. Out of stock'
		WHEN stock_ready / avg_monthly_sales < 1 THEN '3. Understock (under 1 month)'
		WHEN stock_ready / avg_monthly_sales > 6 THEN '5. Overstock (over 6 months)'
		ELSE '4. Healthy (1 to 6 months)'
	END stock_status,
	COUNT(*) products,
	SUM(stock_ready) units_in_stock
FROM product_cover
GROUP BY stock_status
ORDER BY stock_status;

-- D. Delivery Performance

-- D1. How much of shipped orders arrive late, by store?
SELECT
	s.store_name,
	COUNT(*) shipped_orders,
	COUNT(*) FILTER (WHERE o.shipped_date > o.required_date) late_orders,
	ROUND(100.0 * COUNT(*) FILTER (WHERE o.shipped_date > o.required_date) / COUNT (*), 2) late_percent,
	ROUND(AVG(o.shipped_date - o.order_date), 2) avg_days_shipping
FROM orders o
INNER JOIN stores s
	ON o.store_id = s.store_id
WHERE o.shipped_date IS NOT NULL
GROUP BY s.store_name
ORDER BY late_percent DESC;

-- D2. Is delivery performance improving overtimes?
SELECT
	EXTRACT(YEAR FROM order_date)::int order_year,
	COUNT(*) shipped_orders,
	ROUND(100.0 * COUNT(*) FILTER(WHERE shipped_date > required_date) / COUNT(*), 2) late_percent
FROM orders
WHERE shipped_date IS NOT NULL
GROUP BY order_year
ORDER BY order_year DESC;

-- D3 How many days if late
SELECT
	CASE
		WHEN shipped_date - required_date = 1 THEN '1 day late'
		WHEN shipped_date - required_date = 2 THEN '2 days late'
		ELSE '3 or more days late'
	END days_late_group,
	COUNT(*) late_orders
FROM orders
WHERE shipped_date > required_date
GROUP BY days_late_group
ORDER BY days_late_group;
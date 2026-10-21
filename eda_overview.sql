-- Exploratory Data Analysis and Overview
-- Dataset used -> https://www.kaggle.com/datasets/dillonmyrick/bike-store-sample-database
-- This is an updated version (20/10/2026) on previous project in my portfolio

-- 1. Overview all tables
SELECT 'brands' table_name, COUNT(*) row_count FROM brands
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'stores', COUNT(*) FROM stores
UNION ALL SELECT 'staffs', COUNT(*) FROM staffs
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'stocks', COUNT(*) FROM stocks
ORDER BY table_name;

-- 2. Products table

-- Price range and model years
SELECT
  MIN(list_price) min_price,
  MAX(list_price) max_price,
  ROUND(AVG(list_price), 2) avg_price,
  MIN(model_year) oldest_model_year,
  MAX(model_year) newest_model_year
FROM products;

-- Median price
SELECT 
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY list_price) median_price
FROM products;
 
-- Number of products per model year
SELECT 
	model_year, 
	COUNT(*) products
FROM products
GROUP BY model_year
ORDER BY model_year DESC;
 
-- Products that have never been sold
SELECT COUNT(*) products_never_sold
FROM products p
LEFT JOIN order_items oi
  ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- 3. Customers table

SELECT * FROM customers LIMIT 3;
 
-- Missing values in contact and address columns
SELECT
  COUNT(*) total_customers,
  COUNT(*) - COUNT(first_name) missing_fname,
  COUNT(*) - COUNT(last_name) missing_lname,
  COUNT(*) - COUNT(phone) missing_phone,
  COUNT(*) - COUNT(email) missing_email,
  COUNT(*) - COUNT(street) missing_street,
  COUNT(*) - COUNT(city) missing_city,
  COUNT(*) - COUNT(state) missing_state,
  COUNT(*) - COUNT(zip_code) missing_zip
FROM customers;

-- Missing phone data
SELECT
	COUNT(*) total_customers,
	COUNT(*) - COUNT(phone) missing_phone,
	ROUND((COUNT(*) - COUNT(phone)) * 100.0 /COUNT(*), 2) percent_missing_phone
FROM customers;	
 
-- Duplicate emails (the same person registered twice?)
SELECT 
	email, 
	COUNT(*) occurrences
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;
 
-- Customers per state
SELECT 
	state, 
	COUNT(*) customers
FROM customers
GROUP BY state
ORDER BY customers DESC;
 
-- Customers who never placed an order
SELECT COUNT(*) customers_without_orders
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 4. Stores and Staffs
SELECT * FROM stores;
SELECT * FROM staffs;

-- Staff per store, active vs inactive
SELECT
  s.store_name,
  COUNT(st.staff_id) total_staff,
  COUNT(*) FILTER (WHERE st.active = 1) active_staff
FROM stores s
LEFT JOIN staffs st
  ON s.store_id = st.store_id
GROUP BY s.store_name
ORDER BY s.store_name;

-- 5 Orders
SELECT * FROM orders LIMIT 3;
 
-- Date ranges
SELECT
  MIN(order_date) first_order,
  MAX(order_date) last_order
FROM orders;
 
-- Status distribution and status codes
SELECT
  order_status,
  COUNT(*) total_orders,
  COUNT(shipped_date) shipped_orders,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) percent_orders
FROM orders
GROUP BY order_status
ORDER BY order_status;

-- Orders not shipped yet

SELECT
  COUNT(*) FILTER (WHERE shipped_date IS NULL) AS orders_not_shipped
FROM orders;

SELECT
	order_status,
	COUNT(*) total_orders,
	COUNT(*) FILTER (WHERE shipped_date IS NULL) orders_notshipped
FROM orders
GROUP BY order_status
ORDER BY order_status;
 
-- Orders per year
SELECT
  DATE_PART('year', order_date) order_year,
  COUNT(*) total_orders
FROM orders
-- WHERE order_status = 4 -- for complete order only
GROUP BY order_year, order_year
ORDER BY order_year DESC;
 
-- Logic checks on dates
SELECT
  COUNT(*) FILTER (WHERE shipped_date < order_date) shipped_before_ordered,
  COUNT(*) FILTER (WHERE required_date < order_date) required_before_ordered
FROM orders;

-- 6. Order_items table
SELECT * FROM order_items LIMIT 3;
 
-- Quantity and discount ranges
SELECT
  MIN(quantity) min_qty,
  MAX(quantity) max_qty,
  MIN(discount) min_discount,
  MAX(discount) max_discount
FROM order_items;
 
-- Which discount levels exist?
SELECT 
	discount, 
	COUNT(*) order_lines
FROM order_items
GROUP BY discount
ORDER BY discount;
 
-- Is the price in order_items the same as the price in products?
SELECT
  COUNT(*) total_lines,
  COUNT(*) FILTER (WHERE oi.list_price <> p.list_price) lines_with_different_price
FROM order_items oi
INNER JOIN products p
  ON oi.product_id = p.product_id;
 
-- Items per order
SELECT
  MIN(items) min_items_per_order,
  MAX(items) max_items_per_order,
  ROUND(AVG(items), 2) avg_items_per_order
FROM (
  SELECT order_id, COUNT(*) items
  FROM order_items
  GROUP BY order_id
) per_order;

-- 7. Stocks table
SELECT * FROM stocks LIMIT 3;
 
-- Stock summary per store
SELECT
  s.store_name,
  COUNT(*) product_rows,
  SUM(st.quantity) total_units,
  COUNT(*) FILTER (WHERE st.quantity = 0) out_of_stock_products
FROM stocks st
INNER JOIN stores s
  ON st.store_id = s.store_id
GROUP BY s.store_name
ORDER BY s.store_name;
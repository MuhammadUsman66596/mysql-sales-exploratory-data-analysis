/*
				=============================================================
								 EXPLORATORY DATA ANALYSIS
				=============================================================

Project:
    Exploratory analysis of customer, product, and sales data.
Database:
    datawarehouseanalytics
Tables:
    dim_customers
    dim_products
    fact_sales
Objective:
    Understand the database structure, inspect data quality,
    explore business dimensions, calculate key measures,
    compare performance, and rank important entities.
=============================================================
*/

USE datawarehouseanalytics;


-- 				============================================================
-- 								1. DATABASE EXPLORATION
-- 				============================================================

-- List the tables available in the current project database
SELECT TABLE_NAME,TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'datawarehouseanalytics'
ORDER BY TABLE_NAME;

-- Display column names and data types for all project tables
SELECT TABLE_NAME,ORDINAL_POSITION,COLUMN_NAME,DATA_TYPE,IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'datawarehouseanalytics'
ORDER BY TABLE_NAME,
    ORDINAL_POSITION;


-- Compare the number of records stored in each table
SELECT 'Customers' AS table_name,
       COUNT(*) AS total_records
FROM dim_customers
UNION ALL
SELECT 'Products',
    COUNT(*)
FROM dim_products
UNION ALL
SELECT 'Sales',
    COUNT(*)
FROM fact_sales;

-- Preview a small sample from each table
SELECT * FROM dim_customers
LIMIT 5;

SELECT * FROM dim_products
LIMIT 5;

SELECT * FROM fact_sales
LIMIT 5;

-- 				============================================================
-- 								2. BASIC DATA QUALITY CHECKS
-- 				============================================================

-- Look for repeated customer keys
SELECT customer_key,
    COUNT(*) AS occurrences
FROM dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Look for repeated product keys
SELECT product_key,
    COUNT(*) AS occurrences
FROM dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Count missing values in important sales fields
SELECT
    SUM(order_number IS NULL) AS missing_order_numbers,
    SUM(customer_key IS NULL) AS missing_customer_keys,
    SUM(product_key IS NULL) AS missing_product_keys,
    SUM(order_date IS NULL) AS missing_order_dates,
    SUM(sales_amount IS NULL) AS missing_sales_amounts
FROM fact_sales;

-- Find sales records containing invalid numeric values
SELECT order_number,sales_amount,quantity,price
FROM fact_sales
WHERE sales_amount < 0 OR quantity <= 0 OR price < 0;

-- Check whether all sales customers exist in dim_customers
SELECT
    COUNT(*) AS unmatched_customer_records
FROM fact_sales AS f
LEFT JOIN dim_customers AS c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- Check whether all sales products exist in dim_products
SELECT
    COUNT(*) AS unmatched_product_records
FROM fact_sales AS f
LEFT JOIN dim_products AS p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;

-- 				============================================================
-- 								3. DIMENSIONS EXPLORATION
-- 				============================================================

-- Explore the countries represented in the customer data
SELECT DISTINCT country
FROM dim_customers
WHERE country IS NOT NULL
ORDER BY country;

-- Explore the available customer groups
SELECT DISTINCT gender,marital_status
FROM dim_customers
ORDER BY
    gender,marital_status;

-- Explore the complete product hierarchy
SELECT DISTINCT category,subcategory,product_name
FROM dim_products
ORDER BY category,subcategory,product_name;

-- Explore product lines and maintenance classifications
SELECT DISTINCT product_line, maintenance
FROM dim_products
ORDER BY
    product_line,maintenance;

-- 				============================================================
-- 									4. DATE EXPLORATION
-- 				============================================================

-- Find the beginning, ending, and length of the sales period
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    TIMESTAMPDIFF(MONTH,MIN(order_date),MAX(order_date)) AS sales_period_months
FROM fact_sales;

-- Find the birthdates and ages of the oldest and youngest customers
SELECT
	MIN(birthdate) AS oldest_birthdate,
    TIMESTAMPDIFF(YEAR,MIN(birthdate),CURDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    TIMESTAMPDIFF(YEAR,MAX(birthdate),CURDATE()) AS youngest_age
FROM dim_customers
WHERE birthdate IS NOT NULL;

-- Review yearly sales activity
SELECT
    YEAR(order_date) AS sales_year,
    SUM(sales_amount) AS yearly_revenue,
    COUNT(DISTINCT order_number) AS yearly_orders
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY sales_year;

-- Review monthly sales activity
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    SUM(sales_amount) AS monthly_revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT order_number) AS total_orders
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY sales_month;

-- 				============================================================
-- 								5. MEASURES EXPLORATION
-- 				============================================================

-- Present the main business measures in one result
SELECT
    'Total Revenue' AS measure_name,
    ROUND(SUM(sales_amount), 2) AS measure_value
FROM fact_sales
UNION ALL
SELECT
    'Total Quantity Sold',
    SUM(quantity)
FROM fact_sales
UNION ALL
SELECT
    'Average Recorded Price',
    ROUND(AVG(price), 2)
FROM fact_sales
UNION ALL
SELECT
    'Unique Orders',
    COUNT(DISTINCT order_number)
FROM fact_sales
UNION ALL
SELECT
    'Available Products',
    COUNT(DISTINCT product_key)
FROM dim_products
UNION ALL
SELECT
    'Registered Customers',
    COUNT(DISTINCT customer_key)
FROM dim_customers
UNION ALL
SELECT
    'Purchasing Customers',
    COUNT(DISTINCT customer_key)
FROM fact_sales;

-- Calculate the average revenue generated per order
SELECT
    ROUND(
        SUM(sales_amount) /
        NULLIF(COUNT(DISTINCT order_number), 0),
        2
    ) AS average_order_value
FROM fact_sales;

-- 				============================================================
-- 									6. MAGNITUDE ANALYSIS
-- 				============================================================

-- Compare customer population across countries
SELECT
    COALESCE(country, 'Unknown') AS country,
    COUNT(DISTINCT customer_key) AS total_customers
FROM dim_customers
GROUP BY COALESCE(country, 'Unknown')
ORDER BY total_customers DESC;

-- Compare customer population by gender
SELECT
    COALESCE(gender, 'Unknown') AS gender,
    COUNT(DISTINCT customer_key) AS total_customers
FROM dim_customers
GROUP BY COALESCE(gender, 'Unknown')
ORDER BY total_customers DESC;

-- Compare the number of products across categories
SELECT
    COALESCE(category, 'Unknown') AS category,
    COUNT(DISTINCT product_key) AS total_products
FROM dim_products
GROUP BY COALESCE(category, 'Unknown')
ORDER BY total_products DESC;

-- Compare average product cost across categories
SELECT
    COALESCE(category, 'Unknown') AS category,
    ROUND(AVG(cost), 2) AS average_product_cost
FROM dim_products
GROUP BY COALESCE(category, 'Unknown')
ORDER BY average_product_cost DESC;

-- Compare revenue generated by each product category
SELECT
    COALESCE(p.category, 'Unknown') AS category,
    SUM(f.sales_amount) AS total_revenue
FROM fact_sales AS f
LEFT JOIN dim_products AS p
    ON f.product_key = p.product_key
GROUP BY COALESCE(p.category, 'Unknown')
ORDER BY total_revenue DESC;

-- Compare revenue and sold quantity across countries
SELECT
    COALESCE(c.country, 'Unknown') AS country,
    SUM(f.sales_amount) AS total_revenue,
    SUM(f.quantity) AS total_items_sold
FROM fact_sales AS f
LEFT JOIN dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY COALESCE(c.country, 'Unknown')
ORDER BY total_revenue DESC;

-- Measure the revenue generated by individual customers
SELECT
    c.customer_key,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.sales_amount) AS total_revenue
FROM fact_sales AS f
INNER JOIN dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;

-- 				============================================================
-- 									7. RANKING ANALYSIS
-- 				============================================================

-- Identify the five products producing the highest revenue
SELECT
    p.product_key,
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM fact_sales AS f
INNER JOIN dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_key,
    p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Identify the five sold products producing the lowest revenue
SELECT
    p.product_key,
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM fact_sales AS f
INNER JOIN dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    p.product_key,
    p.product_name
ORDER BY total_revenue ASC
LIMIT 5;

-- Identify the ten customers generating the highest revenue
SELECT
    c.customer_key,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(f.sales_amount) AS total_revenue
FROM fact_sales AS f
INNER JOIN dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Find three registered customers with the fewest orders
SELECT
    c.customer_key,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM dim_customers AS c
LEFT JOIN fact_sales AS f
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY
    total_orders ASC,
    c.customer_key ASC
LIMIT 3;

-- Rank products by revenue with a MySQL window function
WITH product_totals AS (
    SELECT
        p.product_key,
        p.product_name,
        SUM(f.sales_amount) AS total_revenue
    FROM fact_sales AS f
    INNER JOIN dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY
        p.product_key,
        p.product_name
),
product_ranking AS (
    SELECT
        product_key,
        product_name,
        total_revenue,
        DENSE_RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS revenue_position
    FROM product_totals
)
SELECT
    product_key,
    product_name,
    total_revenue,
    revenue_position
FROM product_ranking
WHERE revenue_position <= 5
ORDER BY
    revenue_position,
    product_name;
-- 			============================================================
-- 									THE END
-- 			============================================================
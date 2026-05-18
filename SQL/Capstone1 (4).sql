CREATE DATABASE food_delivery;
USE food_delivery;

SELECT * FROM customers;
SELECT * FROM restaurants;
SELECT * FROM menu;
SELECT * FROM orders;
SELECT * FROM order_details;

#Total number of customers
SELECT COUNT(*) AS total_customers FROM customers;

#Total orders
SELECT COUNT(*) AS total_orders FROM orders;

# Customer + Order details
SELECT 
    c.customer_name,
    o.o_order_id,
    o.o_order_date,
    o.o_total_amount
FROM orders o
JOIN customers c 
ON o.o_customer_id = c.customer_id;

#Restaurant-wise orders
SELECT 
    r.r_restaurant_name,
    COUNT(o.o_order_id) AS total_orders
FROM restaurants r
JOIN orders o 
ON r.r_restaurant_id = o.o_restaurant_id
GROUP BY r.r_restaurant_name;

#Full Order Detail (Customer + Restaurant + Items)
SELECT c.customer_name,r.r_restaurant_name,m.m_item_name,od.quantity,o.o_order_date FROM orders o
JOIN customers c ON o.o_customer_id = c.customer_id
JOIN restaurants r ON o.o_restaurant_id = r.r_restaurant_id
JOIN order_details od ON o.o_order_id = od.order_id
JOIN menu m ON od.menu_id = m.m_menu_id;

### Customers who spent above average
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT o_customer_id
    FROM orders
    WHERE o_total_amount > (
        SELECT AVG(o_total_amount) FROM orders
    )
);

# Restaurant with highest orders
SELECT r_restaurant_name
FROM restaurants
WHERE r_restaurant_id = (
    SELECT o_restaurant_id
    FROM orders
    GROUP BY o_restaurant_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

# Top 5 customers by spending
SELECT 
    c.customer_name,
    SUM(o.o_total_amount) AS total_spent
FROM orders o
JOIN customers c 
ON o.o_customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 5;

# Rank customers by spending
SELECT 
    c.customer_name,
    SUM(o.o_total_amount) AS total_spent,
    RANK() OVER (ORDER BY SUM(o.o_total_amount) DESC) AS customer_rank
FROM orders o
JOIN customers c 
ON o.o_customer_id = c.customer_id
GROUP BY c.customer_name;

# Running total of revenue
SELECT 
    o_order_date,
    SUM(o_total_amount) AS daily_sales,
    SUM(SUM(o_total_amount)) OVER (ORDER BY o_order_date) AS running_total
FROM orders
GROUP BY o_order_date;

# Top item per restaurant
SELECT *
FROM (
    SELECT 
        r.r_restaurant_name,
        m.m_item_name,
        SUM(od.quantity) AS total_qty,
        RANK() OVER (
            PARTITION BY r.r_restaurant_name 
            ORDER BY SUM(od.quantity) DESC
        ) AS item_rank
    FROM order_details od
    JOIN menu m ON od.menu_id = m.m_menu_id
    JOIN restaurants r ON m.m_restaurant_id = r.r_restaurant_id
    GROUP BY r.r_restaurant_name, m.m_item_name
) t
WHERE item_rank = 1;

# Customer total spending using CTE
WITH customer_spending AS (
    SELECT 
        o_customer_id,
        SUM(o_total_amount) AS total_spent
    FROM orders
    GROUP BY o_customer_id
)
SELECT 
    c.customer_name,
    cs.total_spent
FROM customer_spending cs
JOIN customers c 
ON cs.o_customer_id = c.customer_id
ORDER BY cs.total_spent DESC;

# Top restaurant using CTE
WITH restaurant_orders AS (
    SELECT 
        o_restaurant_id,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY o_restaurant_id
)
SELECT 
    r.r_restaurant_name,
    ro.total_orders
FROM restaurant_orders ro
JOIN restaurants r 
ON ro.o_restaurant_id = r.r_restaurant_id
ORDER BY ro.total_orders DESC;

# Repeat customers
SELECT 
    o_customer_id,
    COUNT(*) AS order_count
FROM orders
GROUP BY o_customer_id
HAVING COUNT(*) > 1;

# Customer retention (first vs last order)
SELECT 
    o_customer_id,
    MIN(o_order_date) AS first_order,
    MAX(o_order_date) AS last_order
FROM orders
GROUP BY o_customer_id;

# Find most valuable customer per city
WITH spending AS (
    SELECT 
        c.city,
        c.customer_name,
        SUM(o.o_total_amount) AS total_spent,
        RANK() OVER (
            PARTITION BY c.city 
            ORDER BY SUM(o.o_total_amount) DESC
        ) AS customer_rank
    FROM customers c
    JOIN orders o 
    ON c.customer_id = o.o_customer_id
    GROUP BY c.city, c.customer_name
)
SELECT *
FROM spending
WHERE customer_rank = 1;
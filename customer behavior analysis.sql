CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id,product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
# -----CUSTOMER BEHAVIOR ANALYSIS----

# What is the total amount each customer spent at the restaurant?
  
SELECT 
    s.customer_id, sum(m.price) as total_spent
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
group by customer_id;

# How many days has each customer visited the restaurant?

SELECT 
    customer_id, COUNT(distinct order_date) as num_of_days_visited
FROM
    sales
GROUP BY customer_id;

# What was the first item from the menu purchased by each customer?

with customer_first_purchase as
    (SELECT 
        customer_id, MIN(order_date) AS first_purchase_date
    FROM
        sales
    GROUP BY customer_id)
SELECT 
    cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM
    customer_first_purchase cfp
        JOIN
    sales s ON cfp.customer_id = s.customer_id
        AND cfp.first_purchase_date = s.order_date
        JOIN
    menu m ON m.product_id = s.product_id;

# What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    m.product_name, COUNT(*) AS total_times_purchased
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_times_purchased DESC
LIMIT 1;

# Which item was the most popular for each customer?

WITH popular_item as (
select s.customer_id , count(*) as purchase_count, m.product_name,
row_number() over( partition by s.customer_id order by count(*) desc) as ranking
from sales s join menu m on s.product_id = m.product_id
group by s.customer_id , m.product_name)
SELECT 
    po.customer_id, po.product_name, po.purchase_count
FROM
    popular_item po
WHERE
    ranking = 1;
    
# Which item was purchased first by the customer after they became a member? 

with after_membership_purchase as(
select s.customer_id , s.order_date , m.product_name,
row_number() over(partition by customer_id order by order_date) as ranking
from sales s join menu m on s.product_id = m.product_id
join members mem on s.customer_id = mem.customer_id
where order_date >= join_date 
order by customer_id , order_date asc)

SELECT 
    am.customer_id, am.product_name, am.order_date
FROM
    after_membership_purchase am
WHERE
    ranking = 1 ;

# Which item was purchased just before the customer became a member?

with last_purshase_before_member as (SELECT 
    s.customer_id, MAX(s.order_date) AS last_purchase
FROM
    sales s
        JOIN
    members mem ON s.customer_id = mem.customer_id
WHERE
    order_date < join_date
GROUP BY s.customer_id)

SELECT 
    lp.customer_id, m.product_name
FROM
    last_purshase_before_member lp
        JOIN
    sales s ON lp.customer_id = s.customer_id
        AND lp.last_purchase = s.order_date
        JOIN
    menu m ON s.product_id = m.product_id
ORDER BY customer_id;

# What is the total items and amount spent for each member before they became a member?

SELECT 
    s.customer_id,
    COUNT(*) AS number_of_items,
    SUM(m.price) AS total_amount_spent
FROM
    sales s
        JOIN
    members mem ON s.customer_id = mem.customer_id
        JOIN
    menu m ON m.product_id = s.product_id
WHERE
    order_date < join_date
GROUP BY customer_id
ORDER BY customer_id;



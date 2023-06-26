create database swiggy;
use swiggy;
alter table orders modify column date date;

update orders set restaurant_rating = 'Null'
where restaurant_rating not in (1,2,3,4,5);

-- 1. Number of orders via each restaurant
select restaurants.r_id, restaurants.r_name, count(orders.r_id) as order_count
from restaurants
join orders
on
restaurants.r_id = orders.r_id
group by restaurants.r_id
order by order_count desc;

-- 2. Highest number of food names ordered
select food.f_id, food.f_name, count(order_details.f_id) as order_count
from food
join order_details
on
food.f_id = order_details.f_id
group by food.f_id
order by order_count desc ;

-- 3. Highest amount ordered via restaurant
select restaurants.r_id, restaurants.r_name, 
restaurants.cuisine,sum(orders.amount) as total_amount
from restaurants
join orders
on
restaurants.r_id = orders.r_id
group by restaurants.r_id
order by sum(orders.amount) desc; 

-- 4. Customers and amount spent and number of orders
select users.user_id, users.name, 
sum(orders.amount) as total_amount, 
count(orders.user_id) as order_count
from users
join orders
on
users.user_id = orders.user_id
group by users.user_id
order by sum(orders.amount) desc ;

-- 5. Fetch each delviery partner's delivery count , rating , delivery time 
select delivery_partner.partner_id, delivery_partner.partner_name, 
count(orders.order_id) order_count, 
round(avg(orders.delivery_time),2) avg_delivery_time, 
round(avg(orders.delivery_rating),2) avg_delivery_rating
from orders
right join delivery_partner
on 
orders.partner_id = delivery_partner.partner_id
group by delivery_partner.partner_id;

-- 6.Date and Amount spent
select users.user_id, users.name, orders.date, orders.amount
from users
join orders
on
users.user_id = orders.user_id;


-- 7. days between previous order for all users
select users.user_id, users.name, orders.date, 
orders.date - lag(orders.date) over (order by orders.date) as days_between_orders	
from users
join orders
on
users.user_id = orders.user_id;

-- 8. customer and cuisine preference
select users.user_id, users.name, restaurants.r_id, restaurants.cuisine
from orders
join restaurants 
on orders.r_id = restaurants.r_id  
join users
on orders.user_id = users.user_id
where users.user_id = 1;

-- 9. find out customers who have not ordered

select name from users
where user_id not in (select user_id
from orders);

-- 10. find out the restaurant which had the highest number of orders in the month of May

select restaurants.r_id,restaurants.r_name, 
monthname(orders.date) as 'month',count(orders.r_id) as total_orders
from restaurants
join orders
on restaurants.r_id = orders.r_id
where monthname(orders.date) = 'May'
group by restaurants.r_id 
order by total_orders desc
limit 1;


-- 11. find out restaurants whose total revenue in June is greater than 500
select restaurants.r_id, restaurants.r_name, 
monthname(orders.date) as 'month',sum(orders.amount) as total_revenue
from restaurants
join orders
on
restaurants.r_id = orders.r_id
where monthname(orders.date) = 'June'
group by restaurants.r_id
having sum(orders.amount) > 500
order by sum(orders.amount) desc; 

-- 12. show all orders with order details for a particular customer in a particular date range
select users.name, orders.order_id, 
restaurants.r_name,food.f_name,orders.date, orders.amount 
from orders
join users
on orders.user_id = users.user_id
join restaurants
on orders.r_id = restaurants.r_id
join order_details
on orders.order_id = order_details.order_id
join food
on order_details.f_id = food.f_id
where orders.date between '2022-06-10' and '2022-07-10' 
and users.name = 'Ankit'
order by orders.order_id ;

-- 13.Find restaurants with maximum repeated customers
select restaurants.r_name, count(*) as loyal_customers
from
(select r_id, user_id, count(*) as order_placed
from orders
group by r_id, user_id
having order_placed > 1
) t
join restaurants
on t.r_id = restaurants.r_id
group by t.r_id
order by loyal_customers desc 
limit 1;

-- 14. find most loyal customer for each restaurant
select restaurants.r_id, restaurants.r_name, users.user_id, users.name
from
(select  r_id, user_id, count(*) as total_orders
from orders
group by r_id, user_id
having total_orders > 1
order by r_id) t
join restaurants
on t.r_id = restaurants.r_id
join users
on t.user_id = users.user_id
order by r_id;	



-- 15. month over month revenue growth for the food delviery platform
select month, round(((total_revenue - previous)/previous)*100,2) as mom_pct_growth
from 
(with sales as
(select monthname(date) as 'month', sum(amount) as total_revenue
from orders
group by monthname(date))
select month, total_revenue, lag(total_revenue,1) 
over (order by total_revenue) as 'previous' 
from sales) t;

-- 16.  month over month revenue growth for any restaurant
select month, r_name, round(((revenue - previous)/previous)*100,2)  mom_pct_growth
from 
(with sales as
(select monthname(orders.date) as month, orders.r_id, restaurants.r_name,orders.amount as 'revenue'
from orders
join restaurants
on orders.r_id = restaurants.r_id
where orders.r_id = 2
group by monthname(orders.date))
select month, r_id, r_name, revenue, lag(revenue,1)
over (order by revenue) as 'previous'
from sales) t;

-- 17. customer and their favorite food items
with temporary as 
(select users.user_id,users.name,food.f_id,food.f_name, count(*) as total_orders
from users
join orders
on users.user_id = orders.user_id
join order_details
on orders.order_id = order_details.order_id
join food
on order_details.f_id = food.f_id
group by users.user_id, food.f_id
order by users.user_id)
select *
from temporary t1
where t1.total_orders =
(select max(total_orders)
from temporary t2
where t2.user_id = t1.user_id);
use new_wheel;
select * from order_t;
select * from customer_t;
select * from product_t;
select * from shipper_t;
/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
select state,count(customer_id) as distribution_of_customers  from customer_t
 group by 1 
 order by 2 desc;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */
with feedback_cte as (select quarter_number,customer_feedback, case when customer_feedback = 'Very Bad' then 1
							when customer_feedback ='Bad' then 2
                            when customer_feedback = 'Okay' then 3
                            when customer_feedback = 'Good' then 4
                            when customer_feedback = 'Very Good' then 5 
                            end as feedback_rating from order_t
                            )
select quarter_number,round(avg(feedback_rating),1) as Average_feedback from feedback_cte
group by 1 
order by 1;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as 
      the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */
   
  
	with count_cte as (select customer_feedback,quarter_number,count(customer_id) as number_of_cust,
    sum(count(customer_id)) over (partition by quarter_number) as tot_no_of_cust from order_t 
    group by 1,2 order by quarter_number) 
    select quarter_number,customer_feedback, round(number_of_cust/tot_no_of_cust*100,2) as percentage_feed 
    from count_cte
    order by 1,3;
     


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

select p.vehicle_maker,count(customer_id) as number_of_Customer from product_t as p
join order_t using (product_id)
join customer_t using (customer_id)
group by 1
order by 2 desc
limit 5;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/


with rank_cte as (select distinct(c.state),(p.vehicle_maker),count(customer_id*quantity)as no_of_cars,
dense_rank() over (partition by state order by count(customer_id) desc) as rank_order from customer_t as c
join order_t as o using(customer_id)
join product_t as p using (product_id)
group by 1,2) 
select state,vehicle_maker,no_of_cars, rank_order from rank_cte
having rank_order =1
order by state ;

-- ---------------------------------------------------------------------------------------------------------------------------------


/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

select quarter_number,count(order_id) from order_t
group by quarter_number
order by count(order_id*quantity) desc;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/ 
	-- discount included in revenue i.e., revenue =(vehicle_price-(vehicle_price*discount))*quantity
	with quarter_cte as 
    (select quarter_number,sum((vehicle_price-(discount*vehicle_price))*quantity) as quarterly_revenue,
	lag(sum((vehicle_price-(discount*vehicle_price))*quantity)) over (order by quarter_number) as change_in_revenue
    from order_t group by 1) 
    select quarter_number as Quarter,round(quarterly_revenue,2) as Quarter_Revenue,
    round(((quarterly_revenue-change_in_revenue)/quarterly_revenue)*100,2) as Percentage_change_in_revenue 
    from quarter_cte;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

select quarter_number as Quarter, round(sum((vehicle_price-(discount*vehicle_price))*quantity),0) as Revenue, 
count(order_id) as Number_of_order from order_t
group by quarter_number
order by quarter_number;




-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

select c.credit_card_type as Credit_Card_Type, round(avg(discount),2) as Average_Discount from customer_t as c
join order_t using(customer_id)
group by 1
order by 2 desc;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
select quarter_number as Quarter,round(avg(datediff(ship_date,order_date)),0) as "Average Time Taken (In Days)" 
from order_t
group by 1
order by 2;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------

-- Total Revenue
select round(sum((vehicle_price-(discount*vehicle_price))*quantity),0) as total_revenue from order_t;


-- Total Orders
select count(order_id) as total_orders from order_t;


-- Total Customers
select count(customer_id) as total_customer from customer_t;


-- Average Rating
with feedback_values as (select quarter_number,customer_feedback, case when customer_feedback = 'Very Bad' then 1
							when customer_feedback ='Bad' then 2
                            when customer_feedback = 'Okay' then 3
                            when customer_feedback = 'Good' then 4
                            when customer_feedback = 'Very Good' then 5 
                            end as feedback_rating from order_t
                            )
select round(avg(feedback_rating),1) as Average_feedback from feedback_values;


-- Last Quarter Revenue
select quarter_number, round(sum((vehicle_price-(discount*vehicle_price))*quantity),0) as last_quarter_revenue
from order_t
group by 1
having quarter_number =4;


-- Last Quarters Orders
select quarter_number,(count(order_id)) as last_quarter_orders from order_t
group by 1
having quarter_number =4;


-- Average Time Taken to ship
SELECT round(avg(datediff(ship_date,order_date)),0) as time_taken from order_t;


-- % good feedback
with temp as (select customer_feedback, count(order_id) as good_feedback from order_t
where customer_feedback in ('Good','Very Good')
group by 1 ) 
select sum(good_feedback)/1000*100 percentage_good_feedback from temp;


-- Number of orders from different types of Credit card
select credit_card_type, count(order_id) no_of_orders from customer_t
join order_t using (customer_id)
group by 1;


-- Number of orders and Average Time Taken to ship from air or truck
select shipping,count(order_id) number_of_order,round(avg(datediff(ship_date,order_date)),0) as Time_taken from order_t
group by 1;

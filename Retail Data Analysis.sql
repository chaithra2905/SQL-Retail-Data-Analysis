create database casestudy1

use casestudy1

Select * from Customer
Select * from prod_cat_info
Select * from Transactions

---1.Total number of rows in each of the 3 tables

Select 'Customer' as Table_Name, Count(*) as No_of_rows from Customer
UNION ALL
Select 'prod_cat_info', Count(*) from prod_cat_info
UNION ALL
Select 'Transactions', Count(*) from Transactions

--2.What is the total number of transactions that have a return?

Select COUNT(Distinct([transaction_id])) as No_of_Transactions_that_have_a_Return from Transactions 
where CAST([total_amt] AS FLOAT)<1

--OR
Select COUNT(Distinct([transaction_id])) as No_of_Transactions_that_have_a_Return from Transactions 
where Qty<1

---3.As you would have noticed, the dates provided across the datasets are not in a 
-----correct format. As first steps, pls convert the date variables into valid date 
-----formats before proceeding ahead.

Select CONVERT(date,[tran_date],105 )as formatted_date
from Transactions 

Select CONVERT(date,[DOB],105 )as formatted_date
from Customer 

--4. What is the time range of the transaction data available for analysis? 
--Show the output in number of days, months and years simultaneously 
--in different columns.
Select DATEDIFF(YEAR,MIN(CONVERT(date,[tran_date],105 )),MAX(CONVERT(date,[tran_date],105 ))) as YEARS,
DATEDIFF(MONTH,MIN(CONVERT(date,[tran_date],105 )),MAX(CONVERT(date,[tran_date],105 ))) as MONTHS,
DATEDIFF(DAY,MIN(CONVERT(date,[tran_date],105 )),MAX(CONVERT(date,[tran_date],105 ))) as DAYS_
from Transactions

--5. Which product category does the sub-category "DIY" belong to?

Select [prod_cat] from [dbo].[prod_cat_info]
where [prod_subcat]='DIY'

--DATA ANALYSIS
--1. Which channel is most frequently used for transactions?
SELECT TOP 1 Store_type,COUNT(*) as No_of_Transactions from Transactions
GROUP BY Store_type 
ORDER BY No_of_Transactions DESC

--2.What is the count of Male and Female customers in the database?

Select Gender, Count(*) as Cnt from Customer
where Gender is not null
Group By Gender

--3.From which city do we have the maximum number of customers and how many?

Select TOP 1 city_code,COUNT(*) as cnt from Customer
Group by city_code
ORDER BY cnt desc

--4.How many sub-categories are there under the Books category?

Select prod_cat,prod_subcat, count(*) as Sub_categories_cnt from prod_cat_info
Where prod_cat='Books'
Group by prod_cat,prod_subcat

--5.What is the maximum quantity of products ever ordered?
Select prod_cat_code, Max(Qty) as max_prod from Transactions
group by prod_cat_code

-- 6.What is the net total revenue generated in categories Electronics and Books?


Select SUM(CAST(total_amt as float)) as revenue from prod_cat_info as pc
inner join Transactions as t
on pc.prod_cat_code=t.prod_cat_code and pc.[prod_sub_cat_code]=t.[prod_subcat_code]
where prod_cat ='Books'OR prod_cat= 'Electronics'

Select SUM(CAST(total_amt as float)) as revenue from prod_cat_info as pc
inner join Transactions as t
on pc.prod_cat_code=t.prod_cat_code and pc.[prod_sub_cat_code]=t.[prod_subcat_code]
where prod_cat IN('Books','Electronics')


--7.How many customers have >10 transactions with us, excluding returns?

Select count(*) as Total_Cus from
(
Select cust_id, count(distinct([transaction_id])) as cnt_trans from Transactions
where Qty>0
group by cust_id
having count(distinct([transaction_id]))>10
)
as tc

--8.What is the combined revenue earned from the "Electronics" & "Clothing" categories, from "Flagship stores"?

Select sum(cast(total_amt as float)) as combined_revenue from prod_cat_info as pc 
inner join Transactions as t
on pc.[prod_cat_code]=t.[prod_cat_code] and pc.[prod_sub_cat_code]=t.[prod_subcat_code]
where prod_cat IN('Electronics','Clothing') and Store_type='Flagship store' and qty>0

--9.What is the total revenue generated from "Male" customers in "Electronics" category? Output should display 
--total revenue by prod sub-cat.

Select [prod_subcat],sum(cast(total_amt as float)) as total_revenue from [dbo].[Customer] c
inner join [dbo].[Transactions] t
on c.[customer_Id]=t.[cust_id]
inner join [prod_cat_info] pc
on pc.[prod_cat_code]=t.[prod_cat_code] and pc.[prod_sub_cat_code]=t.[prod_subcat_code]
where Gender='M' and prod_cat='Electronics'
group by [prod_subcat]

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories 
--in terms of sales?

Select ps.[prod_subcat],percentage_Sales,percentage_returns from (
Select top 5 [prod_subcat], sum(cast([total_amt] as float))/(Select sum(cast([total_amt] as float)) as tot_Sales from Transactions 
where qty>0) as percentage_Sales
from Transactions t
inner join [prod_cat_info] pc
on pc.[prod_cat_code]=t.[prod_cat_code] and pc.[prod_sub_cat_code]=t.[prod_subcat_code]
where qty>0
group by [prod_subcat]
order by percentage_sales desc) as ps

join
(
Select [prod_subcat], sum(cast([total_amt] as float))/(Select sum(cast([total_amt] as float)) as tot_Sales from Transactions 
where qty<0) as percentage_returns
from Transactions t
inner join [prod_cat_info] pc
on pc.[prod_cat_code]=t.[prod_cat_code] and pc.[prod_sub_cat_code]=t.[prod_subcat_code]
where qty<0
group by [prod_subcat]
 ) as pr
 on ps.prod_subcat=pr.prod_subcat

--11. For all customers aged between 25 to 35 years find what is the net total revenue generated by these 
--consumers in last 30 days of transactions from max transaction date available in the data?

Select * from(
----age
Select * from(
Select cust_id, DATEDIFF(year,convert(date,DOB,105),max_date) as Age,total_revenue
from(
Select cust_id,DOB,MAX(convert(date,[tran_date],105)) as max_date, sum(cast(total_amt as float)) as total_revenue from Customer as c
join Transactions as t
on c.customer_Id=t.cust_id
where qty>0
group by cust_id, dob
) as A
) as B 
where Age between 25 and 35
) as C
--last 30 days transactions
Join
(
Select cust_id, convert(date,tran_date,105) as tran_date from transactions
group by cust_id,convert(date,tran_date,105)
having convert(date,tran_date,105) >=(Select dateadd(day, -30, max(convert(date,tran_date,105))) as cut_off
from Transactions)
) as D
on C.cust_id=D.cust_id

--12. Which product category has seen the max value of returns in the last 3 months of transactions?

--last 3 month transcations

Select top 1 prod_cat_code, sum(returns) as total_returns from(

Select prod_cat_code, convert(date,tran_date,105) as tran_date, sum(cast(qty as int)) as Returns from transactions
where qty<0
group by prod_cat_code ,convert(date,tran_date,105)
having convert(date,tran_date,105) >=(Select dateadd(MONTH, -3, max(convert(date,tran_date,105))) as cut_off
from Transactions)
) as A
group by prod_cat_code
order by total_returns

--13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?

Select top 1 Store_type ,sum(cast(Qty as int)) as max_qty, sum(cast(total_amt as float)) as revenue
from Transactions 
where qty>0 
group by Store_type
order by max_qty desc, revenue desc

--14.What are the categories for which average revenue is above the overall average

Select pc.prod_cat_code, prod_cat,avg(cast(total_amt as float)) as avg_category_revenue
from prod_cat_info as pc
join Transactions as t
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
where qty>0
group by pc.prod_cat_code,pc.prod_cat
having avg(cast(total_amt as float))>
(Select avg(cast(total_amt as float)) as overall_average_revenue 
from Transactions where qty>0)

--15. Find the average and total revenue by each subcategory for the categories which are among top 5 
--categories in terms of quantity sold.
Select * from
(
Select pc.prod_cat,prod_sub_cat_code, prod_subcat,avg(cast(total_amt as float)) as avg_subcategory_revenue,
sum(cast(total_amt as float)) as total_subcategory_revenue
from prod_cat_info as pc
join Transactions as t
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
where qty>0
group by pc.prod_sub_cat_code,pc.prod_subcat,pc.prod_cat
) as t1 
join
(Select top 5 pc.prod_cat,sum(cast(Qty as int)) as qty_total
from prod_cat_info as pc
join Transactions as t
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
where qty>0
group by pc.prod_cat
order by qty_total desc
) as t2
on t1.prod_cat=t2.prod_cat


Select pc.[prod_cat_code],pc.[prod_cat],prod_sub_cat_code,pc.prod_subcat,avg(cast(total_amt as float)) as avg_subcategory_revenue,
sum(cast(total_amt as float)) as total_subcategory_revenue
from prod_cat_info as pc
join Transactions as t
on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
where qty>0 and prod_cat IN
							(Select top 5 pc.prod_cat
							from prod_cat_info as pc
							join Transactions as t
							on pc.prod_cat_code=t.prod_cat_code and pc.prod_sub_cat_code=t.prod_subcat_code
							where qty>0
							group by pc.prod_cat
							order by sum(cast(Qty as int)) desc)
group by pc.prod_sub_cat_code,pc.prod_subcat,pc.[prod_cat_code],pc.[prod_cat]


-----------

Select prod_subcat_code,avg(cast(total_amt as float)) as avg_subcategory_revenue,
sum(cast(total_amt as float)) as total_subcategory_revenue
from Transactions 
where qty>0 and prod_cat_code IN
							(Select top 5 prod_cat_code
							from Transactions 
							where qty>0
							group by prod_cat_code
							order by sum(cast(Qty as int)) desc)
group by prod_subcat_code
-- 1 Top 3 and Bottom 3 for fiscal year 2023
select evm.maker, sum(electric_vehicles_sold) as total_ev_sold
from electric_vehicle_sales_by_makers evm
join dim_date dd
on evm.dates = dd.dates
where evm.vehicle_category = '2-Wheelers' and dd.fiscal_year = '2023'
group by evm.maker
-- to get bottom 3, remove desc
order by total_ev_sold desc
limit 3;

-- Top 3 and Bottom 3 for fiscal year 2024
select evm.maker, sum(electric_vehicles_sold) as total_ev_sold
from electric_vehicle_sales_by_makers evm
join dim_date dd
on evm.dates = dd.dates
where evm.vehicle_category = '2-Wheelers' and dd.fiscal_year = '2024'
group by evm.maker
-- to get bottom 3, remove desc
order by total_ev_sold desc
limit 3;


-- Q2
-- state wise total ev sold and total vehicles sold for 2 & 4 wheelers resp for FY 2024
with cte as
(select state,vehicle_category, sum(electric_vehicles_sold) as total_ev_sold, sum(total_vehicles_sold) as total_vehicle
from electric_vehicle_sales_by_state
where dates between '2023-04-01' and '2024-03-31'
group by state,vehicle_category),

penetration_rate as
(select state, 
	max(case when vehicle_category = '2-Wheelers' then round((total_ev_sold/total_vehicle) * 100,2) end) as penetration_rate_2_wheeler,
    max(case when vehicle_category = '4-Wheelers' then round((total_ev_sold/total_vehicle) * 100,2) end) as penetration_rate_4_wheeler
from cte
group by state)

-- top 5 states for highest penetration rate for 2-w
select state, penetration_rate_2_wheeler
from penetration_rate
order by penetration_rate_2_wheeler desc
limit 5;

-- top 5 states for highest penetration rate for 4-w
select state, penetration_rate_4_wheeler
from penetration_rate
order by penetration_rate_4_wheeler desc
limit 5;


-- Q3
-- statewise total ev sold and total vehicles sold for year 2022 and 2024
with cte as
(select evs.state, dd.fiscal_year, sum(evs.electric_vehicles_sold) as total_ev_sold, sum(evs.total_vehicles_sold) as total_vehicle
from electric_vehicle_sales_by_state evs
join dim_date dd
on evs.dates = dd.dates
group by evs.state, dd.fiscal_year),

-- calculate penetration rate
penetration_rate as
(select state, fiscal_year, round((total_ev_sold/total_vehicle) * 100,2) as penetration_rate
from cte)

-- formatted output displaying the year wise penetration rate for each state along with its difference
select state,
		max(case when fiscal_year = 2022 then penetration_rate else 0 end) as "2022",
        max(case when fiscal_year = 2024 then penetration_rate else 0 end) as "2024",
        max(case when fiscal_year = 2024 then penetration_rate else 0 end) - max(case when fiscal_year = 2022 then penetration_rate else 0 end) as difference
from penetration_rate
group by state;


-- Q4
-- combine electric vehicle sales data with date-related information (to get the quarter)
with cte as
(select ev.dates as dates_,ev.vehicle_category, ev.maker, ev.electric_vehicles_sold, dd.*
from electric_vehicle_sales_by_makers ev
join dim_date dd
on ev.dates = dd.dates
where vehicle_category = '4-Wheelers'),

-- find the top 5 makers based on the number of total EV sold
top_5_maker as
(
 select maker, sum(electric_vehicles_sold) as total_vehicles
from electric_vehicle_sales_by_makers
where vehicle_category = '4-Wheelers'
group by maker
order by total_vehicles desc
limit 5
)

-- aggregate the electric vehicle sales for the top 5 makers by fiscal year and quarter
select maker, fiscal_year, quarter, sum(electric_vehicles_sold) as total_vehicles
from cte
where maker in (select maker from top_5_maker)
group by  maker, fiscal_year, quarter
order by maker;


-- Q5
select ev.state, sum(ev.electric_vehicles_sold) as total_ev, (sum(ev.electric_vehicles_sold)/sum(ev.total_vehicles_sold) *100 ) as penetration_rate
from electric_vehicle_sales_by_state ev
join dim_date dd
on ev.dates = dd.dates
where ev.state in ('Delhi', 'Karnataka') and dd.fiscal_year = 2024
group by ev.state;


-- Q6
-- filter the data for 4-W category for FY 2022(beginning value) & 2024(ending value)
with cte as
(select evm.maker, dd.fiscal_year, sum(evm.electric_vehicles_sold) as total_ev_sold
from electric_vehicle_sales_by_makers evm
join dim_date dd
on evm.dates = dd.dates
where evm.vehicle_category = '4-Wheelers' and dd.fiscal_year in (2022,2024)
group by evm.maker, dd.fiscal_year),

-- find the top 5 makers based on the number of total EV sold
top_5_maker as
(
 select maker, sum(electric_vehicles_sold) as total_vehicles
from electric_vehicle_sales_by_makers
where vehicle_category = '4-Wheelers'
group by maker
order by total_vehicles desc
limit 5
)

-- calculate the cagr
select maker, round(((pow(max(total_ev_sold) / min(total_ev_sold), 1/2))-1) ,2) as cagr
from cte
where maker in (select maker from top_5_maker)
group by maker
order by maker;


-- Q7
-- records for the fiscal year 2022 and 2024
with cte as
(select ev.state, dd.fiscal_year, sum(ev.total_vehicles_sold) as total_vehicles
from electric_vehicle_sales_by_state ev
join dim_date dd
on ev.dates = dd.dates
where dd.fiscal_year in (2022,2024)
group by ev.state, dd.fiscal_year),

-- find the top 10 states based on the number of total vehicles sold
top_10_states as
(
 select state, sum(total_vehicles_sold) as t_v
from electric_vehicle_sales_by_state
group by state
order by t_v desc
limit 10
)

-- CAGR for top 10 states
select state, round(((pow(max(total_vehicles) / min(total_vehicles), 1/2))-1) * 100 ,2) as cagr
from cte
where state in (select state from top_10_states)
group by  state
order by cagr desc;

-- Q8
select monthname(dates) as month_name, sum(electric_vehicles_sold) as total_ev_sold
from electric_vehicle_sales_by_makers
group by monthname(dates)
order by total_ev_sold desc;


-- Q9
-- filter the data to get the beginning(2022) and ending values(2024) to calculate CAGR
with state_ev as
(select ev.state, dd.fiscal_year, sum(ev.electric_vehicles_sold) as total_ev
from electric_vehicle_sales_by_state ev
join dim_date dd
on ev.dates = dd.dates
where dd.fiscal_year in (2022,2024)
group by state,fiscal_year),

-- calculate CAGR
state_cagr as
(select state, round(((pow(max(total_ev) / min(total_ev), 1/2))-1) ,2) as cagr
from state_ev
group by state),

-- filter the data to get the current year sales values (2024 here) for calculating projected sales
state_2024 as
(
select *
from state_ev
where fiscal_year = 2024
)

-- calculate the projected sales as (current value * (1+CAGR) ^ n ) and sort the data accordingly
select sc.state, round(sd.total_ev * pow((1+sc.cagr),6),2) as projected_sales_2030
from state_cagr sc
join state_2024 sd
on sc.state = sd.state
-- get the top 10 states by the penetration rate 
join (select state
				from electric_vehicle_sales_by_state
				group by state
				order by sum(electric_vehicles_sold) / sum(total_vehicles_sold) * 100 desc
				limit 10) as pr
on sc.state = pr.state
order by projected_sales_2030 desc;


-- Q10
-- calculate the revenue 
with revenue_cte as
(select dd.fiscal_year,ev.vehicle_category, sum(electric_vehicles_sold) as total_ev_sold,
	  case when vehicle_category = '2-Wheelers' then sum(electric_vehicles_sold) * 85000 
		   when vehicle_category = '4-Wheelers' then sum(electric_vehicles_sold) * 1500000
           end as revenue
from electric_vehicle_sales_by_makers ev
join dim_date dd 
on ev.dates = dd.dates
group by dd.fiscal_year, ev.vehicle_category)

-- revenue_growth_rate = new_value - old value / old value * 100
select vehicle_category, ((max(revenue) - min(revenue))/min(revenue)) * 100 as rgr_2022_2024
from revenue_cte
where fiscal_year in (2022,2024)
group by vehicle_category;
 
-- same cte used (revenue_cte)
select vehicle_category, ((max(revenue) - min(revenue))/min(revenue)) * 100 as rgr_2023_2024
from revenue_cte
where fiscal_year in (2023,2024)
group by vehicle_category;
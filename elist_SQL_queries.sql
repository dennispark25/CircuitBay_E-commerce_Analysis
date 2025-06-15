-- What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years?

select date_trunc(orders.purchase_ts, quarter) as purchase_quarter,
  count(distinct orders.id) as order_count,
  round(sum(orders.usd_price), 2) as total_sales,
  round(avg(orders.usd_price), 2) as aov
from core.orders
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup
  on customers.country_code = geo_lookup.country
where region = 'NA'
  and lower(orders.product_name) like '%macbook%'
group by 1
order by 1 desc;

-- What is the average quarterly order count and total sales for Macbooks sold in North America? (i.e. “For North America Macbooks, average of X units sold per quarter and Y in dollar sales per quarter”)

with quarterly_metrics as (
  select date_trunc(orders.purchase_ts, quarter) as purchase_quarter,
    count(distinct orders.id) as order_count,
    round(sum(orders.usd_price), 2) as total_sales,
  from core.orders
  left join core.customers 
    on orders.customer_id = customers.id
  left join core.geo_lookup
    on customers.country_code = geo_lookup.country
  where region = 'NA'
    and lower(orders.product_name) like '%macbook%'
  group by 1
  order by 1 desc
)

select round(avg(order_count), 2) as quarterly_order_count,
  round(avg(total_sales), 2) as quarterly_sales
from quarterly_metrics;

-- For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver?

select geo_lookup.region as region,
  avg(date_diff(order_status.delivery_ts, order_status.purchase_ts, day)) as avg_days_to_deliver
from core.order_status
left join core.orders
  on orders.id = order_status.order_id
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup
  on customers.country_code = geo_lookup.country
where (extract(year from orders.purchase_ts) = 2022 and orders.purchase_platform = 'website')
  or (orders.purchase_platform = 'mobile app')
group by 1
order by 2 desc;

-- What was the refund rate and refund count for each product overall?

select case when orders.product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as cleaned_product_name, 
  round(avg(case when order_status.refund_ts is not null then 1 else 0 end) * 100.0, 2) as refund_rate,
  sum(case when order_status.refund_ts is not null then 1 end) as refund_count
from core.orders
left join core.order_status
  on orders.id = order_status.order_id
group by 1
order by 3 desc;

-- Within each region, what is the most popular product?

with regional_product_orders as (
  select geo_lookup.region as region,
    case when orders.product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as cleaned_product_name,
    count(distinct orders.id) as order_count
  from core.orders
  left join core.customers
    on orders.customer_id = customers.id
  left join core.geo_lookup
    on customers.country_code = geo_lookup.country
  group by 1,2
  order by 1,3 desc
)

select *,
  row_number() over (partition by region order by order_count desc) as order_count_rank
from regional_product_orders
qualify order_count_rank = 1
order by order_count desc;

-- How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers?

select customers.loyalty_program as is_loyalty,
  round(avg(date_diff(order_status.purchase_ts, customers.created_on, day)), 2) as avg_days_to_purchase,
  round(avg(date_diff(order_status.purchase_ts, customers.created_on, month)), 2) as avg_months_to_purchase
from core.order_status
left join core.orders
  on order_status.order_id = orders.id
left join core.customers
  on orders.customer_id = customers.id
group by 1;


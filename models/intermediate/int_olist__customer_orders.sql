-- Grain: one row per customer_unique_id

with order_details as (

    select *
    from {{ ref('int_olist__order_details') }}

),

customers as (

    select *
    from {{ ref('stg_olist__customers') }}

),

customer_orders as (

    select
        c.customer_unique_id,

        min(od.order_purchased_at) as first_order_at,
        max(od.order_purchased_at) as last_order_at,

        count(distinct od.order_id) as lifetime_order_count,

        sum(od.total_price_per_item) as lifetime_revenue,

        sum(od.total_price_per_item)
            / nullif(count(distinct od.order_id),0) as avg_order_value,

        avg(case when od.is_delivered then od.days_to_deliver_actual end)
            as avg_actual_delivery_days,

        avg(case when od.is_delivered then od.days_to_deliver_estimated end)
            as avg_estimated_delivery_days,

        sum(case when od.is_late then 1 else 0 end)
            as late_delivery_count,

        sum(case when od.is_delivered then 1 else 0 end)
            as delivered_order_count,

        round(
            sum(case when od.is_late then 1 else 0 end) * 100.0
            / nullif(sum(case when od.is_delivered then 1 else 0 end),0),
            2
        ) as late_delivery_percentage

    from customers c

    left join order_details od
        on c.customer_id = od.customer_id

    group by
        c.customer_unique_id

)

select * from customer_orders
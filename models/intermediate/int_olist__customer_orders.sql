-- models/intermediate/int_olist__customer_orders.sql
-- Grain: one row per customer_unique_id
-- Aggregates order behavior and delivery performance metrics per customer

with order_details as (

    select *
    from {{ ref('int_olist__order_details') }}

),

customers as (

    select *
    from {{ ref('stg_olist__customers') }}

),

-- Roll up item-level data to order-level first
orders_rollup as (

    select
        order_id,
        customer_unique_id,

        min(order_purchased_at) as order_purchased_at,

        sum(total_price_per_item) as order_revenue,

        max(days_to_deliver_actual) as days_to_deliver_actual,
        max(days_to_deliver_estimated) as days_to_deliver_estimated,

        max(is_delivered) as is_delivered,
        max(is_late) as is_late

    from order_details

    group by
        order_id,
        customer_unique_id

),

customer_orders as (

    select
        c.customer_unique_id,

        min(o.order_purchased_at) as first_order_at,
        max(o.order_purchased_at) as last_order_at,

        count(distinct o.order_id) as lifetime_order_count,

        sum(o.order_revenue) as lifetime_revenue,

        sum(o.order_revenue)
            / nullif(count(distinct o.order_id),0) as avg_order_value,

        avg(case when o.is_delivered then o.days_to_deliver_actual end)
            as avg_actual_delivery_days,

        avg(case when o.is_delivered then o.days_to_deliver_estimated end)
            as avg_estimated_delivery_days,

        sum(case when o.is_late then 1 else 0 end)
            as late_delivery_count,

        sum(case when o.is_delivered then 1 else 0 end)
            as delivered_order_count,

        round(
            sum(case when o.is_late then 1 else 0 end) * 100.0
            / nullif(sum(case when o.is_delivered then 1 else 0 end),0),
            2
        ) as late_delivery_percentage,

        case
            when count(distinct o.order_id) > 1 then true
            else false
        end as is_repeat_customer

    from customers c

    left join orders_rollup o
        on c.customer_unique_id = o.customer_unique_id

    group by
        c.customer_unique_id

)

select * from customer_orders
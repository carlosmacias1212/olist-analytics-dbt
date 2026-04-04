-- models/marts/sales/fct_orders.sql
-- Grain: one row per order
-- Central fact table for order-level analytics

{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}

with order_details as (
    select *
    from {{ ref('int_olist__order_details') }}

    {% if is_incremental() %}
        where loaded_at > (
            select coalesce(max(loaded_at), '1900-01-01'::timestamp)
            from {{ this }}
        )
    {% endif %}
),

orders_rollup as (
    select
        order_id,
        customer_unique_id,

        min(order_purchased_at) as order_purchased_at,
        max(order_status) as order_status,

        -- revenue metrics
        sum(total_price_per_item) as order_revenue,
        sum(item_price) as product_revenue,
        sum(item_freight) as freight_revenue,

        -- item metrics
        count(*) as total_items,
        count(distinct product_id) as num_distinct_products,

        -- delivery metrics
        max(days_to_deliver_actual) as days_to_deliver_actual,
        max(days_to_deliver_estimated) as days_to_deliver_estimated,

        -- KPI flags
        max(is_delivered) as is_delivered,
        max(is_late) as is_late,

        -- 👇 CRITICAL for incremental tracking
        max(loaded_at) as loaded_at

    from order_details
    group by
        order_id,
        customer_unique_id
)

select *
from orders_rollup

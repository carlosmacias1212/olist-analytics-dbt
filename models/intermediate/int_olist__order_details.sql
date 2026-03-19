-- models/intermediate/int_olist__order_details.sql
-- Grain: one row per order_item
-- Combines staging orders, order_items, and payments into a single enriched table
-- Includes aggregated and derived fields for downstream marts and analytics

with orders as (
    select *
    from {{ ref('stg_olist__orders') }}
),

order_items as (
    select *
    from {{ ref('stg_olist__order_items') }}
),

payments as (
    select *
    from {{ ref('stg_olist__payments') }}
),

customers as (
    select *
    from {{ ref('stg_olist__customers') }}
),

-- Aggregate payments per order
order_totals as (
    select
        order_id,
        sum(payment_value) as total_payment_value,
        max(payment_installments) as max_installments,
        count(distinct payment_type) as order_payment_type_count
    from payments
    group by order_id
),

-- Combine items, orders, and aggregated payments
order_details as (
    select
        -- Identifiers
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        c.customer_unique_id,

        -- Order-level info
        o.order_status,
        o.order_purchased_at,
        o.order_approved_at,
        o.order_delivered_to_carrier_at,
        o.order_delivered_at,
        o.order_estimated_delivery_at,

        -- Aggregated metrics
        ot.total_payment_value,
        ot.max_installments,
        ot.order_payment_type_count,

        -- Item-level metrics
        oi.price as item_price,
        oi.freight_value as item_freight,
        (oi.price + oi.freight_value) as total_price_per_item,

        -- Derived metrics (null-safe)
        case 
            when o.order_delivered_at is not null
            then datediff(day, o.order_purchased_at, o.order_delivered_at)
        end as days_to_deliver_actual,

        case
            when o.order_estimated_delivery_at is not null
            then datediff(day, o.order_purchased_at, o.order_estimated_delivery_at)
        end as days_to_deliver_estimated,

        -- Optional KPI flags
        case when o.order_delivered_at is not null then true else false end as is_delivered,
        case 
            when o.order_delivered_at is not null 
                 and o.order_estimated_delivery_at is not null
                 and o.order_delivered_at > o.order_estimated_delivery_at
            then true 
            else false 
        end as is_late
    from order_items oi
    left join orders o on oi.order_id = o.order_id
    left join order_totals ot on oi.order_id = ot.order_id
    left join customers c on o.customer_id = c.customer_id
)

select * from order_details
-- models/marts/dimensions/dim_customers.sql
-- Grain: one row per customer_unique_id
-- Customer dimension with lifetime metrics

with customers as (

    select
        customer_unique_id,
        min(customer_zip_code_prefix) as customer_zip_code_prefix,
        min(customer_city) as customer_city,
        min(customer_state) as customer_state
    from {{ ref('stg_olist__customers') }}
    group by customer_unique_id

),

customer_metrics as (

    select
        customer_unique_id,
        first_order_at,
        last_order_at,
        lifetime_order_count,
        lifetime_revenue,
        avg_order_value,
        avg_actual_delivery_days,
        avg_estimated_delivery_days,
        late_delivery_count,
        delivered_order_count,
        late_delivery_percentage
    from {{ ref('int_olist__customer_orders') }}

),

final as (

    select
        cm.customer_unique_id,

        -- location attributes
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,

        -- lifecycle metrics
        cm.first_order_at,
        cm.last_order_at,

        -- purchase metrics
        cm.lifetime_order_count,
        cm.lifetime_revenue,
        cm.avg_order_value,

        -- delivery metrics
        cm.avg_actual_delivery_days,
        cm.avg_estimated_delivery_days,
        cm.late_delivery_count,
        cm.delivered_order_count,
        cm.late_delivery_percentage

    from customer_metrics cm
    left join customers c
        on cm.customer_unique_id = c.customer_unique_id

)

select *
from final
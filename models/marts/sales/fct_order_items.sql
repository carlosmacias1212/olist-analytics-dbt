-- models/marts/sales/fct_order_items.sql
-- Grain: one row per order item

with order_details as (

    select *
    from {{ ref('int_olist__order_details') }}

),

final as (

    select

        -- identifiers
        order_id,
        order_item_id,
        product_id,
        seller_id,

        -- timestamps
        order_purchased_at,
        order_delivered_at,

        -- revenue metrics
        item_price,
        item_freight,
        total_price_per_item,

        -- delivery metrics
        days_to_deliver_actual,
        days_to_deliver_estimated,

        -- flags
        is_delivered,
        is_late

    from order_details

)

select *
from final
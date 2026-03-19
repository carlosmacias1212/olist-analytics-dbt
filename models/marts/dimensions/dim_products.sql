-- models/marts/dimensions/dim_products.sql
-- Grain: one row per product

with products as (

    select
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    from {{ ref('stg_olist__products') }}

),

category_translation as (

    select
        product_category_name,
        product_category_name_english
    from {{ ref('stg_olist__product_category_translation') }}

),

final as (

    select
        p.product_id,

        -- category
        p.product_category_name,
        ct.product_category_name_english as product_category,

        -- descriptive attributes
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,

        -- physical attributes
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm

    from products p
    left join category_translation ct
        on p.product_category_name = ct.product_category_name

)

select *
from final
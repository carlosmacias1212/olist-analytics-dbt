-- models/marts/dimensions/dim_sellers.sql
-- Grain: one row per seller

with sellers as (

    select
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    from {{ ref('stg_olist__sellers') }}

)

select *
from sellers
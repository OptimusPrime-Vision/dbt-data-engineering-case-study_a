{{
    config(materialized='table', tags=['marts','core','dimension'])
}}
-- dim_products: product catalogue with standard list price
-- Grain: one row per Salesforce Product2

with products as (
    select * from {{ ref('stg_salesforce__product_2') }}
),

standard_prices as (
    select
        product2id,
        unitprice as list_price
    from {{ ref('stg_salesforce__pricebook_entry') }}
    where usestandardprice = true
    qualify row_number() over (partition by product2id order by unitprice desc) = 1
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
        p.product_id,
        p.name          as product_name,
        p.productcode,
        p.description,
        p.family        as product_family,
        p.isactive,
        sp.list_price,
        p.createddate
    from products p
    left join standard_prices sp on p.product_id = sp.product2id
)

select * from final

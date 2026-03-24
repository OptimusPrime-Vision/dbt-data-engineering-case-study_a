{{
    config(materialized='table', tags=['marts','finance','fact'])
}}


with line_items as (
    select * from {{ ref('stg_salesforce__pricebook_entry') }}
),



opportunities as (
    select
        opportunity_id,
        accountid,
        ownerid,
        iswon,
        isclosed,
        closedate,
        stagename
    from {{ ref('stg_salesforce__opportunity') }}
),

dim_accounts as (
    select account_id, account_key from {{ ref('dim_accounts') }}
),

dim_users as (
    select user_id, user_key from {{ ref('dim_users') }}
),

dim_products as (
    select product_id, product_key from {{ ref('dim_products') }}
),

pricebook_with_dims as (
    select
        li.pricebook_entry_id,
        li.product2id,
        li.pricebook2id,
        li.unitprice,
        li.isactive,
        li.usestandardprice,
        prd.product_key
    from {{ ref('stg_salesforce__pricebook_entry') }} li
    left join dim_products prd on li.product2id = prd.product_id
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['pb.pricebook_entry_id']) }} as line_item_key,

        -- dimension FKs
        prd.product_key,

        -- natural keys
        pb.pricebook_entry_id,
        pb.product2id           as product_id,
        pb.pricebook2id,

        -- measures
        pb.unitprice            as unit_price,

        -- flags
        pb.isactive,
        pb.usestandardprice

    from {{ ref('stg_salesforce__pricebook_entry') }} pb
    left join dim_products prd on pb.product2id = prd.product_id
)

select * from final

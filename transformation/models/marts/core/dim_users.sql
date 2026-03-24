{{
    config(materialized='table', tags=['marts','core','dimension'])
}}
-- dim_users: sales rep dimension with performance metrics and role hierarchy
-- Grain: one row per Salesforce user

with reps as (
    select * from {{ ref('int_sales_rep_metrics') }}
),

user_roles as (
    select user_role_id, name as role_name
    from {{ ref('stg_salesforce__user_role') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['r.user_id']) }}   as user_key,

        -- natural key
        r.user_id,

        -- attributes
        r.full_name,
        r.email,
        r.title,
        r.department,
        r.userroleid,
        ur.role_name,
        r.isactive,

        -- performance metrics
        r.total_opportunities,
        r.won_opportunities,
        r.total_pipeline,
        r.total_revenue,
        r.avg_deal_size,
        r.win_rate_pct,

        -- revenue quartile: 1 = top performer, 4 = bottom (window function in int layer)
        r.revenue_quartile,

        -- dates
        r.createddate

    from reps r
    left join user_roles ur on r.userroleid = ur.user_role_id
)

select * from final

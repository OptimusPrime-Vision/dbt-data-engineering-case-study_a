{{
    config(materialized='table', tags=['marts','core','dimension'])
}}
-- dim_accounts: conformed account dimension with surrogate key and pre-computed KPIs
-- Grain: one row per Salesforce account

with accounts as (
    select * from {{ ref('int_accounts_with_metrics') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['account_id']) }}  as account_key,

        -- natural key
        account_id,
        ownerid,

        -- descriptive attributes
        account_name,
        account_type,
        industry,
        billingcountry,
        annualrevenue,
        numberofemployees,
        rating,
        accountsource,

        -- pre-computed KPIs (denormalised for BI tool performance)
        total_opportunities,
        won_opportunities,
        lost_opportunities,
        open_opportunities,
        total_pipeline_amount,
        total_won_amount,
        avg_deal_size,
        win_rate_pct,
        total_cases,
        open_cases,
        high_priority_cases,
        total_contacts,
        account_health_tier,

        -- dates
        createddate,
        first_opportunity_date,
        latest_opportunity_date

    from accounts
)

select * from final

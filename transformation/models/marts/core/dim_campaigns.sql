{{
    config(materialized='table', tags=['marts','core','dimension'])
}}
-- dim_campaigns: marketing campaign dimension with ROI metrics
-- Grain: one row per Salesforce Campaign

with campaigns as (
    select * from {{ ref('stg_salesforce__campaign') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['campaign_id']) }}  as campaign_key,
        campaign_id,
        ownerid,
        name            as campaign_name,
        type            as campaign_type,
        status          as campaign_status,
        isactive,
        budgetedcost,
        actualcost,
        expectedrevenue,
        amountwonopportunities                                   as actual_revenue,

        -- ROI: (revenue - cost) / cost * 100
        {{ safe_divide('(amountwonopportunities - actualcost) * 100.0', 'actualcost') }} as roi_pct,

        numberofleads,
        numberofconvertedleads,
        numberofopportunities,
        numberofwonopportunities,

        -- lead conversion rate
        {{ safe_divide('numberofconvertedleads * 100.0', 'numberofleads') }} as lead_conversion_rate_pct,

        startdate,
        enddate,
        date_diff('day', startdate, enddate) as campaign_duration_days,
        createddate
    from campaigns
)

select * from final

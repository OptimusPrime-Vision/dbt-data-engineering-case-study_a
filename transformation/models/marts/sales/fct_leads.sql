{{
    config(materialized='table', tags=['marts','sales','fact'])
}}
-- fct_leads: lead funnel fact table
-- Grain: one row per lead

with leads as (
    select * from {{ ref('int_lead_funnel') }}
),

dim_users as (
    select user_id, user_key from {{ ref('dim_users') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['lead_id']) }}     as lead_key,

        -- dimension foreign keys
        usr.user_key                                            as owner_key,

        -- date foreign keys
        cast(l.createddate as date)                             as created_date_id,
        cast(l.converteddate as date)                           as converted_date_id,

        -- natural keys
        l.lead_id,
        l.ownerid,
        l.convertedopportunityid,
        l.convertedaccountid,

        -- degenerate dimensions
        l.leadsource,
        l.lead_status,
        l.industry,
        l.country,
        l.funnel_stage,
        l.rating,

        -- flags
        l.isconverted,

        -- measures
        l.days_to_conversion,
        l.annualrevenue,
        l.numberofemployees,

        -- timestamps
        l.createddate,
        l.lastmodifieddate

    from leads          l
    left join dim_users usr on l.ownerid = usr.user_id
)

select * from final

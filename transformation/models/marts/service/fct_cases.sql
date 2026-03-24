{{
    config(materialized='table', tags=['marts','service','fact'])
}}
-- fct_cases: customer service fact table
-- Grain: one row per case. Includes SLA classification.

with cases as (
    select * from {{ ref('int_case_resolution') }}
),

dim_accounts as (
    select account_id, account_key from {{ ref('dim_accounts') }}
),

dim_users as (
    select user_id, user_key from {{ ref('dim_users') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['c.case_id']) }}   as case_key,

        -- dimension foreign keys
        acc.account_key,
        usr.user_key                                            as owner_key,

        -- date foreign keys
        cast(c.createddate as date)                             as created_date_id,
        cast(c.closeddate  as date)                             as closed_date_id,

        -- natural keys
        c.case_id,
        c.accountid,
        c.contactid,
        c.ownerid,

        -- degenerate dimensions
        c.casenumber,
        c.case_type,
        c.status,
        c.priority,
        c.origin,
        c.reason,
        c.subject,

        -- flags
        c.isclosed,
        c.isescalated,

        -- measures
        c.resolution_hours,
        c.resolution_target_hours,
        c.total_field_changes,
        c.status_changes,

        -- SLA classification (derived in intermediate layer)
        c.sla_status,

        -- timestamps
        c.createddate,
        c.closeddate

    from cases          c
    left join dim_accounts  acc on c.accountid = acc.account_id
    left join dim_users     usr on c.ownerid   = usr.user_id
)

select * from final

{{
    config(materialized='table', tags=['marts','sales','fact'])
}}


with opps as (
    select * from {{ ref('int_opportunities_enriched') }}
),

dim_accounts as (
    select account_id, account_key from {{ ref('dim_accounts') }}
),

dim_users as (
    select user_id, user_key from {{ ref('dim_users') }}
),

dim_campaigns as (
    select campaign_id, campaign_key from {{ ref('dim_campaigns') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['opp.opportunity_id']) }} as opportunity_key,

        -- dimension foreign keys
        acc.account_key,
        usr.user_key                                            as owner_key,
        cam.campaign_key,

        -- date foreign keys
        cast(opp.closedate as date)                             as close_date_id,
        cast(opp.createddate as date)                           as created_date_id,

        -- natural keys (kept for debugging)
        opp.opportunity_id,
        opp.accountid,
        opp.ownerid,

        -- degenerate dimensions
        opp.opportunity_name,
        opp.stagename,
        opp.opportunity_type,
        opp.leadsource,
        opp.forecastcategory,
        opp.deal_size_tier,
        opp.deal_status,

        -- measures
        opp.amount,
        opp.probability,
        opp.expectedrevenue,
        opp.days_to_close,
        opp.weighted_amount,

        -- flags
        opp.isclosed,
        opp.iswon,

        -- window metrics
        opp.owner_running_pipeline,
        opp.opp_rank_in_account,
        opp.prev_opp_amount_same_account,

        -- timestamps
        opp.createddate,
        opp.lastmodifieddate

    from opps           opp
    left join dim_accounts  acc on opp.accountid  = acc.account_id
    left join dim_users     usr on opp.ownerid    = usr.user_id
    left join dim_campaigns cam on opp.campaignid = cam.campaign_id
)

select * from final

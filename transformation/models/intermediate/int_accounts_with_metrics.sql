{{
    config(
        materialized = 'table',
        tags         = ['intermediate', 'sales']
    )
}}


with accounts as (

    select * from {{ ref('stg_salesforce__account') }}

),

opportunity_agg as (

    select
        accountid,
        count(*)                                               as total_opportunities,
        count(*) filter (where iswon)                          as won_opportunities,
        count(*) filter (where isclosed and not iswon)         as lost_opportunities,
        count(*) filter (where not isclosed)                   as open_opportunities,
        sum(amount)                                            as total_pipeline_amount,
        sum(amount) filter (where iswon)                       as total_won_amount,
        avg(amount)                                            as avg_deal_size,
        max(amount)                                            as largest_deal_amount,
        min(createddate)                                       as first_opportunity_date,
        max(createddate)                                       as latest_opportunity_date
    from {{ ref('stg_salesforce__opportunity') }}
    group by 1

),

case_agg as (

    select
        accountid,
        count(*)                                               as total_cases,
        count(*) filter (where isclosed)                       as closed_cases,
        count(*) filter (where not isclosed)                   as open_cases,
        count(*) filter (
            where priority in ('High', 'Critical')
        )                                                      as high_priority_cases
    from {{ ref('stg_salesforce__case') }}
    group by 1

),

contact_agg as (

    select
        accountid,
        count(*)                                               as total_contacts
    from {{ ref('stg_salesforce__contact') }}
    group by 1

),

final as (

    select

        acc.account_id,
        acc.ownerid,


        acc.name                                               as account_name,
        acc.type                                               as account_type,
        acc.industry,
        acc.billingcountry,
        acc.annualrevenue,
        acc.numberofemployees,
        acc.rating,
        acc.accountsource,
        acc.createddate,


        coalesce(opp.total_opportunities, 0)                   as total_opportunities,
        coalesce(opp.won_opportunities, 0)                     as won_opportunities,
        coalesce(opp.lost_opportunities, 0)                    as lost_opportunities,
        coalesce(opp.open_opportunities, 0)                    as open_opportunities,
        coalesce(opp.total_pipeline_amount, 0)                 as total_pipeline_amount,
        coalesce(opp.total_won_amount, 0)                      as total_won_amount,
        opp.avg_deal_size,
        opp.largest_deal_amount,
        opp.first_opportunity_date,
        opp.latest_opportunity_date,


        {{ safe_divide('opp.won_opportunities * 100.0', 'opp.total_opportunities') }}
                                                               as win_rate_pct,


        coalesce(cs.total_cases, 0)                            as total_cases,
        coalesce(cs.closed_cases, 0)                           as closed_cases,
        coalesce(cs.open_cases, 0)                             as open_cases,
        coalesce(cs.high_priority_cases, 0)                    as high_priority_cases,


        coalesce(ct.total_contacts, 0)                         as total_contacts,


        case
            when coalesce(opp.total_won_amount, 0) >= 500000  then 'Platinum'
            when coalesce(opp.total_won_amount, 0) >= 100000  then 'Gold'
            when coalesce(opp.total_won_amount, 0) >= 25000   then 'Silver'
            else                                                    'Bronze'
        end                                                    as account_health_tier

    from accounts             acc
    left join opportunity_agg opp on acc.account_id = opp.accountid
    left join case_agg        cs  on acc.account_id = cs.accountid
    left join contact_agg     ct  on acc.account_id = ct.accountid

)

select * from final

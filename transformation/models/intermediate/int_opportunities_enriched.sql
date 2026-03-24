{{
    config(
        materialized = 'table',
        tags         = ['intermediate', 'sales']
    )
}}


with opportunities as (

    select * from {{ ref('stg_salesforce__opportunity') }}

),

accounts as (

    select
        account_id,
        name             as account_name,
        type             as account_type,
        industry,
        billingcountry,
        annualrevenue
    from {{ ref('stg_salesforce__account') }}

),

users as (

    select
        user_id,
        firstname || ' ' || lastname   as owner_full_name,
        department                     as owner_department,
        title                          as owner_title
    from {{ ref('stg_salesforce__user') }}

),

enriched as (

    select
      
        opp.opportunity_id,
        opp.accountid,
        opp.ownerid,
        opp.campaignid,

       
        opp.name                                                     as opportunity_name,
        opp.stagename,
        opp.type                                                     as opportunity_type,
        opp.leadsource,
        opp.forecastcategory,
        opp.amount,
        opp.probability,
        opp.expectedrevenue,
        opp.isclosed,
        opp.iswon,
        opp.closedate,
        opp.createddate,
        opp.lastmodifieddate,

     
        acc.account_name,
        acc.account_type,
        acc.industry,
        acc.billingcountry,
        acc.annualrevenue                                            as account_annual_revenue,

       
        usr.owner_full_name,
        usr.owner_department,
        usr.owner_title,

      
        {{ classify_deal_size('opp.amount') }}                      as deal_size_tier,

       
        case
            when opp.iswon                    then 'Won'
            when opp.isclosed                 then 'Lost'
            when opp.closedate < current_date then 'Overdue'
            else                                   'Open'
        end                                                          as deal_status,

     
        date_diff('day',
            cast(opp.createddate as date),
            cast(opp.closedate   as date)
        )                                                            as days_to_close,

     
        round(opp.amount * opp.probability / 100.0, 2)              as weighted_amount,

     
        sum(opp.amount) over (
            partition by opp.ownerid
            order by     opp.createddate
            rows between unbounded preceding and current row
        )                                                            as owner_running_pipeline,

     
        row_number() over (
            partition by opp.accountid
            order by     opp.amount desc nulls last
        )                                                            as opp_rank_in_account,


        lag(opp.amount) over (
            partition by opp.accountid
            order by     opp.createddate
        )                                                            as prev_opp_amount_same_account

    from opportunities  opp
    left join accounts  acc on opp.accountid = acc.account_id
    left join users     usr on opp.ownerid   = usr.user_id

)

select * from enriched

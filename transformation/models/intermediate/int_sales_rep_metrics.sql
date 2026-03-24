{{
    config(
        materialized = 'table',
        tags         = ['intermediate', 'sales']
    )
}}



with users as (

    select * from {{ ref('stg_salesforce__user') }}

),

opp_agg as (

    select
        ownerid,
        count(*)                                               as total_opportunities,
        count(*) filter (where iswon)                          as won_opportunities,
        count(*) filter (where isclosed and not iswon)         as lost_opportunities,
        count(*) filter (where not isclosed)                   as open_opportunities,
        sum(amount)                                            as total_pipeline,
        sum(amount) filter (where iswon)                       as total_revenue,
        avg(amount)                                            as avg_deal_size,
        avg(probability)                                       as avg_probability
    from {{ ref('stg_salesforce__opportunity') }}
    group by 1

),

final as (

    select
     
        usr.user_id,

    
        usr.firstname || ' ' || usr.lastname                   as full_name,
        usr.email,
        usr.title,
        usr.department,
        usr.userroleid,
        usr.isactive,
        usr.createddate,

    
        coalesce(opp.total_opportunities, 0)                   as total_opportunities,
        coalesce(opp.won_opportunities, 0)                     as won_opportunities,
        coalesce(opp.lost_opportunities, 0)                    as lost_opportunities,
        coalesce(opp.open_opportunities, 0)                    as open_opportunities,
        coalesce(opp.total_pipeline, 0)                        as total_pipeline,
        coalesce(opp.total_revenue, 0)                         as total_revenue,
        opp.avg_deal_size,
        opp.avg_probability,

    
        {{ safe_divide('opp.won_opportunities * 100.0', 'opp.total_opportunities') }}
                                                               as win_rate_pct,

    
        ntile(4) over (
            order by coalesce(opp.total_revenue, 0) desc
        )                                                      as revenue_quartile

    from users          usr
    left join opp_agg   opp on usr.user_id = opp.ownerid

)

select * from final

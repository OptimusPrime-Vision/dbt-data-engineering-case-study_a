-- Run: dbt compile 
with pipeline as (
    select
        f.stagename,
        u.full_name         as sales_rep,
        u.role_name,
        s.stage_order,
        s.stage_category,
        count(*)            as opportunity_count,
        sum(f.amount)       as total_amount,
        sum(f.weighted_amount) as total_weighted_amount,
        avg(f.days_to_close) as avg_days_to_close
    from {{ ref('fct_opportunities') }}    f
    join {{ ref('dim_users') }}            u on f.owner_key = u.user_key
    join {{ ref('stage_pipeline_order') }} s on f.stagename = s.stage_name
    where f.isclosed = false
    group by 1,2,3,4,5
)
select *,
    row_number() over (partition by stagename order by total_amount desc) as rep_rank_in_stage
from pipeline
order by stage_order, rep_rank_in_stage

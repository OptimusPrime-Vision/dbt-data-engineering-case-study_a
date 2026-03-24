{{
    config(
        materialized = 'table',
        tags         = ['intermediate', 'service']
    )
}}

with cases as (

    select * from {{ ref('stg_salesforce__case') }}

),

case_history as (

    select
        caseid,
        count(*) as total_field_changes,
        count(*) as status_changes   
    from {{ ref('stg_salesforce__case_history_2') }}
    group by 1

),

sla_thresholds as (

    select * from {{ ref('sla_thresholds') }}

),

final as (

    select
    
        c.case_id,
        c.accountid,
        c.contactid,
        c.ownerid,

        c.casenumber,
        c.subject,
        c.type                          as case_type,
        c.status,
        c.priority,
        c.origin,
        c.reason,
        c.isclosed,
        c.isescalated,

        c.createddate,
        c.closeddate,

        -- resolution time
        date_diff('hour',
            cast(c.createddate as timestamp),
            cast(c.closeddate  as timestamp)
        ) as resolution_hours,

        -- SLA status
        case
            when not c.isclosed then 'Open'
            when date_diff('hour',
                    cast(c.createddate as timestamp),
                    cast(c.closeddate  as timestamp)
                 ) <= sla.resolution_target_hours then 'Within SLA'
            else 'Breached SLA'
        end as sla_status,

        sla.resolution_target_hours as resolution_target_hours,

        -- history metrics
        coalesce(ch.total_field_changes, 0) as total_field_changes,
        coalesce(ch.status_changes, 0)      as status_changes

    from cases c
    left join sla_thresholds sla 
        on c.priority = sla.priority
    left join case_history ch  
        on c.case_id = ch.caseid

)

select * from final
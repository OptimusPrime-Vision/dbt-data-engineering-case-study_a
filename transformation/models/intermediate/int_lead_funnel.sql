{{
    config(
        materialized = 'table',
        tags         = ['intermediate', 'marketing']
    )
}}


with leads as (

    select * from {{ ref('stg_salesforce__lead') }}

),

final as (

    select
    
        l.lead_id,
        l.ownerid,
        l.convertedaccountid,
        l.convertedcontactid,
        l.convertedopportunityid,

    
        l.firstname || ' ' || l.lastname                       as full_name,
        l.company,
        l.email,
        l.phone,
        l.leadsource,
        l.status                                               as lead_status,
        l.industry,
        l.country,
        l.rating,
        l.annualrevenue,
        l.numberofemployees,

    
        l.isconverted,
        l.converteddate,

       
        case
            when l.isconverted
            then date_diff('day',
                    cast(l.createddate as date),
                    cast(l.converteddate as date))
        end                                                    as days_to_conversion,

    
        case
            when l.isconverted                    then '4 - Converted'
            when l.status ilike 'Working%'        then '3 - Working'
            when l.status ilike 'Open%'           then '2 - Open'
            else                                       '1 - Other'
        end                                                    as funnel_stage,

    
        l.createddate,
        l.lastmodifieddate

    from leads l

)

select * from final

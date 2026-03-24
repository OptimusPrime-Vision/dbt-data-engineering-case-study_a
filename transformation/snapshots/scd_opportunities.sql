{% snapshot scd_opportunities %}
{{
    config(
        target_schema = 'snapshots',
        unique_key    = 'opportunity_id',
        strategy      = 'timestamp',
        updated_at    = 'lastmodifieddate',
        tags          = ['snapshots', 'scd2']
    )
}}
select
    opportunity_id, accountid, ownerid, campaignid,
    name, stagename, type, leadsource, forecastcategory,
    amount, probability, isclosed, iswon,
    closedate, createddate, lastmodifieddate
from {{ ref('stg_salesforce__opportunity') }}
{% endsnapshot %}

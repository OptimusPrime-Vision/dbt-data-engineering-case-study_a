{% snapshot scd_accounts %}
{{
    config(
        target_schema = 'snapshots',
        unique_key    = 'account_id',
        strategy      = 'timestamp',
        updated_at    = 'lastmodifieddate',
        tags          = ['snapshots', 'scd2']
    )
}}
select
    account_id, ownerid, name, type, industry,
    billingcountry, annualrevenue, numberofemployees,
    rating, createddate, lastmodifieddate
from {{ ref('stg_salesforce__account') }}
{% endsnapshot %}

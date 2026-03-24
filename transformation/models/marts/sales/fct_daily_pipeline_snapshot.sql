{{
    config(
        materialized     = 'incremental',
        unique_key       = ['snapshot_date', 'opportunity_id'],
        on_schema_change = 'sync_all_columns',
        tags             = ['marts', 'sales', 'incremental']
    )
}}

-- fct_daily_pipeline_snapshot: incremental daily pipeline waterfall
-- Grain: one row per opportunity per snapshot date

with open_opps as (

    select
        current_date                as snapshot_date,
        opportunity_id,
        account_key,
        owner_key,
        opportunity_name,
        stagename,
        deal_size_tier,
        deal_status,
        amount,
        weighted_amount,
        probability,
        days_to_close,
        isclosed,
        iswon,
        createddate,
        close_date_id               

    from {{ ref('fct_opportunities') }}

    {% if is_incremental() %}
        where cast(lastmodifieddate as date) >= (
            select coalesce(max(snapshot_date), '1900-01-01') from {{ this }}
        )
    {% endif %}

)

select * from open_opps
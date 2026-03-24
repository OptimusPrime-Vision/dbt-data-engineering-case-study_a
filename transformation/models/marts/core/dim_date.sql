{{
    config(materialized='table', tags=['marts','core','dimension'])
}}
-- dim_date: standard date dimension via dbt_date package
-- Covers 2018-01-01 to 2030-12-31 to span all Salesforce history

with date_spine as (
    {{ dbt_date.get_date_dimension(start_date="2018-01-01", end_date="2030-12-31") }}
),

final as (
    select
        date_day                            as date_id,
        day_of_week,
        day_of_week_name,
        day_of_month,
        day_of_year,
        week_of_year,
        month_of_year,
        month_name,
        quarter_of_year,
        year_number,
        cast(year_number as varchar) || '-Q' || cast(quarter_of_year as varchar)                    as year_quarter,
        cast(year_number as varchar) || '-' || lpad(cast(month_of_year as varchar), 2, '0')         as year_month,
        case when day_of_week in (1,7) then true else false end  as is_weekend,
        case when date_day = current_date then true else false end as is_today,
        case when date_day <= current_date then true else false end as is_past_or_today
    from date_spine
)

select * from final

{{
    config(
        materialized='view'
    )
}}

with historical as (

    select
        *,
        'historical' as _dbt_lambda_view_source,
        '{{ run_started_at }}' as _dbt_last_run_at

    from {{ ref('page_views__lambda_historical') }}

    where collector_tstamp < '{{ run_started_at }}'

),

new as (

    select
        *,
        'new' as _dbt_lambda_view_source,
        '{{ run_started_at }}' as _dbt_last_run_at

    from {{ ref('page_views__lambda_current') }}

    where collector_tstamp >= '{{ run_started_at }}'

),


unioned as (

    select * from current_view

    union all

    select * from historical_table

)

select * from unioned

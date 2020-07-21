{{
    config(
        materialized='view'
    )
}}

with events as (

    select * from {{ source('snowplow','event') }}
    where collector_tstamp >= dateadd('hour', 2, current_timestamp())

),

page_views as (

    select
        domain_sessionid as session_id,
        domain_userid as anonymous_user_id,
        web_page_context.value:data.id::varchar as page_view_id,
        page_url,
        count(*) * 10 as approx_time_on_page,
        min(derived_tstamp) as page_view_start,
        max(collector_tstamp) as max_collector_tstamp

    from events,
    lateral flatten (input => parse_json(contexts):data) web_page_context

    group by 1,2,3,4

)

select * from page_views

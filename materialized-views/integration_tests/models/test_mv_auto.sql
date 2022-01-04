{{config(
    materialized = 'materialized_view',
    auto_refresh = true
)}}

select

    gender,
    count(*) as num

from {{ref('base_tbl')}}
group by 1

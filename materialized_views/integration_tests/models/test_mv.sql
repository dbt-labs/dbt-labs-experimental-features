{{config(
    materialized = 'materialized_view'
)}}

select

    gender,
    count(*) as num

from {{ref('base_tbl')}}
group by 1

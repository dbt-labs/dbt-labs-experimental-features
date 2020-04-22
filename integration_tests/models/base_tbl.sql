{{config(
    materialized = 'incremental',
    unique_key = 'id'
)}}

-- depends on: {{ref('seed_update')}}
-- depends on: {{ref('seed')}}

{% if is_incremental() %}

select * from {{ref('seed_update')}}

{% else %}

select * from {{ref('seed')}}

{% endif %}

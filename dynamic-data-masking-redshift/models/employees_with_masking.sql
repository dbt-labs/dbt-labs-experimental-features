{{
    config(
        post_hook="{{ create_data_masked_view(
            schema='public_analytics'
        ) }}"
    )
}}

select
    -- this is the model sql
    id,
    first_name,
    last_name,
    favorite_bagel_flavor
from {{ ref('employees') }}

{{
    config(
        post_hook="{{ create_data_masked_view(
            schema='public_analytics',
            columns_to_mask=['first_name', 'last_name']
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
